<script setup lang="ts">
const route = useRoute();
const { t } = useI18n();
const page = computed(() => parsePageNumber(route.query.page));

useSeoMeta({
  description: () => t("community.list.description"),
  title: () => t("community.list.metaTitle"),
});

const { data, error, refresh, status } = await useCommunityPostList(page);
</script>

<template>
  <section class="mx-auto w-full max-w-4xl flex-1 px-5 py-14 sm:px-8 sm:py-20">
    <p class="text-accent-600 text-sm font-bold tracking-widest uppercase">
      {{ $t("community.eyebrow") }}
    </p>
    <h1 class="text-brand-900 mt-3 text-4xl font-semibold tracking-tight">
      {{ $t("community.list.title") }}
    </h1>
    <p class="text-brand-700 mt-3 max-w-2xl leading-7">
      {{ $t("community.list.description") }}
    </p>

    <UiLoadingSkeleton
      v-if="status === 'pending'"
      class="mt-10"
      :label="$t('community.loading')"
      :rows="7"
    />
    <UiEmptyState
      v-else-if="error"
      class="mt-10"
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
      v-else-if="!data?.results.length"
      class="mt-10"
      :description="$t('community.empty.description')"
      :title="$t('community.empty.title')"
    />
    <template v-else>
      <CommunityCommunityPostList class="mt-10" :posts="data.results" />
      <CommunityCommunityPagination
        v-if="data.total_pages > 1"
        :current-page="data.current_page"
        :total-pages="data.total_pages"
      />
    </template>
  </section>
</template>
