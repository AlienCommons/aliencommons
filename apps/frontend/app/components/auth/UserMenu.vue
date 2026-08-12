<script setup lang="ts">
import type { AuthUser } from "~/api/session";

defineProps<{
  pending: boolean;
  user: AuthUser;
}>();

defineEmits<{
  signOut: [];
}>();
</script>

<template>
  <div class="flex items-center gap-3">
    <div
      class="bg-brand-100 text-brand-900 flex size-9 shrink-0 items-center justify-center overflow-hidden rounded-full text-sm font-bold"
    >
      <img
        v-if="user.avatar"
        :alt="$t('auth.userMenu.avatarAlt', { username: user.username })"
        class="size-full object-cover"
        :src="user.avatar"
      />
      <span v-else aria-hidden="true">{{
        user.username.slice(0, 1).toUpperCase()
      }}</span>
    </div>
    <span
      class="text-brand-900 hidden max-w-36 truncate text-sm font-semibold md:block"
    >
      {{ user.username }}
    </span>
    <button
      :disabled="pending"
      class="text-brand-700 hover:text-brand-900 rounded-sm px-2 py-1 text-sm font-medium disabled:cursor-wait disabled:opacity-60"
      type="button"
      @click="$emit('signOut')"
    >
      {{ pending ? $t("auth.logout.submitting") : $t("auth.logout.submit") }}
    </button>
  </div>
</template>
