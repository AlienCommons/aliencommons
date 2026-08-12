<script setup lang="ts">
import type { CommunityPost } from "~/api/community-posts";

defineProps<{
  posts: CommunityPost[];
}>();
</script>

<template>
  <div class="grid gap-5">
    <CommunityCommunityPostCard
      v-for="post in posts"
      :key="post.id"
      :post="post"
    />
  </div>
</template>
