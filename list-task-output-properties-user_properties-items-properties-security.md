# Untitled string in get-configuration output Schema

```txt
http://schema.nethserver.org/imapsync/list-task-output.json#/properties/user_properties/items/properties/security
```



| Abstract            | Extensible | Status         | Identifiable            | Custom Properties | Additional Properties | Access Restrictions | Defined In                                                                       |
| :------------------ | :--------- | :------------- | :---------------------- | :---------------- | :-------------------- | :------------------ | :------------------------------------------------------------------------------- |
| Can be instantiated | No         | Unknown status | Unknown identifiability | Forbidden         | Allowed               | none                | [list-task-output.json\*](imapsync/list-task-output.json "open original schema") |

## security Type

`string`

## security Constraints

**enum**: the value of this property must be equal to one of the following values:

| Value   | Explanation |
| :------ | :---------- |
| `""`    |             |
| `"tls"` |             |
| `"ssl"` |             |
