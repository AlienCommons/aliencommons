<script setup lang="ts">
import type { InputHTMLAttributes } from "vue";

defineOptions({ inheritAttrs: false });

withDefaults(
  defineProps<{
    disabled?: boolean;
    id: string;
    invalid?: boolean;
    type?: InputHTMLAttributes["type"];
  }>(),
  {
    disabled: false,
    invalid: false,
    type: "text",
  }
);

const model = defineModel<string>({ required: true });
</script>

<template>
  <input
    v-bind="$attrs"
    :id="id"
    v-model="model"
    :aria-invalid="invalid || undefined"
    class="border-brand-200 text-brand-900 placeholder:text-brand-500 focus:border-accent-600 w-full rounded-xl border bg-white px-4 py-3 shadow-sm transition-colors disabled:cursor-not-allowed disabled:bg-gray-100 disabled:opacity-70"
    :disabled="disabled"
    :type="type"
  />
</template>
