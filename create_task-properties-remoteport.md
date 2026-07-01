# remoteport Schema

```txt
http://schema.nethserver.org/imapsync/create_task.json#/properties/remoteport
```

Remote port used for the server

| Abstract            | Extensible | Status         | Identifiable            | Custom Properties | Additional Properties | Access Restrictions | Defined In                                                              |
| :------------------ | :--------- | :------------- | :---------------------- | :---------------- | :-------------------- | :------------------ | :---------------------------------------------------------------------- |
| Can be instantiated | No         | Unknown status | Unknown identifiability | Forbidden         | Allowed               | none                | [create\_task.json\*](imapsync/create_task.json "open original schema") |

## remoteport Type

`integer` ([remoteport](create_task-properties-remoteport.md))

## remoteport Constraints

**maximum**: the value of this number must smaller than or equal to: `65535`

**minimum**: the value of this number must greater than or equal to: `1`
