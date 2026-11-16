# get-configuration output Schema

```txt
http://schema.nethserver.org/imapsync/get-configuration-output.json
```

Get imapsync configuration

| Abstract            | Extensible | Status         | Identifiable | Custom Properties | Additional Properties | Access Restrictions | Defined In                                                                                     |
| :------------------ | :--------- | :------------- | :----------- | :---------------- | :-------------------- | :------------------ | :--------------------------------------------------------------------------------------------- |
| Can be instantiated | No         | Unknown status | No           | Forbidden         | Allowed               | none                | [get-configuration-output.json](imapsync/get-configuration-output.json "open original schema") |

## get-configuration output Type

`object` ([get-configuration output](get-configuration-output.md))

# get-configuration output Properties

| Property                            | Type     | Required | Nullable       | Defined by                                                                                                                                                                           |
| :---------------------------------- | :------- | :------- | :------------- | :----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| [mail_server](#mail_server)         | `string` | Required | cannot be null | [get-configuration output](get-configuration-output-properties-mail_server.md "http://schema.nethserver.org/imapsync/get-configuration-output.json#/properties/mail_server")         |
| [mail_host](#mail_host)             | `string` | Required | cannot be null | [get-configuration output](get-configuration-output-properties-mail_host.md "http://schema.nethserver.org/imapsync/get-configuration-output.json#/properties/mail_host")             |
| [mail_server_URL](#mail_server_url) | `array`  | Required | cannot be null | [get-configuration output](get-configuration-output-properties-mail_server_url.md "http://schema.nethserver.org/imapsync/get-configuration-output.json#/properties/mail_server_URL") |

## mail_server



`mail_server`

* is required

* Type: `string`

* cannot be null

* defined in: [get-configuration output](get-configuration-output-properties-mail_server.md "http://schema.nethserver.org/imapsync/get-configuration-output.json#/properties/mail_server")

### mail_server Type

`string`

## mail_host



`mail_host`

* is required

* Type: `string`

* cannot be null

* defined in: [get-configuration output](get-configuration-output-properties-mail_host.md "http://schema.nethserver.org/imapsync/get-configuration-output.json#/properties/mail_host")

### mail_host Type

`string`

## mail_server_URL



`mail_server_URL`

* is required

* Type: `object[]` ([Details](get-configuration-output-properties-mail_server_url-items.md))

* cannot be null

* defined in: [get-configuration output](get-configuration-output-properties-mail_server_url.md "http://schema.nethserver.org/imapsync/get-configuration-output.json#/properties/mail_server_URL")

### mail_server_URL Type

`object[]` ([Details](get-configuration-output-properties-mail_server_url-items.md))
