# Untitled integer in configure-module input Schema

```txt
http://schema.nethserver.org/imapsync/create_task.json#/properties/delete_remote_older
```

Number of days the messages are retained on the remote server. 0 is for no retention.

| Abstract            | Extensible | Status         | Identifiable            | Custom Properties | Additional Properties | Access Restrictions | Defined In                                                             |
| :------------------ | :--------- | :------------- | :---------------------- | :---------------- | :-------------------- | :------------------ | :--------------------------------------------------------------------- |
| Can be instantiated | No         | Unknown status | Unknown identifiability | Forbidden         | Allowed               | none                | [create_task.json\*](imapsync/create_task.json "open original schema") |

## delete_remote_older Type

`integer`

## delete_remote_older Constraints

**minimum**: the value of this number must greater than or equal to: `0`
