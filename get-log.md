# get-log input Schema

```txt
http://schema.nethserver.org/imapsync/get-log.json
```

Get the imapsync log for a task

| Abstract            | Extensible | Status         | Identifiable | Custom Properties | Additional Properties | Access Restrictions | Defined In                                                   |
| :------------------ | :--------- | :------------- | :----------- | :---------------- | :-------------------- | :------------------ | :----------------------------------------------------------- |
| Can be instantiated | No         | Unknown status | No           | Forbidden         | Forbidden             | none                | [get-log.json](imapsync/get-log.json "open original schema") |

## get-log input Type

`object` ([get-log input](get-log.md))

## get-log input Examples

```json
{
  "task_id": "r3koe0",
  "localuser": "john"
}
```

# get-log input Properties

| Property                | Type     | Required | Nullable       | Defined by                                                                                                                  |
| :---------------------- | :------- | :------- | :------------- | :-------------------------------------------------------------------------------------------------------------------------- |
| [task\_id](#task_id)    | `string` | Required | cannot be null | [get-log input](get-log-properties-task_id.md "http://schema.nethserver.org/imapsync/get-log.json#/properties/task_id")     |
| [localuser](#localuser) | `string` | Required | cannot be null | [get-log input](get-log-properties-localuser.md "http://schema.nethserver.org/imapsync/get-log.json#/properties/localuser") |

## task\_id



`task_id`

* is required

* Type: `string`

* cannot be null

* defined in: [get-log input](get-log-properties-task_id.md "http://schema.nethserver.org/imapsync/get-log.json#/properties/task_id")

### task\_id Type

`string`

### task\_id Constraints

**pattern**: the string must match the following regular expression:&#x20;

```regexp
^[a-z0-9]{6}$
```

[try pattern](https://regexr.com/?expression=%5E%5Ba-z0-9%5D%7B6%7D%24 "try regular expression with regexr.com")

## localuser



`localuser`

* is required

* Type: `string`

* cannot be null

* defined in: [get-log input](get-log-properties-localuser.md "http://schema.nethserver.org/imapsync/get-log.json#/properties/localuser")

### localuser Type

`string`

### localuser Constraints

**maximum length**: the maximum number of characters for this string is: `32`

**pattern**: the string must match the following regular expression:&#x20;

```regexp
^[a-z_][a-z0-9_.-]*$
```

[try pattern](https://regexr.com/?expression=%5E%5Ba-z_%5D%5Ba-z0-9_.-%5D*%24 "try regular expression with regexr.com")
