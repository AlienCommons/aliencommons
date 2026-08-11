<script setup lang="ts">
const { locale } = useI18n();

const localeOptions = [
  { code: "en", label: "EN", nameKey: "locale.english" },
  { code: "zh", label: "中文", nameKey: "locale.chinese" },
] as const;
</script>

<template>
  <div
    :aria-label="$t('locale.label')"
    class="border-brand-200 bg-brand-50 flex rounded-lg border p-1"
    role="group"
  >
    <SwitchLocalePathLink
      v-for="option in localeOptions"
      :key="option.code"
      :aria-current="locale === option.code ? 'true' : undefined"
      :aria-label="$t(option.nameKey)"
      :class="[
        'rounded-md px-2.5 py-1 text-xs font-semibold transition-colors',
        locale === option.code
          ? 'bg-brand-900 text-white shadow-sm'
          : 'text-brand-700 hover:bg-brand-100 hover:text-brand-900',
      ]"
      :locale="option.code"
    >
      {{ option.label }}
    </SwitchLocalePathLink>
  </div>
</template>
