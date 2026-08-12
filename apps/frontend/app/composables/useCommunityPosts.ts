import type { MaybeRefOrGetter } from "vue";

import { getCommunityPost, listCommunityPosts } from "~/api/community-posts";
import { ApiResponseError } from "~/api/errors";

interface CommunityPostListOptions {
  key?: string;
}

export function useCommunityPostList(
  page: MaybeRefOrGetter<number>,
  options: CommunityPostListOptions = {}
) {
  const api = useApi();
  const resolvedPage = computed(() => toValue(page));

  return useAsyncData(
    options.key ?? "community-post-list",
    () => listCommunityPosts(api, resolvedPage.value),
    { watch: [resolvedPage] }
  );
}

export function useCommunityPost(id: MaybeRefOrGetter<string>) {
  const api = useApi();
  const resolvedId = computed(() => toValue(id));

  return useAsyncData(
    "community-post-detail",
    async () => {
      try {
        return await getCommunityPost(api, resolvedId.value);
      } catch (error) {
        if (error instanceof ApiResponseError && error.status === 404) {
          throw createError({ statusCode: 404, statusMessage: "Not Found" });
        }
        throw error;
      }
    },
    { watch: [resolvedId] }
  );
}
