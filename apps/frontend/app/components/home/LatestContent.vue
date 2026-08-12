<script setup lang="ts">
const localePath = useLocalePath();
const [articleState, postState] = await Promise.all([
  useArticleList(1, { key: "home-article-publications" }),
  useCommunityPostList(1, { key: "home-community-posts" }),
]);

const latestArticles = computed(
  () => articleState.data.value?.results.slice(0, 4) ?? []
);
const latestPosts = computed(
  () => postState.data.value?.results.slice(0, 3) ?? []
);
</script>

<template>
  <div class="mt-20 space-y-20">
    <section aria-labelledby="latest-articles">
      <div class="flex items-end justify-between gap-5">
        <div>
          <p
            class="text-accent-600 text-sm font-bold tracking-widest uppercase"
          >
            {{ $t("home.latestArticlesEyebrow") }}
          </p>
          <h2
            id="latest-articles"
            class="text-brand-900 mt-2 text-3xl font-semibold tracking-tight"
          >
            {{ $t("home.latestArticlesTitle") }}
          </h2>
        </div>
        <NuxtLink
          class="text-accent-600 hover:text-brand-900 hidden rounded-sm text-sm font-semibold sm:block"
          :to="localePath('articles')"
        >
          {{ $t("home.viewAllArticles") }}
        </NuxtLink>
      </div>

      <UiLoadingSkeleton
        v-if="articleState.status.value === 'pending'"
        class="mt-8"
        :label="$t('articles.loading')"
        :rows="6"
      />
      <UiEmptyState
        v-else-if="articleState.error.value"
        class="mt-8"
        :description="$t('articles.error.description')"
        :title="$t('articles.error.title')"
      >
        <template #action>
          <UiBaseButton variant="secondary" @click="articleState.refresh()">
            {{ $t("articles.error.retry") }}
          </UiBaseButton>
        </template>
      </UiEmptyState>
      <UiEmptyState
        v-else-if="latestArticles.length === 0"
        class="mt-8"
        :description="$t('articles.empty.description')"
        :title="$t('articles.empty.title')"
      />
      <ArticlesArticleList v-else class="mt-8" :articles="latestArticles" />
    </section>

    <section aria-labelledby="latest-community-posts">
      <div class="flex items-end justify-between gap-5">
        <div>
          <p
            class="text-accent-600 text-sm font-bold tracking-widest uppercase"
          >
            {{ $t("home.latestPostsEyebrow") }}
          </p>
          <h2
            id="latest-community-posts"
            class="text-brand-900 mt-2 text-3xl font-semibold tracking-tight"
          >
            {{ $t("home.latestPostsTitle") }}
          </h2>
        </div>
        <NuxtLink
          class="text-accent-600 hover:text-brand-900 hidden rounded-sm text-sm font-semibold sm:block"
          :to="localePath('community')"
        >
          {{ $t("home.viewAllPosts") }}
        </NuxtLink>
      </div>

      <UiLoadingSkeleton
        v-if="postState.status.value === 'pending'"
        class="mt-8"
        :label="$t('community.loading')"
        :rows="6"
      />
      <UiEmptyState
        v-else-if="postState.error.value"
        class="mt-8"
        :description="$t('community.error.description')"
        :title="$t('community.error.title')"
      >
        <template #action>
          <UiBaseButton variant="secondary" @click="postState.refresh()">
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
