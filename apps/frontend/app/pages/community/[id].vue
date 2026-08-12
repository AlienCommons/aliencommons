<script setup lang="ts">
definePageMeta({
  validate: (route) => isUuid(route.params.id),
});

const route = useRoute();
const { locale, t } = useI18n();
const localePath = useLocalePath();
const postId = computed(() => String(route.params.id));
const { data: post, error, refresh, status } = await useCommunityPost(postId);

if (error.value?.statusCode === 404) {
  throw error.value;
}

const authorName = computed(
  () =>
    post.value?.author?.username ??
    post.value?.author_username ??
    t("community.deletedUser")
);
const body = computed(() =>
  post.value ? resolveCommunityPostBody(post.value) : ""
);
const publishedAt = computed(() =>
  post.value ? formatContentDate(post.value.created_at, locale.value) : ""
);

useSeoMeta({
  description: () => getContentExcerpt(body.value, 160),
  title: () => t("community.detail.metaTitle", { username: authorName.value }),
});
</script>

<template>
  <article class="mx-auto w-full max-w-3xl flex-1 px-5 py-14 sm:px-8 sm:py-20">
    <NuxtLink
      class="text-accent-600 hover:text-brand-900 rounded-sm text-sm font-semibold"
      :to="localePath('community')"
    >
      {{ $t("community.detail.back") }}
    </NuxtLink>

    <UiLoadingSkeleton
      v-if="status === 'pending'"
      class="mt-8"
      :label="$t('community.loading')"
      :rows="9"
    />
    <UiEmptyState
      v-else-if="error || !post"
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
    <div v-else class="mt-8">
      <header class="flex items-center gap-4">
        <UiUserAvatar
          :alt="$t('community.authorAvatar', { username: authorName })"
          :name="authorName"
          :src="post.author?.avatar ?? undefined"
        />
        <div>
          <p class="text-brand-900 font-semibold">{{ authorName }}</p>
          <time class="text-brand-500 text-sm" :datetime="post.created_at">
            {{ publishedAt }}
          </time>
        </div>
      </header>

      <p
        class="text-brand-900 mt-8 whitespace-pre-wrap text-lg leading-8 break-words"
      >
        {{ body }}
      </p>

      <footer
        class="border-brand-200 text-brand-500 mt-10 flex gap-5 border-t pt-5 text-sm"
      >
        <span>{{ $t("community.likes", { count: post.like_count }) }}</span>
        <span>{{
          $t("community.dislikes", { count: post.dislike_count })
        }}</span>
        <span>{{
          $t("community.comments", { count: post.comment_count })
        }}</span>
      </footer>
    </div>
  </article>
</template>
