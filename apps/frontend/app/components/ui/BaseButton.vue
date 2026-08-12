<script setup lang="ts">
import type { ButtonHTMLAttributes } from "vue";

type ButtonSize = "sm" | "md";
type ButtonVariant = "danger" | "ghost" | "primary" | "secondary";

const props = withDefaults(
  defineProps<{
    block?: boolean;
    disabled?: boolean;
    loading?: boolean;
    size?: ButtonSize;
    type?: ButtonHTMLAttributes["type"];
    variant?: ButtonVariant;
  }>(),
  {
    block: false,
    disabled: false,
    loading: false,
    size: "md",
    type: "button",
    variant: "primary",
  }
);

defineSlots<{
  default(): unknown;
}>();

const buttonClasses = computed(() => [
  "inline-flex items-center justify-center gap-2 rounded-xl font-semibold shadow-sm transition-colors",
  "disabled:cursor-not-allowed disabled:opacity-60",
  props.block ? "w-full" : "w-auto",
  props.size === "sm" ? "px-3 py-2 text-sm" : "px-4 py-3",
  {
    danger: "bg-red-700 text-white hover:bg-red-800",
    ghost: "text-brand-700 shadow-none hover:bg-brand-100 hover:text-brand-900",
    primary: "bg-brand-900 text-white hover:bg-brand-700",
    secondary:
      "border-brand-200 bg-white text-brand-900 border hover:bg-brand-100",
  }[props.variant],
]);
</script>

<template>
  <button
    :aria-busy="loading || undefined"
    :class="buttonClasses"
    :disabled="disabled || loading"
    :type="type"
  >
    <span
      v-if="loading"
      aria-hidden="true"
      class="size-4 animate-spin rounded-full border-2 border-current border-r-transparent motion-reduce:animate-none"
    />
    <slot />
  </button>
</template>
