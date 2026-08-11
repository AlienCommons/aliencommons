<script setup lang="ts">
import type { NuxtError } from "#app";

const props = defineProps<{
  error: NuxtError;
}>();

const { t } = useI18n();
const localePath = useLocalePath();
const isNotFound = computed(() => props.error.statusCode === 404);
const title = computed(() =>
  t(isNotFound.value ? "error.notFoundTitle" : "error.genericTitle")
);
const description = computed(() =>
  t(isNotFound.value ? "error.notFoundDescription" : "error.genericDescription")
);

useSiteHead();
useSeoMeta({
  robots: "noindex, nofollow",
  title,
});

function returnHome() {
  clearError({ redirect: localePath("index") });
}
</script>

<template>
  <main
    class="mx-auto grid min-h-dvh w-full max-w-3xl place-items-center px-5 py-16 text-center sm:px-8"
  >
    <div>
      <p class="text-accent-600 text-sm font-bold tracking-widest uppercase">
        {{ error.statusCode || 500 }}
      </p>
      <h1
        class="text-brand-900 mt-4 text-4xl font-semibold tracking-tight sm:text-5xl"
      >
        {{ title }}
      </h1>
      <p class="text-brand-700 mx-auto mt-5 max-w-xl text-lg leading-8">
        {{ description }}
      </p>
      <button
        class="bg-brand-900 hover:bg-brand-700 mt-8 rounded-lg px-5 py-3 text-sm font-semibold text-white transition-colors"
        type="button"
        @click="returnHome"
      >
        {{ $t("error.returnHome") }}
      </button>
    </div>
  </main>
</template>
