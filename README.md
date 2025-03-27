# ns8-imapsync
## Install

Instantiate the module with:

    add-module ghcr.io/nethserver/imapsync:latest 1

The output of the command will return the instance name.
Output example:

    {"module_id": "imapsync1", "image_name": "imapsync", "image_url": "ghcr.io/nethserver/imapsync:latest"}

## Configure

Let's assume that the imapsync instance is named `imapsync1`.

We need to bind imapsync to a mail server inside the cluster, we use the MODULE_UUID of mail server to configure imapsync, reveal the vmail master secret of local users and start the container waiting for cron tasks or individual user tasks

Launch `configure-module`, by setting the following parameters:
- `mail_server`: module uuid of the mail server
- `mail_host`: local ip of the mail server

Example:

    api-cli run module/imapsync1/configure-module --data '{
        "mail_server":"8dd3b3fe-609c-42f7-a2d1-cecba9461bea",
        "mail_host":"10.5.4.1"
    }'

The above command will:
- start and configure the imapsync instance

## start to sync a remote imap account to local user account

security : "tls" or "ssl" or ""
- delete mails and folder on local account not in remote account
delete_local: true, false
- delete mails on remote account once synchronized to localaccount
delete_remote: true, false
- exclude folders prepend by `^` and end by `$`
exclude: folder1,folder2,^folder3$
- start tasks by a cron (use 5m for minute, 2h for hour: start a cron `0/5 * * * *` or `1 */2 * * *`)
cron: 5m
- the remote imap account credentials (you can use the password of the imap master administrator if you know it, for example vmail. use the login user*vmail and the relevant password). Otherwise use the login and the password of the remote account.
- foldersynchronization: synchronize `all`, only what is in `inbox` or `all but with exclusion` ("all","inbox","exclusion")
- task_id : must be unical, set by a random function by the UI

Example:

    api-cli run module/imapsync1/create-task --data '{
        "localuser":"administrator",
        "remotehostname":"imap.foo.com",
        "remoteport":143,
        "security":"tls",
        "delete_local": false,
        "delete_remote": false,
        "delete_remote_older": 0,
        "exclude":"folder1,folder2",
        "remoteusername":"username",
        "remotepassword":"password",
        "cron":"5m",
        "task_id": "a0241w",
        "foldersynchronization": "all"
    }'

## delete env and stop a running synchronisation

Example:

    api-cli run module/imapsync1/delete-task --data '{
        "localuser":"administrator"
    }'

## stop a running synchronisation

Example:

    api-cli run module/imapsync1/stop-task --data '{
        "localuser":"administrator"
    }'

## start a running synchronisation

Example:

    api-cli run module/imapsync1/start-task --data '{
        "localuser":"administrator"
    }'

## start all configured tasks
Read all `imapsync/*.env` files and start the synchronization

Example:

    api-cli run module/imapsync1/start-all-tasks

## stop all configured tasks
Read all `imapsync/*.env` files and stop the synchronization

Example:

    api-cli run module/imapsync1/stop-all-tasks

## read configuration

Example:

    api-cli run module/imapsync1/get-configuration

Answer:

```json
{
  "mail_server": "e8a6177c-9ae5-4356-826b-0a5f93b2dbaf",
  "mail_host": "10.5.4.1",
  "mail_server_URL": [
    {
      "name": "mail2",
      "label": "mail2 (R3.rocky9-3.org)",
      "value": "e8a6177c-9ae5-4356-826b-0a5f93b2dbaf,10.5.4.1"
    }
  ],
}
```

## list-tasks

Read configuration from `environment` and from `imapsync/*.{env,pwd}`

api-cli run module/imapsync1/list-tasks

