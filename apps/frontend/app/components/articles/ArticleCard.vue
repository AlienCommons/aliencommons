<script setup lang="ts">
import type { ArticlePublication } from "~/api/articles";

const props = defineProps<{
  article: ArticlePublication;
}>();

const { locale, t } = useI18n();
const localePath = useLocalePath();
const title = computed(() => props.article.title ?? t("articles.untitled"));
const publishedAt = computed(() =>
  formatContentDate(
    props.article.publication_at ?? props.article.published_at,
    locale.value
  )
);
const articlePath = computed(() =>
  localePath({
    name: "articles-id",
    params: { id: props.article.id },
  })
);
</script>

<template>
  <article
    class="border-brand-200 bg-white/80 rounded-2xl border p-5 shadow-sm transition-shadow hover:shadow-md sm:p-6"
  >
    <p class="text-accent-600 text-xs font-bold tracking-widest uppercase">
      {{ $t("articles.card.label") }}
    </p>
    <h2 class="text-brand-900 mt-3 text-2xl font-semibold tracking-tight">
      <NuxtLink class="rounded-sm" :to="articlePath">{{ title }}</NuxtLink>
    </h2>
    <time
      class="text-brand-500 mt-3 block text-sm"
      :datetime="article.publication_at ?? article.published_at"
    >
      {{ publishedAt }}
    </time>

    <div
      class="text-brand-500 mt-6 flex items-center justify-between gap-4 text-sm"
    >
      <div class="flex items-center gap-4">
        <span>{{ $t("articles.likes", { count: article.like_count }) }}</span>
        <span>{{
          $t("articles.comments", { count: article.comment_count })
        }}</span>
      </div>
      <NuxtLink
        :aria-label="$t('articles.readNamed', { title })"
        class="text-accent-600 hover:text-brand-900 rounded-sm font-semibold"
        :to="articlePath"
      >
        {{ $t("articles.read") }}
      </NuxtLink>
    </div>
  </article>
</template>
