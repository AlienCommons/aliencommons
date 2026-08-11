<script setup lang="ts">
const { t } = useI18n();

useSeoMeta({
  description: () => t("home.description"),
  ogDescription: () => t("home.description"),
  ogTitle: () => t("home.metaTitle"),
  title: () => t("home.metaTitle"),
});
</script>

<template>
  <section
    class="mx-auto flex w-full max-w-6xl flex-1 items-center px-5 py-20 sm:px-8 sm:py-28"
  >
    <div class="max-w-3xl">
      <p
        class="text-accent-600 mb-5 text-sm font-bold tracking-widest uppercase"
      >
        {{ $t("home.eyebrow") }}
      </p>
      <h1
        class="text-brand-900 text-4xl leading-tight font-semibold tracking-tight text-balance sm:text-6xl"
      >
        {{ $t("home.title") }}
      </h1>
      <p
        class="text-brand-700 mt-6 max-w-2xl text-lg leading-8 text-pretty sm:text-xl"
      >
        {{ $t("home.description") }}
      </p>
      <div
        class="border-brand-200 bg-brand-100/65 mt-10 rounded-2xl border p-5 sm:p-6"
      >
        <p class="text-brand-900 font-semibold">{{ $t("home.statusTitle") }}</p>
        <p class="text-brand-700 mt-1 leading-7">
          {{ $t("home.statusDescription") }}
        </p>
      </div>
    </div>
  </section>
</template>
