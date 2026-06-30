# NS8 Module — Architecture Guide

## Platform Overview
NS8 is a modular Linux server platform. Each module runs in a Podman container,
rootless by default. Some modules require rootful mode — declared in `build-images.sh`
via `--label="org.nethserver.rootfull=1"`.

## Module Directory Layout
```
build-images.sh          # Container image build + authorization declarations
imageroot/
  actions/               # Backend action handlers (Python 3 + bash)
  events/                # Event handlers triggered by platform events
  bin/                   # Utility scripts called by actions or systemd
  bin/module-dump-state  # (optional) runs before Restic backup — export DB/data to state/
  bin/module-cleanup-state # (optional) runs after backup — remove temp dump files
  systemd/user/          # Systemd user service units
  update-module.d/       # Upgrade hooks (run on module update)
  etc/state-include.conf # ALL paths to include in Restic backup (state/ and volumes/)
ui/                      # Vue.js 2 frontend
tests/                   # Robot Framework integration tests
```

## Authorization Model

### Declaring privileges (build-images.sh)
Authorizations are declared as container labels in `build-images.sh`:
```bash
--label="org.nethserver.authorizations=node:fwadm traefik@node:routeadm mail@any:mailadm"
```
Format: `<scope>:<role>`. Multiple roles on the same scope: `node:fwadm,portsadm`.

**Scopes:** `node` (node agent), `cluster` (cluster agent), `<module>@node` (first instance on same node), `<module>@any` (all instances of that module).

**Available roles:**

| Role | Defined by | Purpose |
|---|---|---|
| `fwadm` | ns8-core / node | firewall rules (public services, zones, rich rules) |
| `portsadm` | ns8-core / node | port allocation |
| `tunadm` | ns8-core / node | TUN device + fwadm actions |
| `reader` | ns8-core | `get-*`, `show-*`, `read-*` |
| `routeadm` | ns8-traefik | manage Traefik routes |
| `certadm` | ns8-traefik | certificate management |
| `fulladm` | ns8-traefik | routeadm + certadm |
| `mailadm` | ns8-mail | master credentials, relay rules, BCC |
| `accountconsumer` | cluster | bind/use a user domain (LDAP) |
| `accountprovider` | cluster | provide a user domain |
| `selfadm` | built-in | module's own actions (auto-granted) |

### selfadm — module calling its own actions
A module can grant itself the right to call its own actions via Redis in
`imageroot/actions/create-module/10grants`:
```bash
redis-exec SADD "${AGENT_ID}/roles/selfadm" "action-name"
```
Use this when an action needs to trigger another action of the same module.

## Action Handlers
Each action is a directory under `imageroot/actions/<action-name>/`.
Scripts inside execute in lexicographic order: `10grants`, `20read`, `80start_services`, etc.
Python scripts use the NS8 agent SDK (`import agent`).
Bash scripts use standard POSIX shell.

Base actions inherited automatically (no need to implement):
- `create-module` — install + pull image
- `destroy-module` — cleanup (traefik, firewall, systemd)
- `get-status` — runtime status (rootless only)
- `list-service-providers` — service discovery

Modules with a UI must implement:
- `configure-module` — validate + apply config
- `get-configuration` — return current config (mirrors configure-module input)

### Agent SDK (Python)
```python
import agent

# High-level env helpers — no Redis connection needed
agent.set_env("KEY", "value")   # add/update env var in state/environment
agent.unset_env("KEY")          # remove env var from state/environment
```

> **Note:** env vars live in Redis — all node modules can read them.
> For secrets, write to `state/<file>`, include in `etc/state-include.conf`, and read in the relevant action.

`redis_connect` only when you need to read/write Redis directly with the Python client:

```python
rdb = agent.redis_connect(use_replica=True)   # local replica, resilient at startup

# Cross-module RPC call
agent.tasks.run(f"module/{other_module_id}", action="action-name", data={...})
```

## Service Providers
Modules expose services to other modules via Redis hash keys:
```
module/<module_id>/srv/<transport>/<service_name>
```
Typical fields: `host`, `port`.

Discovering services (Python):
```python
rdb = agent.redis_connect(use_replica=True)
providers = agent.list_service_providers(rdb, 'imap', 'tcp', {'module_uuid': uuid})
host = providers[0]['host']
```
Use `use_replica=True` so service startup works even if cluster leader is unreachable.

When a service endpoint changes, the provider fires an event named
`<service-name>-changed` with payload `{"module_id": "...", "module_uuid": "..."}`.

## Events
Events are Redis channel messages. Channel format: `module/<module_id>/event/<event_name>`.
Name events in **past tense**: `mail-settings-changed`, `ldap-provider-changed`.

Firing an event:
```bash
redis-cli PUBLISH "module/mymodule1/event/my-settings-changed" '{"module_id":"mymodule1","module_uuid":"..."}'
```

### Handlers
Live in `imageroot/events/<event-name>/` — executable scripts, work like action steps.
Payload arrives on **stdin** as JSON. **Non-zero exit halts remaining steps.**
Injected env vars: `AGENT_EVENT_SOURCE`, `AGENT_EVENT_NAME`.

Pattern: `event = json.load(sys.stdin)` → filter with `sys.exit(0)` if not relevant → apply change → `agent.run_helper('systemctl', '--user', '-T', 'try-restart', ...)`.
`-T` removes the default timeout. `agent.certificate_event_matches(event, hostname)` — built-in helper for `certificate-changed`.

### Built-in platform events
Module channel `module/<id>/event/<name>`: `user-domain-changed`, `ldap-provider-changed`,
`certificate-changed`, `mail-settings-changed`, `backup-status-changed`.
Node channel `node/<id>/event/<name>`: `fqdn-changed`.
Cluster channel `cluster/event/<name>`: `module-added`, `module-removed`, `leader-changed`.

