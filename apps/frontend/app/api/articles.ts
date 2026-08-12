import type { components } from "~/api/generated/v1";

import type { ApiClient } from "./client";
import { unwrapApiResponse } from "./errors";

export type ArticlePublication = components["schemas"]["ArticlePublication"];
export type ArticlePublicationPage =
  components["schemas"]["PaginatedArticlePublicationList"];

export async function listArticlePublications(
  api: ApiClient,
  page = 1
): Promise<ArticlePublicationPage> {
  const response = unwrapApiResponse(
    await api.GET("/v1/article_publications/", {
      params: { query: { page } },
    })
  );
  return response.data;
}

export async function getArticlePublication(
  api: ApiClient,
  id: string
): Promise<ArticlePublication> {
  const response = unwrapApiResponse(
    await api.GET("/v1/article_publications/{id}/", {
      params: { path: { id } },
    })
  );
  return response.data;
}
