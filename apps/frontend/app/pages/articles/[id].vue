<script setup lang="ts">
definePageMeta({
  validate: (route) => isUuid(route.params.id),
});

const route = useRoute();
const { locale, t } = useI18n();
const localePath = useLocalePath();
const publicationId = computed(() => String(route.params.id));
const {
  data: article,
  error,
  refresh,
  status,
} = await useArticlePublication(publicationId);

if (error.value?.statusCode === 404) {
  throw error.value;
}

const title = computed(() => article.value?.title ?? t("articles.untitled"));
const publishedAt = computed(() => {
  if (!article.value) {
    return "";
  }
  return formatContentDate(
    article.value.publication_at ?? article.value.published_at,
    locale.value
  );
});

useSeoMeta({
  description: () =>
    t("articles.detail.metaDescription", { title: title.value }),
  ogDescription: () =>
    t("articles.detail.metaDescription", { title: title.value }),
  ogTitle: title,
  title,
});
</script>

<template>
  <article class="mx-auto w-full max-w-3xl flex-1 px-5 py-14 sm:px-8 sm:py-20">
    <NuxtLink
      class="text-accent-600 hover:text-brand-900 rounded-sm text-sm font-semibold"
      :to="localePath('articles')"
    >
      {{ $t("articles.detail.back") }}
    </NuxtLink>

    <UiLoadingSkeleton
      v-if="status === 'pending'"
      class="mt-8"
      :label="$t('articles.loading')"
      :rows="10"
    />
    <UiEmptyState
      v-else-if="error || !article"
      class="mt-8"
      :description="$t('articles.error.description')"
      :title="$t('articles.error.title')"
    >
      <template #action>
        <UiBaseButton variant="secondary" @click="refresh()">
          {{ $t("articles.error.retry") }}
        </UiBaseButton>
      </template>
    </UiEmptyState>
    <div v-else>
      <header class="border-brand-200 mt-8 border-b pb-8">
        <p class="text-accent-600 text-sm font-bold tracking-widest uppercase">
          {{ $t("articles.detail.label") }}
        </p>
        <h1
          class="text-brand-900 mt-3 text-4xl leading-tight font-semibold tracking-tight text-balance sm:text-5xl"
        >
          {{ title }}
        </h1>
        <time
          class="text-brand-500 mt-4 block text-sm"
          :datetime="article.publication_at ?? article.published_at"
        >
          {{ publishedAt }}
        </time>
      </header>

      <ArticlesArticleBody
        v-if="article.html"
        class="mt-8"
        :html="article.html"
      />
      <UiEmptyState
        v-else
        class="mt-8"
        :description="$t('articles.emptyBody.description')"
        :title="$t('articles.emptyBody.title')"
      />

      <footer
        class="border-brand-200 text-brand-500 mt-12 flex flex-wrap gap-5 border-t pt-5 text-sm"
      >
        <span>{{ $t("articles.likes", { count: article.like_count }) }}</span>
        <span>{{
          $t("articles.dislikes", { count: article.dislike_count })
        }}</span>
        <span>{{
          $t("articles.comments", { count: article.comment_count })
        }}</span>
      </footer>
    </div>
  </article>
</template>
