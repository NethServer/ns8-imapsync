# Untitled string in get-configuration output Schema

```txt
http://schema.nethserver.org/imapsync/list-task-output.json#/properties/user_properties/items/properties/foldersynchronization
```



| Abstract            | Extensible | Status         | Identifiable            | Custom Properties | Additional Properties | Access Restrictions | Defined In                                                                       |
| :------------------ | :--------- | :------------- | :---------------------- | :---------------- | :-------------------- | :------------------ | :------------------------------------------------------------------------------- |
| Can be instantiated | No         | Unknown status | Unknown identifiability | Forbidden         | Allowed               | none                | [list-task-output.json\*](imapsync/list-task-output.json "open original schema") |

## foldersynchronization Type

`string`

## foldersynchronization Constraints

**enum**: the value of this property must be equal to one of the following values:

| Value         | Explanation |
| :------------ | :---------- |
| `"all"`       |             |
| `"inbox"`     |             |
| `"exclusion"` |             |
