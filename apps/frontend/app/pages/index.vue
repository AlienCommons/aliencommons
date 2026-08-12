<script setup lang="ts">
const { t } = useI18n();
const localePath = useLocalePath();

useSeoMeta({
  description: () => t("home.description"),
  ogDescription: () => t("home.description"),
  ogTitle: () => t("home.metaTitle"),
  title: () => t("home.metaTitle"),
});

const { data, error, refresh, status } = await useCommunityPostList(1, {
  key: "home-community-posts",
});
const latestPosts = computed(() => data.value?.results.slice(0, 3) ?? []);
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
          :to="localePath('community')"
        >
          {{ $t("home.exploreCommunity") }}
        </NuxtLink>
      </div>
    </section>

    <section aria-labelledby="latest-community-posts" class="mt-20">
      <div class="flex items-end justify-between gap-5">
        <div>
          <p
            class="text-accent-600 text-sm font-bold tracking-widest uppercase"
          >
            {{ $t("home.latestEyebrow") }}
          </p>
          <h2
            id="latest-community-posts"
            class="text-brand-900 mt-2 text-3xl font-semibold tracking-tight"
          >
            {{ $t("home.latestTitle") }}
          </h2>
        </div>
        <NuxtLink
          class="text-accent-600 hover:text-brand-900 hidden rounded-sm text-sm font-semibold sm:block"
          :to="localePath('community')"
        >
          {{ $t("home.viewAll") }}
        </NuxtLink>
      </div>

      <UiLoadingSkeleton
        v-if="status === 'pending'"
        class="mt-8"
        :label="$t('community.loading')"
        :rows="6"
      />
      <UiEmptyState
        v-else-if="error"
        class="mt-8"
        :description="$t('community.error.description')"
        :title="$t('community.error.title')"
      >
        <template #action>
          <UiBaseButton variant="secondary" @click="refresh()">
            {{ $t("community.error.retry") }}
          </UiBaseButton>
        </template>
      </UiEmptyState>
      <UiEmptyState
        v-else-if="latestPosts.length === 0"
        class="mt-8"
        :description="$t('community.empty.description')"
        :title="$t('community.empty.title')"
      />
      <CommunityCommunityPostList v-else class="mt-8" :posts="latestPosts" />
    </section>
  </div>
</template>
