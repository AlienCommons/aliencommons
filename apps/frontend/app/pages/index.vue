<script setup lang="ts">
const { t } = useI18n();
const localePath = useLocalePath();

useSeoMeta({
  description: () => t("home.description"),
  ogDescription: () => t("home.description"),
  ogTitle: () => t("home.metaTitle"),
  title: () => t("home.metaTitle"),
});
</script>

<template>
  <div class="mx-auto w-full max-w-6xl flex-1 px-5 py-16 sm:px-8 sm:py-24">
    <section class="max-w-3xl">
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
      <div class="mt-9 flex flex-wrap gap-3">
        <NuxtLink
          class="bg-brand-900 hover:bg-brand-700 rounded-xl px-5 py-3 font-semibold text-white transition-colors"
          :to="localePath('articles')"
        >
          {{ $t("home.exploreArticles") }}
        </NuxtLink>
        <NuxtLink
          class="border-brand-200 bg-white text-brand-900 hover:bg-brand-100 rounded-xl border px-5 py-3 font-semibold transition-colors"
          :to="localePath('community')"
        >
          {{ $t("home.exploreCommunity") }}
        </NuxtLink>
      </div>
    </section>
    <HomeLatestContent />
  </div>
</template>
