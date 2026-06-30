# NS8 Module — Frontend Guide

## Stack & Vuex
Vue 2.6, Vuex, Vue Router, IBM Carbon Design System, `@nethserver/ns8-ui-lib`.
Views: `ui/src/views/` — Components: `ui/src/components/`

```javascript
import { mapState } from "vuex";
import { TaskService, UtilService, IconService, QueryParamService, PageTitleService } from "@nethserver/ns8-ui-lib";

export default {
  mixins: [TaskService, UtilService, IconService, QueryParamService, PageTitleService],
  computed: {
    ...mapState(["instanceName", "core", "appName"]),
  },
}
```

- `core` — parent NS8 shell Vue instance (module runs in iframe). Used for `this.core.$root.$once(...)`.
- `instanceName` — module ID e.g. `imapsync1`. Auto-extracted from URL by App.vue.
- Mixins: `TaskService`→`createModuleTaskForApp()`,`getUuid()` / `UtilService`→`clearErrors()`,`focusElement()`,`getErrorMessage()`

## Action call pattern

```javascript
import { to } from "await-to-js";

// data() structure
data: () => ({
  loading: { getConfiguration: false, configureModule: false },
  error:   { getConfiguration: "", configureModule: "", myField: "" },
  myField: "",
}),

created() { this.getConfiguration(); },

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
  this.myField = taskResult.output.my_field;
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

validateConfigureModule() {
  this.clearErrors(this);
  if (!this.myField) { this.error.myField = "common.required"; this.focusElement("myField"); return false; }
  return true;
},
configureModuleAborted(taskResult, taskContext) {
  console.error(`${taskContext.action} aborted`, taskResult);
  this.error.configureModule = this.$t("error.generic_error");
  this.loading.configureModule = false;
},
configureModuleValidationFailed(validationErrors) {
  this.loading.configureModule = false;
  for (const e of validationErrors) { this.error[e.parameter] = this.$t("settings." + e.error); }
  this.focusElement(validationErrors[0].parameter);
},
```

Backend validation payload: `[{field, parameter, error}]` — `parameter` maps to `error` object key.

## Template

```html
<cv-form @submit.prevent="configureModule">
  <NsTextInput v-model.trim="myField" :label="$t('s.label')" ref="myField"
    :invalid-message="$t(error.myField)" :disabled="loading.configureModule" />

  <NsComboBox v-model.trim="myField" :title="$t('s.title')" :label="$t('s.placeholder')"
    :options="list" :invalid-message="$t(error.myField)" ref="myField"
    :disabled="loading.getConfiguration || loading.configureModule" />

  <NsButton kind="primary" :icon="Save20" :loading="loading.configureModule"
    :disabled="loading.getConfiguration || loading.configureModule">
    {{ $t("settings.save") }}
  </NsButton>

  <NsInlineNotification v-if="error.configureModule" kind="error"
    :title="$t('action.configure-module')" :description="error.configureModule" :showCloseButton="false" />
</cv-form>
```

`ref="myField"` must match `focusElement("myField")`.

## ns8-ui-lib components

Source: `github.com/NethServer/ns8-ui-lib` — read `src/lib-components/<Name>.vue` for props.

`NsButton` `NsTextInput` `NsPasswordInput` `NsComboBox` `NsComboSearchBox` `NsMultiSelect`
`NsToggle` `NsCheckbox` `NsSlider` `NsByteSlider` `NsTimePicker` `NsModal` `NsDangerDeleteModal`
`NsInlineNotification` `NsToastNotification` `NsDataTable` `NsPagination` `NsEmptyState`
`NsStatusCard` `NsInfoCard` `NsTile` `NsTabs` `NsProgress` `NsProgressBar`
`NsSystemdServiceCard` `NsSystemLogsCard` `NsWizard` `NsCodeSnippet` `NsTag`

## Translations
Only edit `ui/public/i18n/en/translation.json`. Other languages updated automatically by Renovate.
