<script setup lang="ts">
const props = defineProps<{
  description?: string;
  error?: string;
  id: string;
  label: string;
  required?: boolean;
}>();

defineSlots<{
  default(props: {
    describedBy: string | undefined;
    id: string;
    invalid: boolean;
  }): unknown;
}>();

const descriptionId = computed(() =>
  props.description ? `${props.id}-description` : undefined
);
const errorId = computed(() => (props.error ? `${props.id}-error` : undefined));
const describedBy = computed(
  () =>
    [descriptionId.value, errorId.value].filter(Boolean).join(" ") || undefined
);
</script>

<template>
  <div>
    <label class="text-brand-900 mb-2 block text-sm font-semibold" :for="id">
      {{ label }}
      <span v-if="required" aria-hidden="true" class="text-red-700">*</span>
    </label>
    <slot :described-by="describedBy" :id="id" :invalid="Boolean(error)" />
    <p
      v-if="description"
      :id="descriptionId"
      class="text-brand-700 mt-2 text-sm leading-6"
    >
      {{ description }}
    </p>
    <p v-if="error" :id="errorId" class="mt-2 text-sm text-red-700">
      {{ error }}
    </p>
  </div>
</template>
