# configure-module input Schema

```txt
http://schema.nethserver.org/imapsync/configure-module.json
```

Configure the module application

| Abstract            | Extensible | Status         | Identifiable | Custom Properties | Additional Properties | Access Restrictions | Defined In                                                                     |
| :------------------ | :--------- | :------------- | :----------- | :---------------- | :-------------------- | :------------------ | :----------------------------------------------------------------------------- |
| Can be instantiated | No         | Unknown status | No           | Forbidden         | Forbidden             | none                | [configure-module.json](imapsync/configure-module.json "open original schema") |

## configure-module input Type

`object` ([configure-module input](configure-module.md))

## configure-module input Examples

```json
{
  "mail_server": "e8a6177c-9ae5-4356-826b-0a5f93b2dbaf",
  "mail_host": "10.5.4.1"
}
```

# configure-module input Properties

| Property                     | Type     | Required | Nullable       | Defined by                                                                                                                                                 |
| :--------------------------- | :------- | :------- | :------------- | :--------------------------------------------------------------------------------------------------------------------------------------------------------- |
| [mail\_host](#mail_host)     | `string` | Required | cannot be null | [configure-module input](configure-module-properties-mail_host.md "http://schema.nethserver.org/imapsync/configure-module.json#/properties/mail_host")     |
| [mail\_server](#mail_server) | `string` | Required | cannot be null | [configure-module input](configure-module-properties-mail_server.md "http://schema.nethserver.org/imapsync/configure-module.json#/properties/mail_server") |

## mail\_host

Host name for the remote account

`mail_host`

*   is required

*   Type: `string` ([mail\_host](configure-module-properties-mail_host.md))

*   cannot be null

*   defined in: [configure-module input](configure-module-properties-mail_host.md "http://schema.nethserver.org/imapsync/configure-module.json#/properties/mail_host")

### mail\_host Type

`string` ([mail\_host](configure-module-properties-mail_host.md))

### mail\_host Constraints

**(international) hostname**: the string must be an (IDN) hostname, according to [RFC 5890, section 2.3.2.3](https://tools.ietf.org/html/rfc5890 "check the specification")

## mail\_server

module\_uuid of the mail server like 9b9a7388-a661-4399-a7d2-c2ab08f4227c

`mail_server`

*   is required

*   Type: `string` ([mail\_server](configure-module-properties-mail_server.md))

*   cannot be null

*   defined in: [configure-module input](configure-module-properties-mail_server.md "http://schema.nethserver.org/imapsync/configure-module.json#/properties/mail_server")

### mail\_server Type

`string` ([mail\_server](configure-module-properties-mail_server.md))
