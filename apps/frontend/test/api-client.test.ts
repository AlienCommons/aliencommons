import { describe, expect, it, vi } from "vite-plus/test";

import { createApiClient } from "../app/api/client";

function jsonResponse(): Response {
  return new Response(JSON.stringify({ data: {} }), {
    headers: { "content-type": "application/json" },
    status: 200,
  });
}

describe("createApiClient", () => {
  it("forwards the SSR cookie without adding CSRF to safe requests", async () => {
    const requests: Request[] = [];
    const api = createApiClient({
      baseUrl: "https://example.test/api",
      cookie: "sessionid=session",
      csrfToken: () => "csrf-token",
      fetch: async (request) => {
        requests.push(request);
        return jsonResponse();
      },
    });

    await api.GET("/v1/sessions/csrf/");

    expect(requests).toHaveLength(1);
    expect(requests[0]?.headers.get("cookie")).toBe("sessionid=session");
    expect(requests[0]?.headers.get("x-csrftoken")).toBeNull();
  });

  it("adds CSRF to unsafe requests and refreshes afterward", async () => {
    const requests: Request[] = [];
    const onUnsafeResponse = vi.fn<() => void>();
    const api = createApiClient({
      baseUrl: "https://example.test/api",
      csrfToken: () => "csrf-token",
      fetch: async (request) => {
        requests.push(request);
        return jsonResponse();
      },
      onUnsafeResponse,
    });

    await api.POST("/v1/sessions/login/", {
      body: { email: "user@example.test", password: "secret" },
      params: { header: { "X-CSRFToken": "csrf-token" } },
    });

    expect(requests[0]?.headers.get("x-csrftoken")).toBe("csrf-token");
    expect(onUnsafeResponse).toHaveBeenCalledOnce();
  });

  it("does not overwrite an explicitly supplied CSRF header", async () => {
    const requests: Request[] = [];
    const api = createApiClient({
      baseUrl: "https://example.test/api",
      csrfToken: () => "cookie-token",
      fetch: async (request) => {
        requests.push(request);
        return jsonResponse();
      },
    });

    await api.POST("/v1/sessions/login/", {
      body: { email: "user@example.test", password: "secret" },
      params: { header: { "X-CSRFToken": "explicit-token" } },
    });

    expect(requests[0]?.headers.get("x-csrftoken")).toBe("explicit-token");
  });
});
