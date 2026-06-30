# NS8 Module — Frontend Guide

## Stack
Vue 2.6, Vuex, Vue Router, IBM Carbon Design System, `@nethserver/ns8-ui-lib`.
Entry: `ui/src/main.js`. Views in `ui/src/views/`, components in `ui/src/components/`.

Mixins from `@nethserver/ns8-ui-lib` (import and declare in `mixins: []`):

| Mixin | Provides |
|---|---|
| `TaskService` | `createModuleTaskForApp()`, `getUuid()` |
| `UtilService` | `clearErrors()`, `focusElement()`, `getErrorMessage()` |
| `IconService` | Carbon icon helpers |
| `QueryParamService` | URL query param binding (`watchQueryData`, `initUrlBindingForApp`) |
| `PageTitleService` | `pageTitle()` hook |

## Calling a backend action

All backend calls use `TaskService.createModuleTaskForApp()` wrapped with `await-to-js`:

```javascript
import { to } from "await-to-js";

const eventId = this.getUuid();
this.core.$root.$once(`my-action-completed-${eventId}`, this.myActionCompleted);
this.core.$root.$once(`my-action-aborted-${eventId}`,   this.myActionAborted);

const res = await to(
  this.createModuleTaskForApp(this.instanceName, {
    action: "my-action",
    data: { key: value },          // omit for read-only actions
    extra: {
      title: this.$t("action.my-action"),
      isNotificationHidden: true,  // hide from notification center
      eventId,
    },
  })
);
const err = res[0];
if (err) {
  this.error.myAction = this.getErrorMessage(err);
  this.loading.myAction = false;
}
```

## get-configuration / configure-module cycle

Standard pattern for a Settings view:

```javascript
// lifecycle — load on mount
created() {
  this.getConfiguration();
},

async getConfiguration() {
  this.loading.getConfiguration = true;
  const eventId = this.getUuid();
  this.core.$root.$once(`get-configuration-completed-${eventId}`, this.getConfigurationCompleted);
  this.core.$root.$once(`get-configuration-aborted-${eventId}`,   this.getConfigurationAborted);
  const res = await to(this.createModuleTaskForApp(this.instanceName, {
    action: "get-configuration",
    extra: { title: this.$t("action.get-configuration"), isNotificationHidden: true, eventId },
  }));
  if (res[0]) { this.error.getConfiguration = this.getErrorMessage(res[0]); this.loading.getConfiguration = false; }
},
getConfigurationCompleted(taskContext, taskResult) {
  const config = taskResult.output;
  this.myField = config.my_field;
  this.loading.getConfiguration = false;
},

async configureModule() {
  if (!this.validateConfigureModule()) return;
  this.loading.configureModule = true;
  const eventId = this.getUuid();
  this.core.$root.$once(`configure-module-validation-failed-${eventId}`, this.configureModuleValidationFailed);
  this.core.$root.$once(`configure-module-completed-${eventId}`,         this.configureModuleCompleted);
  this.core.$root.$once(`configure-module-aborted-${eventId}`,           this.configureModuleAborted);
  const res = await to(this.createModuleTaskForApp(this.instanceName, {
    action: "configure-module",
    data: { my_field: this.myField },
    extra: { title: this.$t("settings.configuring"), eventId },
  }));
  if (res[0]) { this.error.configureModule = this.getErrorMessage(res[0]); this.loading.configureModule = false; }
},
```

## Validation error handling

### Frontend (before sending to backend)
```javascript
validateConfigureModule() {
  this.clearErrors(this);
  if (!this.myField) {
    this.error.myField = "common.required";
    this.focusElement("myField");
    return false;
  }
  return true;
},
```

### Backend validation-failed
```javascript
configureModuleValidationFailed(validationErrors) {
  this.loading.configureModule = false;
  for (const validationError of validationErrors) {
    this.error[validationError.parameter] = this.$t("settings." + validationError.error);
  }
  this.focusElement(validationErrors[0].parameter);
},
```

Backend sends `[{'field': 'my_field', 'parameter': 'my_field', 'error': 'not_valid'}]` —
`parameter` maps to the component's `error` object key.

## Standard data() structure

```javascript
data() {
  return {
    loading: {
      getConfiguration: false,
      configureModule: false,
    },
    error: {
      getConfiguration: "",
      configureModule: "",
      myField: "",        // one entry per validated field
    },
    myField: "",          // form fields
  };
},
```

## Translations
Files live in `ui/public/i18n/<lang>/translation.json`.
**Only edit `ui/public/i18n/en/translation.json`.**
All other language files are updated automatically by Renovate — never edit them manually.
