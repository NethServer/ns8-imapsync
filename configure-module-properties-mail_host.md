# mail\_host Schema

```txt
http://schema.nethserver.org/imapsync/configure-module.json#/properties/mail_host
```

Host name for the remote account

| Abstract            | Extensible | Status         | Identifiable            | Custom Properties | Additional Properties | Access Restrictions | Defined In                                                                       |
| :------------------ | :--------- | :------------- | :---------------------- | :---------------- | :-------------------- | :------------------ | :------------------------------------------------------------------------------- |
| Can be instantiated | No         | Unknown status | Unknown identifiability | Forbidden         | Allowed               | none                | [configure-module.json\*](imapsync/configure-module.json "open original schema") |

## mail\_host Type

`string` ([mail\_host](configure-module-properties-mail_host.md))

## mail\_host Constraints

**(international) hostname**: the string must be an (IDN) hostname, according to [RFC 5890, section 2.3.2.3](https://tools.ietf.org/html/rfc5890 "check the specification")
