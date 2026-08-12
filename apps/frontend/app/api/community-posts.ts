import type { components } from "~/api/generated/v1";

import type { ApiClient } from "./client";
import { unwrapApiResponse } from "./errors";

export type CommunityPost = components["schemas"]["CommunityPostRead"];
export type CommunityPostPage =
  components["schemas"]["PaginatedCommunityPostReadList"];

export async function listCommunityPosts(
  api: ApiClient,
  page = 1
): Promise<CommunityPostPage> {
  const response = unwrapApiResponse(
    await api.GET("/v1/community_posts/", {
      params: { query: { page } },
    })
  );
  return response.data;
}

export async function getCommunityPost(
  api: ApiClient,
  id: string
): Promise<CommunityPost> {
  const response = unwrapApiResponse(
    await api.GET("/v1/community_posts/{id}/", {
      params: { path: { id } },
    })
  );
  return response.data;
}
