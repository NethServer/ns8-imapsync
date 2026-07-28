<!--
  Copyright (C) 2023 Nethesis S.r.l.
  SPDX-License-Identifier: GPL-3.0-or-later
-->
<template>
  <NsModal
    kind="danger"
    size="default"
    :visible="isShown"
    @modal-hidden="$emit('hide')"
    @primary-click="$emit('confirm')"
  >
    <template slot="title"
      >{{ $t("tasks.delete_task") }}: {{ task.localuser }}</template
    >
    <template slot="content">
      <div>{{ $t("tasks.confirm_delete_task_message") }}</div>
    </template>
    <template slot="secondary-button">{{ core.$t("common.cancel") }}</template>
    <template slot="primary-button">{{ core.$t("common.delete") }}</template>
  </NsModal>
</template>

<script>
import { UtilService, IconService } from "@nethserver/ns8-ui-lib";
export default {
  name: "ConfirmDeleteTask",
  mixins: [UtilService, IconService],
  props: {
    isShown: Boolean,
    task: { type: [Object, null] },
    core: { type: Object },
  },
};
</script>

<style scoped lang="scss">
@import "../styles/carbon-utils";
</style>
