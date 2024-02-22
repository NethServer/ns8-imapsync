# get-configuration output Schema

```txt
http://schema.nethserver.org/imapsync/list-informations-output.json
```

Get imapsync informations on folders/emails count and folders/emails size

| Abstract            | Extensible | Status         | Identifiable | Custom Properties | Additional Properties | Access Restrictions | Defined In                                                                                     |
| :------------------ | :--------- | :------------- | :----------- | :---------------- | :-------------------- | :------------------ | :--------------------------------------------------------------------------------------------- |
| Can be instantiated | No         | Unknown status | No           | Forbidden         | Allowed               | none                | [list-informations-output.json](imapsync/list-informations-output.json "open original schema") |

## get-configuration output Type

`object` ([get-configuration output](list-informations-output.md))

## get-configuration output Examples

```json
{
  "status": true,
  "host1Folders": 45,
  "host2Folders": 45,
  "host1Messages": 61884,
  "host2Messages": 1609,
  "host2Sizes": 553971344,
  "host1Sizes": 30805127
}
```

# get-configuration output Properties

| Property                        | Type      | Required | Nullable       | Defined by                                                                                                                                                                       |
| :------------------------------ | :-------- | :------- | :------------- | :------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| [status](#status)               | `boolean` | Required | cannot be null | [get-configuration output](list-informations-output-properties-status.md "http://schema.nethserver.org/imapsync/list-informations-output.json#/properties/status")               |
| [host1Folders](#host1folders)   | `integer` | Optional | cannot be null | [get-configuration output](list-informations-output-properties-host1folders.md "http://schema.nethserver.org/imapsync/list-informations-output.json#/properties/host1Folders")   |
| [host2Folders](#host2folders)   | `integer` | Optional | cannot be null | [get-configuration output](list-informations-output-properties-host2folders.md "http://schema.nethserver.org/imapsync/list-informations-output.json#/properties/host2Folders")   |
| [host1Messages](#host1messages) | `integer` | Optional | cannot be null | [get-configuration output](list-informations-output-properties-host1messages.md "http://schema.nethserver.org/imapsync/list-informations-output.json#/properties/host1Messages") |
| [host2Messages](#host2messages) | `integer` | Optional | cannot be null | [get-configuration output](list-informations-output-properties-host2messages.md "http://schema.nethserver.org/imapsync/list-informations-output.json#/properties/host2Messages") |
| [host2Sizes](#host2sizes)       | `integer` | Optional | cannot be null | [get-configuration output](list-informations-output-properties-host2sizes.md "http://schema.nethserver.org/imapsync/list-informations-output.json#/properties/host2Sizes")       |
| [host1Sizes](#host1sizes)       | `integer` | Optional | cannot be null | [get-configuration output](list-informations-output-properties-host1sizes.md "http://schema.nethserver.org/imapsync/list-informations-output.json#/properties/host1Sizes")       |

## status



`status`

*   is required

*   Type: `boolean`

*   cannot be null

*   defined in: [get-configuration output](list-informations-output-properties-status.md "http://schema.nethserver.org/imapsync/list-informations-output.json#/properties/status")

### status Type

`boolean`

## host1Folders



`host1Folders`

*   is optional

*   Type: `integer`

*   cannot be null

*   defined in: [get-configuration output](list-informations-output-properties-host1folders.md "http://schema.nethserver.org/imapsync/list-informations-output.json#/properties/host1Folders")

### host1Folders Type

`integer`

## host2Folders



`host2Folders`

*   is optional

*   Type: `integer`

*   cannot be null

*   defined in: [get-configuration output](list-informations-output-properties-host2folders.md "http://schema.nethserver.org/imapsync/list-informations-output.json#/properties/host2Folders")

### host2Folders Type

`integer`

## host1Messages



`host1Messages`

*   is optional

*   Type: `integer`

*   cannot be null

*   defined in: [get-configuration output](list-informations-output-properties-host1messages.md "http://schema.nethserver.org/imapsync/list-informations-output.json#/properties/host1Messages")

### host1Messages Type

`integer`

## host2Messages



`host2Messages`

*   is optional

*   Type: `integer`

*   cannot be null

*   defined in: [get-configuration output](list-informations-output-properties-host2messages.md "http://schema.nethserver.org/imapsync/list-informations-output.json#/properties/host2Messages")

### host2Messages Type

`integer`

## host2Sizes



`host2Sizes`

*   is optional

*   Type: `integer`

*   cannot be null

*   defined in: [get-configuration output](list-informations-output-properties-host2sizes.md "http://schema.nethserver.org/imapsync/list-informations-output.json#/properties/host2Sizes")

### host2Sizes Type

`integer`

## host1Sizes



`host1Sizes`

*   is optional

*   Type: `integer`

*   cannot be null

*   defined in: [get-configuration output](list-informations-output-properties-host1sizes.md "http://schema.nethserver.org/imapsync/list-informations-output.json#/properties/host1Sizes")

### host1Sizes Type

`integer`
