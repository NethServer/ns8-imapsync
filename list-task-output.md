# get-configuration output Schema

```txt
http://schema.nethserver.org/imapsync/list-task-output.json
```

Get tasks configuration

| Abstract            | Extensible | Status         | Identifiable | Custom Properties | Additional Properties | Access Restrictions | Defined In                                                                     |
| :------------------ | :--------- | :------------- | :----------- | :---------------- | :-------------------- | :------------------ | :----------------------------------------------------------------------------- |
| Can be instantiated | No         | Unknown status | No           | Forbidden         | Allowed               | none                | [list-task-output.json](imapsync/list-task-output.json "open original schema") |

## get-configuration output Type

`object` ([get-configuration output](list-task-output.md))

## get-configuration output Examples

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
      "props": {
        "localuser": "administrator",
        "remoteusername": "username",
        "remotehostname": "imap.foo.com",
        "remoteport": "143",
        "security": "tls",
        "delete_local": true,
        "delete_remote": false,
        "exclude": "|folder1|folder2",
        "remotepassword": "password",
        "cron": "5m"
      },
      "mailbox": "administrator",
      "service_running": false
    },
    {
      "props": {
        "localuser": "foo",
        "remoteusername": "username",
        "remotehostname": "imap.foo.com",
        "remoteport": "143",
        "security": "tls",
        "delete_local": true,
        "exclude": "",
        "remotepassword": "password",
        "cron": "1h"
      },
      "mailbox": "foo",
      "service_running": false
    }
  ]
}
```

# get-configuration output Properties

| Property                                 | Type    | Required | Nullable       | Defined by                                                                                                                                                               |
| :--------------------------------------- | :------ | :------- | :------------- | :----------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| [enabled\_mailboxes](#enabled_mailboxes) | `array` | Required | cannot be null | [get-configuration output](list-task-output-properties-enabled_mailboxes.md "http://schema.nethserver.org/imapsync/list-task-output.json#/properties/enabled_mailboxes") |
| [user\_properties](#user_properties)     | `array` | Required | cannot be null | [get-configuration output](list-task-output-properties-user_properties.md "http://schema.nethserver.org/imapsync/list-task-output.json#/properties/user_properties")     |

## enabled\_mailboxes



`enabled_mailboxes`

*   is required

*   Type: `object[]` ([Details](list-task-output-properties-enabled_mailboxes-items.md))

*   cannot be null

*   defined in: [get-configuration output](list-task-output-properties-enabled_mailboxes.md "http://schema.nethserver.org/imapsync/list-task-output.json#/properties/enabled_mailboxes")

### enabled\_mailboxes Type

`object[]` ([Details](list-task-output-properties-enabled_mailboxes-items.md))

## user\_properties



`user_properties`

*   is required

*   Type: `object[]` ([Details](list-task-output-properties-user_properties-items.md))

*   cannot be null

*   defined in: [get-configuration output](list-task-output-properties-user_properties.md "http://schema.nethserver.org/imapsync/list-task-output.json#/properties/user_properties")

### user\_properties Type

`object[]` ([Details](list-task-output-properties-user_properties-items.md))
