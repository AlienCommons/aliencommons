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
    <UiUserAvatar
      :alt="$t('auth.userMenu.avatarAlt', { username: user.username })"
      :name="user.username"
      :src="user.avatar ?? undefined"
    />
    <span
      class="text-brand-900 hidden max-w-36 truncate text-sm font-semibold md:block"
    >
      {{ user.username }}
    </span>
    <UiBaseButton
      :loading="pending"
      size="sm"
      variant="ghost"
      @click="$emit('signOut')"
    >
      {{ pending ? $t("auth.logout.submitting") : $t("auth.logout.submit") }}
    </UiBaseButton>
  </div>
</template>
