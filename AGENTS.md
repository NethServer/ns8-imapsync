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

**Scopes:**

| Scope | Target |
|---|---|
| `node` | node agent |
| `cluster` | cluster agent |
| `<module>@node` | first instance of module on same node |
| `<module>@any` | all instances of that module |

**Available roles (by module that defines them):**

| Role | Defined by | Grants access to |
|---|---|---|
| `fwadm` | ns8-core / node | `add-public-service`, `remove-public-service`, `add-custom-zone`, `remove-custom-zone`, `add-rich-rules`, `remove-rich-rules` |
| `portsadm` | ns8-core / node | `allocate-ports`, `deallocate-ports` |
| `tunadm` | ns8-core / node | TUN device management (includes fwadm actions) |
| `reader` | ns8-core | `get-*`, `show-*`, `read-*` |
| `routeadm` | ns8-traefik | `set-route`, `get-route`, `list-routes` |
| `certadm` | ns8-traefik | certificate management actions |
| `fulladm` | ns8-traefik | routeadm + certadm combined |
| `mailadm` | ns8-mail | `reveal-master-credentials`, `get-*`, `list-*`, `set-always-bcc`, `add-relay-rule`, `alter-relay-rule`, `remove-relay-rule` |
| `accountconsumer` | cluster | bind/use a user domain (LDAP) |
| `accountprovider` | cluster | provide a user domain |
| `selfadm` | built-in | module's own actions (auto-granted at install) |

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
rdb = agent.redis_connect(use_replica=True)   # local replica, resilient at startup
agent.set_env("KEY", "value")                  # add/update env var in state/environment
agent.unset_env("KEY")                         # remove env var from state/environment

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
Payload arrives on **stdin**. stdout/stderr go to system log.
**Non-zero exit halts remaining steps** — further scripts in the same event directory are skipped.

Injected env vars: `AGENT_EVENT_SOURCE`, `AGENT_EVENT_NAME`.

Filter early — `sys.exit(0)` if event not relevant to this instance:
```python
#!/usr/bin/env python3
import json, sys, agent, os

event = json.load(sys.stdin)

if event.get('module_uuid') != os.getenv('MAIL_SERVER', ''):
    sys.exit(0)  # not our mail server, ignore

agent.set_env("MAIL_HOST", event['host'])
agent.run_helper('systemctl', '--user', '-T', 'try-restart', 'mymodule.service').check_returncode()
```

`-T` removes the default timeout — use for service restarts.
`agent.certificate_event_matches(event, hostname)` — built-in helper for `certificate-changed`.

### Built-in platform events

**Module channel** (`module/<id>/event/<name>`):
- `user-domain-changed` — `{"node_id":INT,"domain":STRING,"domains":LIST}`
- `ldap-provider-changed` — `{"domain":STRING,"key":STRING}`
- `certificate-changed` — TLS cert renewed for a hostname
- `mail-settings-changed` — mail module config changed (fired by ns8-mail)
- `backup-status-changed` — `{"node_id":INT,"module_id":STRING,"backup_id":INT}`

**Node channel** (`node/<id>/event/<name>`):
- `fqdn-changed` — `{"hostname":STRING,"domain":STRING,"node":INT}`

**Cluster channel** (`cluster/event/<name>`):
- `module-added`, `module-removed`, `leader-changed`, `backup-destination-changed`

## Systemd Services

### Naming convention
- Single service: `<module>.service`
- Multi-service (pod pattern): `<module>.service` (pod master) + `<component>-app.service` (children)

### Single service (simple module)
```ini
[Unit]
Description=My service
[Service]
EnvironmentFile=%S/state/environment
ExecStart=/usr/bin/podman run ...
Restart=always
[Install]
WantedBy=default.target
```

### Multi-service ordering (pod pattern)
Master pod declares `Before=` and `Requires=` for all children.
Children use `BindsTo=` (stops if pod dies) and `After=` (start order):

```ini
# <module>.service — pod master
[Unit]
Requires=db-app.service app-app.service
Before=db-app.service app-app.service

# db-app.service — database (must be ready before app)
[Unit]
BindsTo=<module>.service
After=<module>.service
Before=app-app.service

# app-app.service — main application
[Unit]
BindsTo=<module>.service
After=<module>.service db-app.service
```

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
`imageroot/etc/state-include.conf` lists paths relative to the module home:
```
state/mydata
volumes/myvolume
```
- `state/` paths → files in `AGENT_STATE_DIR`
- `volumes/<name>` → Podman volume `<name>` (rootless) or `<module_id>-<name>` (rootful)
- `state/environment` is always included automatically

### Database dump/cleanup (bin scripts, not actions)
For modules with a database, create two **executable** scripts in `imageroot/bin/`:

**`imageroot/bin/module-dump-state`** — runs before Restic backup, CWD is `state/`:
```bash
#!/bin/bash
set -e
# Exit silently if service not running
if ! systemctl --user -q is-active mymodule.service; then exit 0; fi
podman exec mariadb-app mysqldump \
    --databases mydb \
    --default-character-set=utf8mb4 \
    --single-transaction --quick --add-drop-table \
    --skip-dump-date > mydb.sql
```

