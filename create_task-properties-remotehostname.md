# remotehostname Schema

```txt
http://schema.nethserver.org/imapsync/create_task.json#/properties/remotehostname
```

Host name for the remote account

| Abstract            | Extensible | Status         | Identifiable            | Custom Properties | Additional Properties | Access Restrictions | Defined In                                                              |
| :------------------ | :--------- | :------------- | :---------------------- | :---------------- | :-------------------- | :------------------ | :---------------------------------------------------------------------- |
| Can be instantiated | No         | Unknown status | Unknown identifiability | Forbidden         | Allowed               | none                | [create\_task.json\*](imapsync/create_task.json "open original schema") |

## remotehostname Type

`string` ([remotehostname](create_task-properties-remotehostname.md))

## remotehostname Constraints

**(international) hostname**: the string must be an (IDN) hostname, according to [RFC 5890, section 2.3.2.3](https://tools.ietf.org/html/rfc5890 "check the specification")