```json
{
  "enabled_mailboxes": [
    {
      "name": "administrator",
      "label": "administrator",
      "value": "administrator"
    },
    {
      "name": "foo",
      "label": "foo",
      "value": "foo"
    },
    {
      "name": "john",
      "label": "john",
      "value": "john"
    }
  ],
  "user_properties": [
    {
      "task_id": "qu1dcb",
      "localuser": "administrator",
      "remoteusername": "user2@domain.com",
      "remotehostname": "imap.domain.com",
      "remoteport": "143",
      "security": "tls",
      "delete_local": false,
      "deletefolder": "",
      "exclude": "",
      "delete_remote": false,
      "delete_remote_older": 0,
      "expunge_remote": "",
      "cron": "",
      "folder_inbox": "",
      "foldersynchronization": "all",
      "remotepassword": "password",
      "service_running": false
    },
    {
      "task_id": "vd2am3",
      "localuser": "john",
      "remoteusername": "user@domain.com",
      "remotehostname": "imap.domain.com",
      "remoteport": "143",
      "security": "tls",
      "delete_local": false,
      "deletefolder": "",
      "exclude": "",
      "delete_remote": false,
      "delete_remote_older": 0,
      "expunge_remote": "",
      "cron": "",
      "folder_inbox": "",
      "foldersynchronization": "all",
      "remotepassword": "password",
      "service_running": false
    }
  ]
}

```

## list-informations

You can retrieve the email and folder numbers and the email size for the local and remote account
Example:

    api-cli run module/imapsync9/list-informations --data '{
      "localuser": "john",
      "task_id": "vd2am3"
      }'

output:

```json
{"status": true, "host1Folders": 78, "host2Folders": 78, "host1Messages": 164625, "host2Messages": 155, "host1Sizes": 3060488650, "host2Sizes": 72036894}
```

in case of error you will have

```json
{"status": false}
```
## custom scripts

If necessary, you can add your custom scripts inside the container. To facilitate this, two volumes, included in the backup, 
are mounted from their respective directories under the ./state module.

- `cron` (e.g. `/home/imapsync1/.config/state/cron`)
  This folder is designated for storing cron files, each of which should end its name with `.custom`, while adhering to the cron syntax.
  
      1 */1 * * *  root /usr/bin/imapsync --host1 SOURCE_SERVER --user1 SOURCE_USERNAME --password1 SOURCE_PASSWORD --host2 DESTINATION_SERVER --user2 DESTINATION_USERNAME --password2 DESTINATION_PASSWORD

  Instead of directly add an imapsync command, you have the option to run a script, which can be stored in the `imapsync` volume.

      1 */1 * * *  root /etc/imapsync/script.custom

- `imapsync` (e.g. `/home/imapsync1/.config/state/imapsync`)
  In this location, you can store custom scripts (ending with `.custom`) intended for execution by cron. These scripts must be set to be executable by all users.

## troubleshot issues

in the state folder of the imapsync module you can find environment file (`*.env`), password file (`*.pwd`) and lock file when a task is running (`*.lock`)
You can filter by the task name (locauser to sync + task_id)

The vmail.pwd file is the credential of the dovecot master user

```
.config/state/
├── cron
│   ├── foo_a0241w.cron
│   └── foo_a1j44r.cron
└── imapsync
    ├── foo_a0241w.env
    ├── foo_a0241w.lock
    ├── foo_a0241w.pwd
    ├── foo_a1j44r.env
    ├── foo_a1j44r.pwd
    └── vmail.pwd
```

to launch manually a task
```
ssh imapsync1@localhost
podman exec -ti imapsync /usr/local/bin/syncctl start foo_a1j44r
podman exec -ti imapsync /usr/local/bin/syncctl stop foo_a1j44r
podman exec -ti imapsync /usr/local/bin/syncctl status foo_a1j44r
```

## Uninstall

To uninstall the instance:

    remove-module --no-preserve imapsync1

## Testing

Test the module using the `test-module.sh` script:


    ./test-module.sh <NODE_ADDR> ghcr.io/nethserver/imapsync:latest

The tests are made using [Robot Framework](https://robotframework.org/)

## UI translation

Translated with [Weblate](https://hosted.weblate.org/projects/ns8/).

To setup the translation process:

- add [GitHub Weblate app](https://docs.weblate.org/en/latest/admin/continuous.html#github-setup) to your repository
- add your repository to [hosted.weblate.org]((https://hosted.weblate.org) or ask a NethServer developer to add it to ns8 Weblate project