**`imageroot/bin/module-cleanup-state`** — runs after backup:
```bash
#!/bin/bash
rm -vf mydb.sql
```

Add the dump file to `state-include.conf`:
```
state/mydb.sql
volumes/mysql-data
```

### Restore sequence
`imageroot/actions/restore-module/` — numbered steps, `10restore` inherited (Restic).
Add custom steps after 10:

**`06copyenv`** — restore env vars from backup (runs before 10restore overwrites state):
```python
import sys, json, agent
request = json.load(sys.stdin)
for evar in ["MAIL_SERVER", "TRAEFIK_HOST", ...]:
    agent.set_env(evar, request['environment'][evar])
```

**`40restoreDB`** — restore SQL dump via ephemeral MariaDB container:
```bash
#!/bin/bash
set -e -o pipefail
exec 1>&2
mkdir -vp initdb.d
mv -v mydb.sql initdb.d
# Exit script to stop MariaDB after dump is loaded
cat - >initdb.d/zz_restore.sh <<'EOS'
set -- true
docker_temp_server_stop
exit 0
EOS
trap 'rm -rfv initdb.d/' EXIT
podman run --rm --interactive --network=none \
    --volume=./initdb.d:/docker-entrypoint-initdb.d:z \
    --volume mysql-data:/var/lib/mysql/:Z \
    --env MARIADB_ROOT_PASSWORD=Nethesis,1234 \
    --env MARIADB_DATABASE=mydb \
    --env MARIADB_USER=myuser \
    --env MARIADB_PASSWORD=Nethesis,1234 \
    --replace --name=restore_db \
    ${MARIADB_IMAGE}
```
MariaDB entrypoint auto-executes all files in `/docker-entrypoint-initdb.d/` on first
start, then `zz_restore.sh` stops the container. The volume `mysql-data` is now populated.

**`50call-configure-module`** — reconfigure after restore:
```python
import sys, json, agent, os
request = json.load(sys.stdin)
renv = request['environment']
retval = agent.tasks.run(agent_id=os.environ['AGENT_ID'],
    action='configure-module', data={
        "mail_server": renv["MAIL_SERVER"],
        "host": renv["TRAEFIK_HOST"],
        # ... map all required config fields
    })
agent.assert_exp(retval['exit_code'] == 0, "configure-module failed!")
```

### Clone vs restore
- **restore-module**: Restic restores files listed in `etc/state-include.conf` → `40restoreDB` loads SQL dump → `50call-configure-module` reconfigures
- **clone-module**: no Restic restore, no SQL dump — only `50call-configure-module` (fresh DB, env vars from `os.environ` set by clone framework)

Dump/cleanup scripts (`imageroot/bin/module-dump-state`, `imageroot/bin/module-cleanup-state`) only run during backup — not during clone or restore.

### MariaDB volume persistence
Database data lives in a named Podman volume declared in `build-images.sh`:
```bash
--label="org.nethserver.volumes=mysql-data"
```
And mounted in the systemd service:
```
--volume mysql-data:/var/lib/mysql/:Z
```

### PostgreSQL dump/restore pattern
Dump uses custom format (`--format=c`) for `pg_restore` compatibility:

**`imageroot/bin/module-dump-state`:**
```bash
#!/bin/bash
set -e
podman exec postgres-app pg_dump -U myuser --format=c mydb > mydb.pg_dump
```

**`imageroot/actions/restore-module/40restore-postgres`:**
```bash
#!/bin/bash
set -e -o pipefail
exec 1>&2
mkdir -vp restore
cat - >restore/mydb_restore.sh <<'EOS'
pg_restore --no-owner --no-privileges -U myuser -d mydb
ec=$?
docker_temp_server_stop
exit $ec
EOS
# Dump is piped via stdin into the ephemeral container
podman run --rm --interactive --network=none \
    --volume=./restore:/docker-entrypoint-initdb.d/:Z \
    --volume=postgres-data:/var/lib/postgresql/data:Z \
    --replace --name=restore_db \
    --env POSTGRES_USER=myuser \
    --env POSTGRES_PASSWORD=Nethesis,1234 \
    --env POSTGRES_DB=mydb \
    "${POSTGRES_IMAGE}" < mydb.pg_dump
rm -rfv restore/ mydb.pg_dump
```
The restore script in `/docker-entrypoint-initdb.d/` reads the dump from stdin,
calls `docker_temp_server_stop` to exit the container once done.

`state-include.conf` — list dump file and all named volumes:
```
state/mydb.pg_dump
volumes/postgres-data
volumes/app-data
```

### SELinux volume label flags
- `:z` (shared) — volume accessible by multiple containers within the same pod
- `:Z` (private) — volume exclusive to a single container/service

## Upgrade Hooks
Scripts in `imageroot/update-module.d/` run on `update-module` in lexicographic order.
If a script fails, execution continues with the next one — each script is independent.

Recommended numbering layout:
```
05migrate-data        # pre-restart: data/schema migrations
06update-config       # pre-restart: config file transformations
30restart             # restart the service
50reindex             # post-restart: rebuild indexes, caches
60cleanup             # post-restart: remove stale files/volumes
```

```bash
# 30restart — typical restart script
#!/bin/bash
set -e
systemctl --user try-restart <module>.service
```

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
