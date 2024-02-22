# configure-module input Schema

```txt
http://schema.nethserver.org/imapsync/create_task.json
```

Create user tasks

| Abstract            | Extensible | Status         | Identifiable | Custom Properties | Additional Properties | Access Restrictions | Defined In                                                            |
| :------------------ | :--------- | :------------- | :----------- | :---------------- | :-------------------- | :------------------ | :-------------------------------------------------------------------- |
| Can be instantiated | No         | Unknown status | No           | Forbidden         | Forbidden             | none                | [create\_task.json](imapsync/create_task.json "open original schema") |

## configure-module input Type

`object` ([configure-module input](create_task.md))

## configure-module input Examples

```json
{
  "localuser": "john",
  "remoteusername": "john@domain.com",
  "remotehostname": "imap.domain.com",
  "remotepassword": "password",
  "remoteport": 143,
  "security": "tls",
  "delete_local": true,
  "exclude": "folder1,folder2",
  "delete_remote": false,
  "cron": "5m",
  "task_id": "",
  "foldersynchronization": "all"
}
```

# configure-module input Properties

| Property                                        | Type      | Required | Nullable       | Defined by                                                                                                                                                            |
| :---------------------------------------------- | :-------- | :------- | :------------- | :-------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| [foldersynchronization](#foldersynchronization) | `string`  | Required | cannot be null | [configure-module input](create_task-properties-folder-synchronization.md "http://schema.nethserver.org/imapsync/create_task.json#/properties/foldersynchronization") |
| [cron](#cron)                                   | `string`  | Required | cannot be null | [configure-module input](create_task-properties-cron-task.md "http://schema.nethserver.org/imapsync/create_task.json#/properties/cron")                               |
| [task\_id](#task_id)                            | `string`  | Required | cannot be null | [configure-module input](create_task-properties-task-id.md "http://schema.nethserver.org/imapsync/create_task.json#/properties/task_id")                              |
| [localuser](#localuser)                         | `string`  | Required | cannot be null | [configure-module input](create_task-properties-local-user.md "http://schema.nethserver.org/imapsync/create_task.json#/properties/localuser")                         |
| [remotepassword](#remotepassword)               | `string`  | Required | cannot be null | [configure-module input](create_task-properties-remote-password.md "http://schema.nethserver.org/imapsync/create_task.json#/properties/remotepassword")               |
| [remoteusername](#remoteusername)               | Merged    | Required | cannot be null | [configure-module input](create_task-properties-remote-user.md "http://schema.nethserver.org/imapsync/create_task.json#/properties/remoteusername")                   |
| [remotehostname](#remotehostname)               | `string`  | Required | cannot be null | [configure-module input](create_task-properties-remotehostname.md "http://schema.nethserver.org/imapsync/create_task.json#/properties/remotehostname")                |
| [remoteport](#remoteport)                       | `integer` | Required | cannot be null | [configure-module input](create_task-properties-remoteport.md "http://schema.nethserver.org/imapsync/create_task.json#/properties/remoteport")                        |
| [security](#security)                           | `string`  | Required | cannot be null | [configure-module input](create_task-properties-security.md "http://schema.nethserver.org/imapsync/create_task.json#/properties/security")                            |
| [delete\_local](#delete_local)                  | `boolean` | Required | cannot be null | [configure-module input](create_task-properties-delete-email.md "http://schema.nethserver.org/imapsync/create_task.json#/properties/delete_local")                    |
| [delete\_remote](#delete_remote)                | `boolean` | Required | cannot be null | [configure-module input](create_task-properties-delete-email-on-remote.md "http://schema.nethserver.org/imapsync/create_task.json#/properties/delete_remote")         |
| [exclude](#exclude)                             | `string`  | Required | cannot be null | [configure-module input](create_task-properties-exclude.md "http://schema.nethserver.org/imapsync/create_task.json#/properties/exclude")                              |

## foldersynchronization

Decide what folders to synchronize

`foldersynchronization`

*   is required

*   Type: `string` ([folder synchronization](create_task-properties-folder-synchronization.md))

*   cannot be null

*   defined in: [configure-module input](create_task-properties-folder-synchronization.md "http://schema.nethserver.org/imapsync/create_task.json#/properties/foldersynchronization")

### foldersynchronization Type

`string` ([folder synchronization](create_task-properties-folder-synchronization.md))

### foldersynchronization Constraints

**enum**: the value of this property must be equal to one of the following values:

| Value         | Explanation |
| :------------ | :---------- |
| `"all"`       |             |
| `"inbox"`     |             |
| `"exclusion"` |             |

## cron

Start a task by a cron

`cron`

*   is required

*   Type: `string` ([Cron task](create_task-properties-cron-task.md))

*   cannot be null

*   defined in: [configure-module input](create_task-properties-cron-task.md "http://schema.nethserver.org/imapsync/create_task.json#/properties/cron")

### cron Type

`string` ([Cron task](create_task-properties-cron-task.md))

### cron Constraints

**enum**: the value of this property must be equal to one of the following values:

| Value   | Explanation |
| :------ | :---------- |
| `""`    |             |
| `"5m"`  |             |
| `"10m"` |             |
| `"15m"` |             |
| `"30m"` |             |
| `"45m"` |             |
| `"1h"`  |             |

## task\_id

A local user can run many tasks, we need ID

`task_id`

*   is required

*   Type: `string` ([Task ID](create_task-properties-task-id.md))

*   cannot be null

*   defined in: [configure-module input](create_task-properties-task-id.md "http://schema.nethserver.org/imapsync/create_task.json#/properties/task_id")

### task\_id Type

`string` ([Task ID](create_task-properties-task-id.md))

## localuser

Local user of the local account

`localuser`

*   is required

*   Type: `string` ([Local User](create_task-properties-local-user.md))

*   cannot be null

*   defined in: [configure-module input](create_task-properties-local-user.md "http://schema.nethserver.org/imapsync/create_task.json#/properties/localuser")

### localuser Type

`string` ([Local User](create_task-properties-local-user.md))

### localuser Constraints

**minimum length**: the minimum number of characters for this string is: `1`

## remotepassword

Password of the remote user

`remotepassword`

*   is required

*   Type: `string` ([Remote Password](create_task-properties-remote-password.md))

*   cannot be null

*   defined in: [configure-module input](create_task-properties-remote-password.md "http://schema.nethserver.org/imapsync/create_task.json#/properties/remotepassword")

### remotepassword Type

`string` ([Remote Password](create_task-properties-remote-password.md))

### remotepassword Constraints

**minimum length**: the minimum number of characters for this string is: `1`

## remoteusername

Remote user of the remote account

`remoteusername`

*   is required

*   Type: `string` ([Remote User](create_task-properties-remote-user.md))

*   cannot be null

*   defined in: [configure-module input](create_task-properties-remote-user.md "http://schema.nethserver.org/imapsync/create_task.json#/properties/remoteusername")

### remoteusername Type

`string` ([Remote User](create_task-properties-remote-user.md))

any of

*   [Untitled undefined type in configure-module input](create_task-properties-remote-user-anyof-0.md "check type definition")

*   [Untitled undefined type in configure-module input](create_task-properties-remote-user-anyof-1.md "check type definition")

## remotehostname

Host name for the remote account

`remotehostname`

*   is required

*   Type: `string` ([remotehostname](create_task-properties-remotehostname.md))

*   cannot be null

*   defined in: [configure-module input](create_task-properties-remotehostname.md "http://schema.nethserver.org/imapsync/create_task.json#/properties/remotehostname")

### remotehostname Type

`string` ([remotehostname](create_task-properties-remotehostname.md))

### remotehostname Constraints

**(international) hostname**: the string must be an (IDN) hostname, according to [RFC 5890, section 2.3.2.3](https://tools.ietf.org/html/rfc5890 "check the specification")

## remoteport

Remote port used for the server

`remoteport`

*   is required

*   Type: `integer` ([remoteport](create_task-properties-remoteport.md))

*   cannot be null

*   defined in: [configure-module input](create_task-properties-remoteport.md "http://schema.nethserver.org/imapsync/create_task.json#/properties/remoteport")

### remoteport Type

`integer` ([remoteport](create_task-properties-remoteport.md))

### remoteport Constraints

**maximum**: the value of this number must smaller than or equal to: `65535`

**minimum**: the value of this number must greater than or equal to: `1`

## security



`security`

*   is required

*   Type: `string` ([security](create_task-properties-security.md))

*   cannot be null

*   defined in: [configure-module input](create_task-properties-security.md "http://schema.nethserver.org/imapsync/create_task.json#/properties/security")

### security Type

`string` ([security](create_task-properties-security.md))

### security Constraints

**enum**: the value of this property must be equal to one of the following values:

| Value   | Explanation |
| :------ | :---------- |
| `""`    |             |
| `"tls"` |             |
| `"ssl"` |             |

## delete\_local

delete Email not on local server

`delete_local`

*   is required

*   Type: `boolean` ([Delete Email](create_task-properties-delete-email.md))

*   cannot be null

*   defined in: [configure-module input](create_task-properties-delete-email.md "http://schema.nethserver.org/imapsync/create_task.json#/properties/delete_local")

### delete\_local Type

`boolean` ([Delete Email](create_task-properties-delete-email.md))

## delete\_remote

delete Email on remote server after sync

`delete_remote`

*   is required

*   Type: `boolean` ([Delete Email on remote](create_task-properties-delete-email-on-remote.md))

*   cannot be null

*   defined in: [configure-module input](create_task-properties-delete-email-on-remote.md "http://schema.nethserver.org/imapsync/create_task.json#/properties/delete_remote")

### delete\_remote Type

`boolean` ([Delete Email on remote](create_task-properties-delete-email-on-remote.md))

## exclude

Folders exclusion

`exclude`

*   is required

*   Type: `string` ([exclude](create_task-properties-exclude.md))

*   cannot be null

*   defined in: [configure-module input](create_task-properties-exclude.md "http://schema.nethserver.org/imapsync/create_task.json#/properties/exclude")

### exclude Type

`string` ([exclude](create_task-properties-exclude.md))
