# Cron task Schema

```txt
http://schema.nethserver.org/imapsync/create_task.json#/properties/cron
```

Start a task by a cron

| Abstract            | Extensible | Status         | Identifiable            | Custom Properties | Additional Properties | Access Restrictions | Defined In                                                              |
| :------------------ | :--------- | :------------- | :---------------------- | :---------------- | :-------------------- | :------------------ | :---------------------------------------------------------------------- |
| Can be instantiated | No         | Unknown status | Unknown identifiability | Forbidden         | Allowed               | none                | [create\_task.json\*](imapsync/create_task.json "open original schema") |

## cron Type

`string` ([Cron task](create_task-properties-cron-task.md))

## cron Constraints

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
