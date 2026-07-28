<!--
  Copyright (C) 2023 Nethesis S.r.l.
  SPDX-License-Identifier: GPL-3.0-or-later
-->
<template>
  <NsModal size="default" :visible="isShown" @modal-hidden="onModalHidden">
    <template slot="title"
      >{{ $t("tasks.compare_accounts") }}:
      {{ task.localuser + "/" + task.remoteusername }}
    </template>
    <template slot="content">
      <template v-if="loading.toggleListInformations">
        <div>{{ $t("tasks.fetching_statistic_please_wait") }}</div>
        <cv-skeleton-text :paragraph="true" :line-count="4"></cv-skeleton-text>
      </template>
      <template
        v-if="!loading.toggleListInformations && currentInformation.status"
      >
        <div class="key-value-setting">
          <span class="label">{{
            $t("tasks.local_account_host2Folders")
          }}</span>
          <span class="value">{{ currentInformation.host2Folders }}</span>
        </div>
        <div class="key-value-setting">
          <span class="label">{{
            $t("tasks.remote_account_host1Folders")
          }}</span>
          <span class="value">{{ currentInformation.host1Folders }}</span>
        </div>
        <div class="key-value-setting">
          <span class="label">{{
            $t("tasks.local_account_host2Messages")
          }}</span>
          <span class="value">{{ currentInformation.host2Messages }}</span>
        </div>
        <div class="key-value-setting">
          <span class="label">{{
            $t("tasks.remote_account_host1Messages")
          }}</span>
          <span class="value">{{ currentInformation.host1Messages }}</span>
        </div>
        <div class="key-value-setting">
          <span class="label">{{ $t("tasks.local_account_host2Sizes") }}</span>
          <span class="value">{{
            currentInformation.host2Sizes | byteFormat
          }}</span>
        </div>
        <div class="key-value-setting">
          <span class="label">{{ $t("tasks.remote_account_host1Sizes") }}</span>
          <span class="value">{{
            currentInformation.host1Sizes | byteFormat
          }}</span>
        </div>
      </template>
      <template
        v-if="!loading.toggleListInformations && !currentInformation.status"
      >
        <div>{{ $t("tasks.something_wrong_cannot_list_informations") }}</div>
      </template>
    </template>
  </NsModal>
</template>

<script>
import to from "await-to-js";
import { mapState } from "vuex";
import { UtilService, IconService, TaskService } from "@nethserver/ns8-ui-lib";

export default {
  name: "ShowInformations",
  mixins: [UtilService, IconService, TaskService],
  props: {
    isShown: Boolean,
    task: { type: [Object, null] },
  },
  data() {
    return {
      loading: {
        toggleListInformations: false,
      },
      error: {
        toggleListInformations: "",
      },
      currentInformation: {
        status: false,
        host2Folders: "",
        host1Folders: "",
        host2Messages: "",
        host1Messages: "",
        host2Sizes: "",
        host1Sizes: "",
      },
    };
  },

  computed: {
    ...mapState(["instanceName", "core", "appName"]),
  },
  watch: {
    isShown: function () {
      if (this.isShown) {
        this.toggleListInformations();
      }
    },
  },
  methods: {
    async toggleListInformations() {
      const taskAction = "list-informations";
      const eventId = this.getUuid();
      this.loading.toggleListInformations = true;
      // register to task events
      this.core.$root.$once(
        `${taskAction}-aborted-${eventId}`,
        this.toggleListInformationsAborted
      );
      this.core.$root.$once(
        `${taskAction}-completed-${eventId}`,
        this.toggleListInformationsCompleted
      );
      const res = await to(
        this.createModuleTaskForApp(this.instanceName, {
          action: taskAction,
          data: { task_id: this.task.task_id, localuser: this.task.localuser },
          extra: {
            title: this.$t("action." + taskAction),
            isNotificationHidden: true,
            eventId,
          },
        })
      );
      const err = res[0];

      if (err) {
        console.error(`error creating task ${taskAction}`, err);
        const errMessage = this.getErrorMessage(err);
        this.error.toggleListInformations = errMessage;
        this.loading.toggleListInformations = false;
      }
    },
    toggleListInformationsAborted(taskResult, taskContext) {
      console.error(`${taskContext.action} aborted`, taskResult);
      this.error.toggleListInformations = this.$t("error.generic_error");
      this.loading.toggleListInformations = false;
    },
    toggleListInformationsCompleted(taskContext, taskResult) {
      let Config = taskResult.output;
      this.currentInformation.status = Config.status;
      this.currentInformation.host1Folders = Config.host1Folders;
      this.currentInformation.host2Folders = Config.host2Folders;
      this.currentInformation.host1Messages = Config.host1Messages;
      this.currentInformation.host2Messages = Config.host2Messages;
      this.currentInformation.host2Sizes = Config.host2Sizes;
      this.currentInformation.host1Sizes = Config.host1Sizes;
      this.loading.toggleListInformations = false;
    },
    onModalHidden() {
      this.loading.toggleListInformations = false;

      this.clearErrors();
      this.$emit("hide");
    },
  },
};
</script>

<style scoped lang="scss">
@import "../styles/carbon-utils";
</style>
