<script setup lang="ts">
import type { CommunityPost } from "~/api/community-posts";

const props = defineProps<{
  post: CommunityPost;
}>();

const { locale, t } = useI18n();
const localePath = useLocalePath();
const authorName = computed(
  () =>
    props.post.author?.username ??
    props.post.author_username ??
    t("community.deletedUser")
);
const body = computed(() => resolveCommunityPostBody(props.post));
const excerpt = computed(() => getContentExcerpt(body.value));
const publishedAt = computed(() =>
  formatContentDate(props.post.created_at, locale.value)
);
const postPath = computed(() =>
  localePath({
    name: "community-id",
    params: { id: props.post.id },
  })
);
</script>

<template>
  <article
    class="border-brand-200 bg-white/80 rounded-2xl border p-5 shadow-sm transition-shadow hover:shadow-md sm:p-6"
  >
    <div class="flex items-center gap-3">
      <UiUserAvatar
        :alt="$t('community.authorAvatar', { username: authorName })"
        :name="authorName"
        size="sm"
        :src="post.author?.avatar ?? undefined"
      />
      <div class="min-w-0">
        <p class="text-brand-900 truncate text-sm font-semibold">
          {{ authorName }}
        </p>
        <time class="text-brand-500 block text-xs" :datetime="post.created_at">
          {{ publishedAt }}
        </time>
      </div>
    </div>

    <p class="text-brand-900 mt-5 line-clamp-4 whitespace-pre-wrap leading-7">
      {{ excerpt }}
    </p>

    <div
      class="text-brand-500 mt-5 flex items-center justify-between gap-4 text-sm"
    >
      <div class="flex items-center gap-4">
        <span>{{ $t("community.likes", { count: post.like_count }) }}</span>
        <span>{{
          $t("community.comments", { count: post.comment_count })
        }}</span>
      </div>
      <NuxtLink
        :aria-label="$t('community.readPostBy', { username: authorName })"
        class="text-accent-600 hover:text-brand-900 rounded-sm font-semibold"
        :to="postPath"
      >
        {{ $t("community.readPost") }}
      </NuxtLink>
    </div>
  </article>
</template>
