# security Schema

```txt
http://schema.nethserver.org/imapsync/create_task.json#/properties/security
```



| Abstract            | Extensible | Status         | Identifiable            | Custom Properties | Additional Properties | Access Restrictions | Defined In                                                              |
| :------------------ | :--------- | :------------- | :---------------------- | :---------------- | :-------------------- | :------------------ | :---------------------------------------------------------------------- |
| Can be instantiated | No         | Unknown status | Unknown identifiability | Forbidden         | Allowed               | none                | [create\_task.json\*](imapsync/create_task.json "open original schema") |

## security Type

`string` ([security](create_task-properties-security.md))

## security Constraints

**enum**: the value of this property must be equal to one of the following values:

| Value   | Explanation |
| :------ | :---------- |
| `""`    |             |
| `"tls"` |             |
| `"ssl"` |             |
