# Untitled string in get-log input Schema

```txt
http://schema.nethserver.org/imapsync/get-log.json#/properties/task_id
```



| Abstract            | Extensible | Status         | Identifiable            | Custom Properties | Additional Properties | Access Restrictions | Defined In                                                     |
| :------------------ | :--------- | :------------- | :---------------------- | :---------------- | :-------------------- | :------------------ | :------------------------------------------------------------- |
| Can be instantiated | No         | Unknown status | Unknown identifiability | Forbidden         | Allowed               | none                | [get-log.json\*](imapsync/get-log.json "open original schema") |

## task\_id Type

`string`

## task\_id Constraints

**pattern**: the string must match the following regular expression:&#x20;

```regexp
^[a-z0-9]{6}$
```

[try pattern](https://regexr.com/?expression=%5E%5Ba-z0-9%5D%7B6%7D%24 "try regular expression with regexr.com")
