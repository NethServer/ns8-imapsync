# Untitled string in get-log input Schema

```txt
http://schema.nethserver.org/imapsync/get-log.json#/properties/localuser
```



| Abstract            | Extensible | Status         | Identifiable            | Custom Properties | Additional Properties | Access Restrictions | Defined In                                                     |
| :------------------ | :--------- | :------------- | :---------------------- | :---------------- | :-------------------- | :------------------ | :------------------------------------------------------------- |
| Can be instantiated | No         | Unknown status | Unknown identifiability | Forbidden         | Allowed               | none                | [get-log.json\*](imapsync/get-log.json "open original schema") |

## localuser Type

`string`

## localuser Constraints

**maximum length**: the maximum number of characters for this string is: `32`

**pattern**: the string must match the following regular expression:&#x20;

```regexp
^[a-z_][a-z0-9_.-]*$
```

[try pattern](https://regexr.com/?expression=%5E%5Ba-z_%5D%5Ba-z0-9_.-%5D*%24 "try regular expression with regexr.com")
