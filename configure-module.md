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

| Property                    | Type     | Required | Nullable       | Defined by                                                                                                                                                 |
| :-------------------------- | :------- | :------- | :------------- | :--------------------------------------------------------------------------------------------------------------------------------------------------------- |
| [mail_host](#mail_host)     | `string` | Required | cannot be null | [configure-module input](configure-module-properties-mail_host.md "http://schema.nethserver.org/imapsync/configure-module.json#/properties/mail_host")     |
| [mail_server](#mail_server) | `string` | Required | cannot be null | [configure-module input](configure-module-properties-mail_server.md "http://schema.nethserver.org/imapsync/configure-module.json#/properties/mail_server") |

## mail_host

Host name for the remote account

`mail_host`

* is required

* Type: `string` ([mail_host](configure-module-properties-mail_host.md))

* cannot be null

* defined in: [configure-module input](configure-module-properties-mail_host.md "http://schema.nethserver.org/imapsync/configure-module.json#/properties/mail_host")

### mail_host Type

`string` ([mail_host](configure-module-properties-mail_host.md))

### mail_host Constraints

**pattern**: the string must match the following regular expression:&#x20;

```regexp
\.
```

[try pattern](https://regexr.com/?expression=%5C. "try regular expression with regexr.com")

**hostname**: the string must be a hostname, according to [RFC 1123, section 2.1](https://tools.ietf.org/html/rfc1123 "check the specification")

## mail_server

module_uuid of the mail server like 9b9a7388-a661-4399-a7d2-c2ab08f4227c

`mail_server`

* is required

* Type: `string` ([mail_server](configure-module-properties-mail_server.md))

* cannot be null

* defined in: [configure-module input](configure-module-properties-mail_server.md "http://schema.nethserver.org/imapsync/configure-module.json#/properties/mail_server")

### mail_server Type

`string` ([mail_server](configure-module-properties-mail_server.md))
