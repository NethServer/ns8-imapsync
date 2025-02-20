# folder synchronization Schema

```txt
http://schema.nethserver.org/imapsync/create_task.json#/properties/foldersynchronization
```

Decide what folders to synchronize

| Abstract            | Extensible | Status         | Identifiable            | Custom Properties | Additional Properties | Access Restrictions | Defined In                                                              |
| :------------------ | :--------- | :------------- | :---------------------- | :---------------- | :-------------------- | :------------------ | :---------------------------------------------------------------------- |
| Can be instantiated | No         | Unknown status | Unknown identifiability | Forbidden         | Allowed               | none                | [create\_task.json\*](imapsync/create_task.json "open original schema") |

## foldersynchronization Type

`string` ([folder synchronization](create_task-properties-folder-synchronization.md))

## foldersynchronization Constraints

**enum**: the value of this property must be equal to one of the following values:

| Value         | Explanation |
| :------------ | :---------- |
| `"all"`       |             |
| `"inbox"`     |             |
| `"exclusion"` |             |
