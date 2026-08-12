<script setup lang="ts">
import type { ArticlePublication } from "~/api/articles";

defineProps<{
  articles: ArticlePublication[];
}>();
</script>

<template>
  <div class="grid gap-5 sm:grid-cols-2">
    <ArticlesArticleCard
      v-for="article in articles"
      :key="article.id"
      :article="article"
    />
  </div>
</template>
