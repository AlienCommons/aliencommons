import type { MaybeRefOrGetter } from "vue";

import { getArticlePublication, listArticlePublications } from "~/api/articles";
import { ApiResponseError } from "~/api/errors";

interface ArticleListOptions {
  key?: string;
}

export function useArticleList(
  page: MaybeRefOrGetter<number>,
  options: ArticleListOptions = {}
) {
  const api = useApi();
  const resolvedPage = computed(() => toValue(page));

  return useAsyncData(
    options.key ?? "article-publication-list",
    () => listArticlePublications(api, resolvedPage.value),
    { watch: [resolvedPage] }
  );
}

export function useArticlePublication(id: MaybeRefOrGetter<string>) {
  const api = useApi();
  const resolvedId = computed(() => toValue(id));

  return useAsyncData(
    "article-publication-detail",
    async () => {
      try {
        return await getArticlePublication(api, resolvedId.value);
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
