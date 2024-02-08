# Untitled object in get-configuration output Schema

```txt
http://schema.nethserver.org/imapsync/list-task-output.json#/properties/user_properties/items
```



| Abstract            | Extensible | Status         | Identifiable | Custom Properties | Additional Properties | Access Restrictions | Defined In                                                                       |
| :------------------ | :--------- | :------------- | :----------- | :---------------- | :-------------------- | :------------------ | :------------------------------------------------------------------------------- |
| Can be instantiated | No         | Unknown status | No           | Forbidden         | Allowed               | none                | [list-task-output.json\*](imapsync/list-task-output.json "open original schema") |

## items Type

`object` ([Details](list-task-output-properties-user_properties-items.md))

# items Properties

| Property                                        | Type      | Required | Nullable       | Defined by                                                                                                                                                                                                                                         |
| :---------------------------------------------- | :-------- | :------- | :------------- | :------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| [task\_id](#task_id)                            | `string`  | Required | cannot be null | [get-configuration output](list-task-output-properties-user_properties-items-properties-task_id.md "http://schema.nethserver.org/imapsync/list-task-output.json#/properties/user_properties/items/properties/task_id")                             |
| [localuser](#localuser)                         | `string`  | Required | cannot be null | [get-configuration output](list-task-output-properties-user_properties-items-properties-localuser.md "http://schema.nethserver.org/imapsync/list-task-output.json#/properties/user_properties/items/properties/localuser")                         |
| [remoteusername](#remoteusername)               | `string`  | Required | cannot be null | [get-configuration output](list-task-output-properties-user_properties-items-properties-remoteusername.md "http://schema.nethserver.org/imapsync/list-task-output.json#/properties/user_properties/items/properties/remoteusername")               |
| [remotehostname](#remotehostname)               | `string`  | Required | cannot be null | [get-configuration output](list-task-output-properties-user_properties-items-properties-remotehostname.md "http://schema.nethserver.org/imapsync/list-task-output.json#/properties/user_properties/items/properties/remotehostname")               |
| [remoteport](#remoteport)                       | `string`  | Required | cannot be null | [get-configuration output](list-task-output-properties-user_properties-items-properties-remoteport.md "http://schema.nethserver.org/imapsync/list-task-output.json#/properties/user_properties/items/properties/remoteport")                       |
| [security](#security)                           | `string`  | Required | cannot be null | [get-configuration output](list-task-output-properties-user_properties-items-properties-security.md "http://schema.nethserver.org/imapsync/list-task-output.json#/properties/user_properties/items/properties/security")                           |
| [delete\_local](#delete_local)                  | `boolean` | Required | cannot be null | [get-configuration output](list-task-output-properties-user_properties-items-properties-delete_local.md "http://schema.nethserver.org/imapsync/list-task-output.json#/properties/user_properties/items/properties/delete_local")                   |
| [deletefolder](#deletefolder)                   | `string`  | Optional | cannot be null | [get-configuration output](list-task-output-properties-user_properties-items-properties-deletefolder.md "http://schema.nethserver.org/imapsync/list-task-output.json#/properties/user_properties/items/properties/deletefolder")                   |
| [exclude](#exclude)                             | `string`  | Optional | cannot be null | [get-configuration output](list-task-output-properties-user_properties-items-properties-exclude.md "http://schema.nethserver.org/imapsync/list-task-output.json#/properties/user_properties/items/properties/exclude")                             |
| [delete\_remote](#delete_remote)                | `boolean` | Required | cannot be null | [get-configuration output](list-task-output-properties-user_properties-items-properties-delete_remote.md "http://schema.nethserver.org/imapsync/list-task-output.json#/properties/user_properties/items/properties/delete_remote")                 |
| [expunge\_remote](#expunge_remote)              | `string`  | Optional | cannot be null | [get-configuration output](list-task-output-properties-user_properties-items-properties-expunge_remote.md "http://schema.nethserver.org/imapsync/list-task-output.json#/properties/user_properties/items/properties/expunge_remote")               |
| [cron](#cron)                                   | `string`  | Optional | cannot be null | [get-configuration output](list-task-output-properties-user_properties-items-properties-cron.md "http://schema.nethserver.org/imapsync/list-task-output.json#/properties/user_properties/items/properties/cron")                                   |
| [folder\_inbox](#folder_inbox)                  | `string`  | Optional | cannot be null | [get-configuration output](list-task-output-properties-user_properties-items-properties-folder_inbox.md "http://schema.nethserver.org/imapsync/list-task-output.json#/properties/user_properties/items/properties/folder_inbox")                   |
| [foldersynchronization](#foldersynchronization) | `string`  | Required | cannot be null | [get-configuration output](list-task-output-properties-user_properties-items-properties-foldersynchronization.md "http://schema.nethserver.org/imapsync/list-task-output.json#/properties/user_properties/items/properties/foldersynchronization") |
| [remotepassword](#remotepassword)               | `string`  | Required | cannot be null | [get-configuration output](list-task-output-properties-user_properties-items-properties-remotepassword.md "http://schema.nethserver.org/imapsync/list-task-output.json#/properties/user_properties/items/properties/remotepassword")               |
| [service\_running](#service_running)            | `boolean` | Required | cannot be null | [get-configuration output](list-task-output-properties-user_properties-items-properties-service_running.md "http://schema.nethserver.org/imapsync/list-task-output.json#/properties/user_properties/items/properties/service_running")             |

## task\_id



`task_id`

*   is required

*   Type: `string`

*   cannot be null

*   defined in: [get-configuration output](list-task-output-properties-user_properties-items-properties-task_id.md "http://schema.nethserver.org/imapsync/list-task-output.json#/properties/user_properties/items/properties/task_id")

### task\_id Type

`string`

## localuser



`localuser`

*   is required

*   Type: `string`

*   cannot be null

*   defined in: [get-configuration output](list-task-output-properties-user_properties-items-properties-localuser.md "http://schema.nethserver.org/imapsync/list-task-output.json#/properties/user_properties/items/properties/localuser")

### localuser Type

`string`

## remoteusername



`remoteusername`

*   is required

*   Type: `string`

*   cannot be null

*   defined in: [get-configuration output](list-task-output-properties-user_properties-items-properties-remoteusername.md "http://schema.nethserver.org/imapsync/list-task-output.json#/properties/user_properties/items/properties/remoteusername")

### remoteusername Type

`string`

## remotehostname



`remotehostname`

*   is required

*   Type: `string`

*   cannot be null

*   defined in: [get-configuration output](list-task-output-properties-user_properties-items-properties-remotehostname.md "http://schema.nethserver.org/imapsync/list-task-output.json#/properties/user_properties/items/properties/remotehostname")

### remotehostname Type

`string`

## remoteport



`remoteport`

*   is required

*   Type: `string`

*   cannot be null

*   defined in: [get-configuration output](list-task-output-properties-user_properties-items-properties-remoteport.md "http://schema.nethserver.org/imapsync/list-task-output.json#/properties/user_properties/items/properties/remoteport")

### remoteport Type

`string`

## security



`security`

*   is required

*   Type: `string`

*   cannot be null

*   defined in: [get-configuration output](list-task-output-properties-user_properties-items-properties-security.md "http://schema.nethserver.org/imapsync/list-task-output.json#/properties/user_properties/items/properties/security")

### security Type

`string`

### security Constraints

**enum**: the value of this property must be equal to one of the following values:

| Value   | Explanation |
| :------ | :---------- |
| `""`    |             |
| `"tls"` |             |
| `"ssl"` |             |

## delete\_local



`delete_local`

*   is required

*   Type: `boolean`

*   cannot be null

*   defined in: [get-configuration output](list-task-output-properties-user_properties-items-properties-delete_local.md "http://schema.nethserver.org/imapsync/list-task-output.json#/properties/user_properties/items/properties/delete_local")

### delete\_local Type

`boolean`

## deletefolder



`deletefolder`

*   is optional

*   Type: `string`

*   cannot be null

*   defined in: [get-configuration output](list-task-output-properties-user_properties-items-properties-deletefolder.md "http://schema.nethserver.org/imapsync/list-task-output.json#/properties/user_properties/items/properties/deletefolder")

### deletefolder Type

`string`

## exclude



`exclude`

*   is optional

*   Type: `string`

*   cannot be null

*   defined in: [get-configuration output](list-task-output-properties-user_properties-items-properties-exclude.md "http://schema.nethserver.org/imapsync/list-task-output.json#/properties/user_properties/items/properties/exclude")

### exclude Type

`string`

## delete\_remote



`delete_remote`

*   is required

*   Type: `boolean`

*   cannot be null

*   defined in: [get-configuration output](list-task-output-properties-user_properties-items-properties-delete_remote.md "http://schema.nethserver.org/imapsync/list-task-output.json#/properties/user_properties/items/properties/delete_remote")

### delete\_remote Type

`boolean`

## expunge\_remote



`expunge_remote`

*   is optional

*   Type: `string`

*   cannot be null

*   defined in: [get-configuration output](list-task-output-properties-user_properties-items-properties-expunge_remote.md "http://schema.nethserver.org/imapsync/list-task-output.json#/properties/user_properties/items/properties/expunge_remote")

### expunge\_remote Type

`string`

## cron



`cron`

*   is optional

*   Type: `string`

*   cannot be null

*   defined in: [get-configuration output](list-task-output-properties-user_properties-items-properties-cron.md "http://schema.nethserver.org/imapsync/list-task-output.json#/properties/user_properties/items/properties/cron")

### cron Type

`string`

### cron Constraints

**enum**: the value of this property must be equal to one of the following values:

| Value   | Explanation |
| :------ | :---------- |
| `""`    |             |
| `"5m"`  |             |
| `"15m"` |             |
| `"30m"` |             |
| `"45m"` |             |
| `"1h"`  |             |

## folder\_inbox



`folder_inbox`

*   is optional

*   Type: `string`

*   cannot be null

*   defined in: [get-configuration output](list-task-output-properties-user_properties-items-properties-folder_inbox.md "http://schema.nethserver.org/imapsync/list-task-output.json#/properties/user_properties/items/properties/folder_inbox")

### folder\_inbox Type

`string`

## foldersynchronization



`foldersynchronization`

*   is required

*   Type: `string`

*   cannot be null

*   defined in: [get-configuration output](list-task-output-properties-user_properties-items-properties-foldersynchronization.md "http://schema.nethserver.org/imapsync/list-task-output.json#/properties/user_properties/items/properties/foldersynchronization")

### foldersynchronization Type

`string`

### foldersynchronization Constraints

**enum**: the value of this property must be equal to one of the following values:

| Value         | Explanation |
| :------------ | :---------- |
| `"all"`       |             |
| `"inbox"`     |             |
| `"exclusion"` |             |

## remotepassword



`remotepassword`

*   is required

*   Type: `string`

*   cannot be null

*   defined in: [get-configuration output](list-task-output-properties-user_properties-items-properties-remotepassword.md "http://schema.nethserver.org/imapsync/list-task-output.json#/properties/user_properties/items/properties/remotepassword")

### remotepassword Type

`string`

## service\_running



`service_running`

*   is required

*   Type: `boolean`

*   cannot be null

*   defined in: [get-configuration output](list-task-output-properties-user_properties-items-properties-service_running.md "http://schema.nethserver.org/imapsync/list-task-output.json#/properties/user_properties/items/properties/service_running")

### service\_running Type

`boolean`
