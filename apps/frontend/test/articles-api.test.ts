import { describe, expect, it } from "vite-plus/test";

import {
  getArticlePublication,
  listArticlePublications,
} from "../app/api/articles";
import { createApiClient } from "../app/api/client";

const publicationId = "00000000-0000-0000-0000-000000000001";

function envelope(data: unknown): Response {
  return new Response(JSON.stringify({ data }), {
    headers: { "content-type": "application/json" },
    status: 200,
  });
}

function publication() {
  return {
    article: "00000000-0000-0000-0000-000000000002",
    comment_count: 2,
    created_at: "2026-01-02T00:00:00Z",
    dislike_count: 0,
    html: "<p>Safe article</p>",
    id: publicationId,
    latest_version: undefined,
    like_count: 4,
    my_reaction: undefined,
    publication_at: "2026-01-02T00:00:00Z",
    published_at: "2026-01-02T00:00:00Z",
    title: "Redstone guide",
    updated_at: "2026-01-02T00:00:00Z",
    versions: [],
  };
}

describe("article publications API", () => {
  it("lists the requested page", async () => {
    const requests: Request[] = [];
    const api = createApiClient({
      baseUrl: "https://example.test/api",
      fetch: async (request) => {
        requests.push(request);
        return envelope({
          count: 1,
          current_page: 3,
          page_size: 20,
          results: [publication()],
          total_pages: 3,
        });
      },
    });

    const result = await listArticlePublications(api, 3);

    expect(requests[0]?.url).toBe(
      "https://example.test/api/v1/article_publications/?page=3"
    );
    expect(result.results[0]?.title).toBe("Redstone guide");
  });

  it("retrieves a publication by id", async () => {
    const requests: Request[] = [];
    const api = createApiClient({
      baseUrl: "https://example.test/api",
      fetch: async (request) => {
        requests.push(request);
        return envelope(publication());
      },
    });

    const result = await getArticlePublication(api, publicationId);

    expect(requests[0]?.url).toBe(
      `https://example.test/api/v1/article_publications/${publicationId}/`
    );
    expect(result.html).toBe("<p>Safe article</p>");
  });
});
