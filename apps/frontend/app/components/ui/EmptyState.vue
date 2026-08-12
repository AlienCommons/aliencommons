<script setup lang="ts">
defineProps<{
  description: string;
  title: string;
}>();

defineSlots<{
  action?(): unknown;
  icon?(): unknown;
}>();
</script>

<template>
  <section
    class="border-brand-200 bg-brand-100/55 rounded-2xl border px-6 py-10 text-center"
  >
    <div v-if="$slots.icon" class="text-accent-600 mx-auto mb-4 w-fit">
      <slot name="icon" />
    </div>
    <h2 class="text-brand-900 text-xl font-semibold">{{ title }}</h2>
    <p class="text-brand-700 mx-auto mt-2 max-w-lg leading-7">
      {{ description }}
    </p>
    <div v-if="$slots.action" class="mt-6 flex justify-center">
      <slot name="action" />
    </div>
  </section>
</template>