## Systemd Services

### Naming convention
- Single service: `<module>.service`
- Multi-service (pod pattern): `<module>.service` (pod master) + `<component>-app.service` (children)

### Multi-service ordering (pod pattern)
- Pod master (`<module>.service`): `Requires=` + `Before=` all children
- DB service: `BindsTo=<module>.service`, `After=<module>.service`, `Before=app-app.service`
- App service: `BindsTo=<module>.service`, `After=<module>.service db-app.service`

`BindsTo=` ensures children stop automatically if the pod dies.

### Conditional service start (configure-module/80start_services)
Services are enabled and started only after successful configuration.
For a pod module, **all services must be named explicitly** to guarantee
the `Before=`/`After=` start order is respected — systemd does not cascade
restarts to children automatically:
```bash
systemctl --user enable <module>.service
systemctl --user restart <module>.service db-app.service app-app.service
# Use try-restart if the service may not be running yet (e.g. first configure)
systemctl --user try-restart <module>.service db-app.service app-app.service
```

## Backup & Restore

### Declaring what to back up (state-include.conf)
`imageroot/etc/state-include.conf` lists paths relative to the module home. Use `state/<file>` for files in `AGENT_STATE_DIR` and `volumes/<name>` for Podman volumes (`<module_id>-<name>` when rootful). `state/environment` is always included automatically.

### Restore sequence
`imageroot/actions/restore-module/` — numbered steps, `10restore` inherited (Restic).

- `06copyenv` — restore env vars from `request['environment']` via `agent.set_env()`
- `40restoreDB` — load SQL dump via ephemeral container (see patterns below)
- `50call-configure-module` — call `configure-module` with restored env vars via `agent.tasks.run()`

### MariaDB
- **Dump** (`imageroot/bin/module-dump-state`, CWD=`state/`): `podman exec mariadb-app mysqldump --databases mydb --default-character-set=utf8mb4 --single-transaction --quick --add-drop-table --skip-dump-date > mydb.sql`
- **Cleanup** (`imageroot/bin/module-cleanup-state`): `rm -vf mydb.sql`
- **Restore** (`40restoreDB`): move `mydb.sql` into `initdb.d/`, add `zz_restore.sh` that calls `docker_temp_server_stop`, launch ephemeral `${MARIADB_IMAGE}` with `--volume=./initdb.d:/docker-entrypoint-initdb.d:z --volume mysql-data:/var/lib/mysql/:Z`. MariaDB entrypoint auto-executes the SQL, then the script stops the container.
- **Reference**: ns8-sogo

`state-include.conf`: `state/mydb.sql` + `volumes/mysql-data`

### PostgreSQL
- **Dump** (`imageroot/bin/module-dump-state`): `podman exec postgres-app pg_dump -U myuser --format=c mydb > mydb.pg_dump` (custom format for `pg_restore`)
- **Cleanup** (`imageroot/bin/module-cleanup-state`): `rm -vf mydb.pg_dump`
- **Restore** (`40restore-postgres`): create `restore/mydb_restore.sh` with `pg_restore --no-owner --no-privileges`, launch ephemeral `${POSTGRES_IMAGE}` with dump **piped via stdin** (`< mydb.pg_dump`), script calls `docker_temp_server_stop` on exit.
- **Reference**: ns8-mattermost

`state-include.conf`: `state/mydb.pg_dump` + `volumes/postgres-data`

### Clone vs restore
- **restore-module**: Restic restores files listed in `etc/state-include.conf` → `40restoreDB` loads SQL dump → `50call-configure-module` reconfigures
- **clone-module**: no Restic restore, no SQL dump — only `50call-configure-module` (fresh DB, env vars from `os.environ` set by clone framework)

Dump/cleanup scripts (`imageroot/bin/module-dump-state`, `imageroot/bin/module-cleanup-state`) only run during backup — not during clone or restore.

### Volume persistence
Named Podman volumes are created automatically on first use — no label required.
Mount in the systemd service:
```
--volume mysql-data:/var/lib/mysql/:Z
--volume postgres-data:/var/lib/postgresql/data:Z
```

### Additional disks
`--label="org.nethserver.volumes=vol1 vol2"` — marks volumes as candidates for additional-disk placement. At install, the UI prompts the sysadmin to assign them to an extra disk (slower but bigger). Without the label, volumes land in Podman default under the module home. Only use for bulk data (DB, mail, media). Assignments in `/etc/nethserver/volumes.conf`, managed via `volumectl`.

### SELinux volume label flags
- `:z` (shared) — volume accessible by multiple containers within the same pod
- `:Z` (private) — volume exclusive to a single container/service

## Upgrade Hooks
Scripts in `imageroot/update-module.d/` run on `update-module` in lexicographic order.
If a script fails, execution continues with the next one — each script is independent.

Recommended layout: `05`-`06` pre-restart migrations, `30restart` (`systemctl --user try-restart`), `50`-`60` post-restart reindex/cleanup.
Version-specific migrations go before `30restart` so the new code starts on updated data.

## Frontend: Vue.js 2
Stack: Vue 2.6, Vuex, Vue Router, IBM Carbon Design System, `@nethserver/ns8-ui-lib`.
Entry: `ui/src/main.js`. Views in `ui/src/views/`, components in `ui/src/components/`.
API calls go through the NS8 agent REST API.

### Translations
Files live in `ui/public/i18n/<lang>/translation.json`.
**Only edit `ui/public/i18n/en/translation.json`.**
All other language files are updated automatically by Renovate — never edit them manually.

## Testing
Robot Framework tests in `tests/`. Run in order by filename: install → test → uninstall.
