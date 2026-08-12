<script setup lang="ts">
type AvatarSize = "lg" | "md" | "sm";

const props = withDefaults(
  defineProps<{
    alt?: string;
    name: string;
    size?: AvatarSize;
    src?: string;
  }>(),
  {
    alt: "",
    size: "md",
    src: undefined,
  }
);

const initial = computed(() => getAvatarInitial(props.name));
const sizeClass = computed(
  () =>
    ({
      lg: "size-12 text-base",
      md: "size-9 text-sm",
      sm: "size-7 text-xs",
    })[props.size]
);
</script>

<template>
  <span
    :aria-label="!src && alt ? alt : undefined"
    :class="[
      'bg-brand-100 text-brand-900 inline-flex shrink-0 items-center justify-center overflow-hidden rounded-full font-bold',
      sizeClass,
    ]"
    :role="!src && alt ? 'img' : undefined"
  >
    <img v-if="src" :alt="alt" class="size-full object-cover" :src="src" />
    <span v-else aria-hidden="true">{{ initial }}</span>
  </span>
</template>
