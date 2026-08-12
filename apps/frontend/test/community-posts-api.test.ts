import { describe, expect, it } from "vite-plus/test";

import {
  getCommunityPost,
  listCommunityPosts,
} from "../app/api/community-posts";
import { createApiClient } from "../app/api/client";

const postId = "00000000-0000-0000-0000-000000000001";

function envelope(data: unknown): Response {
  return new Response(JSON.stringify({ data }), {
    headers: { "content-type": "application/json" },
    status: 200,
  });
}

function post() {
  return {
    author: {
      id: "00000000-0000-0000-0000-000000000002",
      signature: "",
      username: "Builder",
    },
    author_username: "Builder",
    body: "Hello community",
    comment_count: 0,
    created_at: "2026-01-02T00:00:00Z",
    dislike_count: 0,
    id: postId,
    like_count: 1,
    mention_users: [],
    mentions: [],
    render_body: "Hello community",
    updated_at: "2026-01-02T00:00:00Z",
  };
}

describe("community posts API", () => {
  it("lists the requested page", async () => {
    const requests: Request[] = [];
    const api = createApiClient({
      baseUrl: "https://example.test/api",
      fetch: async (request) => {
        requests.push(request);
        return envelope({
          count: 1,
          current_page: 2,
          page_size: 20,
          results: [post()],
          total_pages: 2,
        });
      },
    });

    const result = await listCommunityPosts(api, 2);

    expect(requests[0]?.url).toBe(
      "https://example.test/api/v1/community_posts/?page=2"
    );
    expect(result.results[0]?.id).toBe(postId);
  });

  it("retrieves a post by id", async () => {
    const requests: Request[] = [];
    const api = createApiClient({
      baseUrl: "https://example.test/api",
      fetch: async (request) => {
        requests.push(request);
        return envelope(post());
      },
    });

    const result = await getCommunityPost(api, postId);

    expect(requests[0]?.url).toBe(
      `https://example.test/api/v1/community_posts/${postId}/`
    );
    expect(result.author_username).toBe("Builder");
  });
});
