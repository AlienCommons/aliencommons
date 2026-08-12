<script setup lang="ts">
const props = withDefaults(
  defineProps<{
    label?: string;
    rows?: number;
  }>(),
  {
    label: undefined,
    rows: 3,
  }
);

const rowIds = computed(() => getSkeletonRowIds(props.rows));
</script>

<template>
  <div :role="label ? 'status' : undefined" class="space-y-3">
    <span v-if="label" class="sr-only">{{ label }}</span>
    <span
      v-for="row in rowIds"
      :key="row"
      aria-hidden="true"
      :class="[
        'bg-brand-200 block h-4 animate-pulse rounded-full motion-reduce:animate-none',
        row === rowIds.length ? 'w-2/3' : 'w-full',
      ]"
    />
  </div>
</template>
