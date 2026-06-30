# NS8 Module — Frontend Guide

## Stack & Vuex
Vue 2.6, Vuex, Vue Router, IBM Carbon Design System, `@nethserver/ns8-ui-lib`.
Views: `ui/src/views/` — Components: `ui/src/components/`

```javascript
import { mapState } from "vuex";
import { TaskService, UtilService, IconService, QueryParamService, PageTitleService, DateTimeService } from "@nethserver/ns8-ui-lib";

export default {
  mixins: [TaskService, UtilService, IconService, QueryParamService, PageTitleService, DateTimeService],
  computed: {
    ...mapState(["instanceName", "core", "appName"]),
  },
}
```

- `core` — parent NS8 shell Vue instance (module runs in iframe). Used for `this.core.$root.$once(...)`.
- `instanceName` — module ID e.g. `imapsync1`. Auto-extracted from URL by App.vue.
- Before writing utility code, check `ns8-ui-lib/src/lib-mixins/` — all 8 mixins are already available via import.

| Mixin | Key methods / data |
|---|---|
| `TaskService` | `createModuleTaskForApp()`, `createNodeTaskForApp()`, `createErrorNotificationForApp()`, `createNotificationForApp()`, `deleteNotificationForApp()`, `getTaskStatus()`, `getTaskKind()` |
| `UtilService` | `getErrorMessage()`, `clearErrors()`, `focusElement()`, `goToAppPage()`, `getUuid()`, `sortByProperty(prop)`, `isJson(s)`, `tryParseJson(s)` |
| `DateTimeService` | `formatDate` (date-fns format), `formatDateDistance`, `parseIsoDate`, `dateIsBefore`, `formatInTimeZone(date,fmt,tz)` |
| `StorageService` | `getFromStorage(prop)`, `saveToStorage(prop, obj)`, `deleteFromStorage(prop)` — localStorage wrappers, do NOT use `localStorage` directly |
| `QueryParamService` | `queryParamsToDataForApp()`, `watchQueryData()` — sync URL query params ↔ component data |
| `IconService` | **~150 Carbon icons injected into `data()`** — use directly as `:icon="Save20"` without importing. Check `ns8-ui-lib/src/lib-mixins/icon.js` before importing an icon manually. Common: `Save20`, `TrashCan20`, `Edit20`, `Add20`, `Settings20`, `Information16`, `CheckmarkFilled20`, `ErrorFilled20`, `Warning20`, `Restart20` |
| `PageTitleService` | Sets browser tab title automatically |
| `LottieService` | Lottie animation helpers |

## Router

Standard views in every module: `status` (default `/`), `settings`, `tasks`, `about`.

Navigate with `goToAppPage()` from `UtilService` mixin — do NOT use `this.$router.push()` directly:
```javascript
this.goToAppPage(this.instanceName, "settings");
this.goToAppPage(this.instanceName, "status");
```

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

## Task progress

Add `isProgressNotified: true` in `extra`, use `$on` (not `$once`) for repeated events.
Unregister in **completed, aborted, AND validation-failed** — all terminal states:

```javascript
this.myProgress = 0;  // reset before call — indeterminate until first value arrives
this.core.$root.$on(`${taskAction}-progress-${eventId}`, this.myActionProgressUpdated);

// in extra:
extra: { ..., isProgressNotified: true, eventId },

// ALL terminal callbacks (completed, aborted, validation-failed):
this.core.$root.$off(`${taskContext.action}-progress-${taskContext.extra.eventId}`);

myActionProgressUpdated(progress) {
  this.myProgress = progress;  // 0-100
},
```

```html
<NsProgressBar :value="myProgress" :indeterminate="!myProgress" />
```

Both sides required: backend calls `agent.set_progress(0-100)`, frontend sets `isProgressNotified: true` — neither works alone. See AGENTS-backend.md § Agent SDK.

## Template

Import Carbon icons with size suffix, register in `components`, use as `:icon` prop:
```javascript
import Save20        from "@carbon/icons-vue/es/save/20";
import TrashCan16    from "@carbon/icons-vue/es/trash-can/16";
import Play20        from "@carbon/icons-vue/es/play--outline/20";  // double-dash before variant

export default {
  components: { Save20, TrashCan16, Play20 },
}
```
Pattern: `@carbon/icons-vue/es/<kebab-name>/<size>`. Multi-word: single dash (`trash-can`), variants: double dash (`play--outline`, `add--alt`).

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

### Vue filters (registered globally — use directly in templates)

Source: `ns8-ui-lib/src/lib-filters/filters.js` — registered in `main.js` via `Vue.filter()`.

| Filter | Input | Output example |
|---|---|---|
| `byteFormat` | bytes (int) | `1536 → "1.5 KiB"` |
| `humanFormat` | any number | `1500 → "2 K"` (pass `true` for 1 decimal) |
| `mibFormat` | MiB (int) | `2048 → "2 GiB"` |
| `gibFormat` | GiB (int) | `2048 → "2 TiB"` |
| `secondsFormat` | seconds | `3661 → "1h 1m 1s"` |
| `secondsLongFormat` | seconds | `3661 → "01h 01m 01s"` |

```html
{{ fileSize | byteFormat }}
{{ duration | secondsFormat }}
```

### NsWizard
Props: `visible` (Boolean), `isLastStep` (replaces Next→Finish), `isNextLoading`, `isNextDisabled`, `isPreviousDisabled`, `isCancelDisabled`, `isPreviousShown`, `isCancelShown`.
Slots: `#title`, `#content`. Events: `@cancel`, `@previousStep`, `@nextStep`.

```html
<NsWizard
  :visible="isWizardVisible"
  :isLastStep="currentStep === steps.length - 1"
  :isNextLoading="loading.nextStep"
  @cancel="isWizardVisible = false"
  @previousStep="currentStep--"
  @nextStep="handleNextStep"
>
  <template #title>{{ $t("wizard.title") }}</template>
  <template #content><!-- step content --></template>
</NsWizard>
```

## Translations
Only edit `ui/public/i18n/en/translation.json`. Other languages updated automatically by Renovate.
