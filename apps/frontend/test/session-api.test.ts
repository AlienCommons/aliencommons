import { describe, expect, it } from "vite-plus/test";

import { createApiClient } from "../app/api/client";
import {
  fetchCurrentUser,
  loginSession,
  logoutSession,
} from "../app/api/session";

const emptyResponseData: unknown = JSON.parse("null");

function envelope(data: unknown): Response {
  return new Response(JSON.stringify({ data }), {
    headers: { "content-type": "application/json" },
    status: 200,
  });
}

describe("session API", () => {
  it("retrieves the current user", async () => {
    const api = createApiClient({
      baseUrl: "https://example.test/api",
      fetch: async () =>
        envelope({
          avatar: "https://example.test/avatar.png",
          date_joined: "2026-01-01T00:00:00Z",
          email: "player@example.test",
          id: "00000000-0000-0000-0000-000000000001",
          is_moderator: false,
          signature: "",
          username: "Player",
        }),
    });

    await expect(fetchCurrentUser(api)).resolves.toMatchObject({
      username: "Player",
    });
  });

  it("sends credentials and CSRF when logging in", async () => {
    const requests: Request[] = [];
    const api = createApiClient({
      baseUrl: "https://example.test/api",
      fetch: async (request) => {
        requests.push(request);
        return envelope(emptyResponseData);
      },
    });

    await loginSession(
      api,
      { email: "player@example.test", password: "secret" },
      "csrf-token"
    );

    expect(requests[0]?.url).toBe(
      "https://example.test/api/v1/sessions/login/"
    );
    expect(requests[0]?.headers.get("x-csrftoken")).toBe("csrf-token");
    await expect(requests[0]?.json()).resolves.toEqual({
      email: "player@example.test",
      password: "secret",
    });
  });

  it("sends CSRF when logging out", async () => {
    const requests: Request[] = [];
    const api = createApiClient({
      baseUrl: "https://example.test/api",
      fetch: async (request) => {
        requests.push(request);
        return envelope(emptyResponseData);
      },
    });

    await logoutSession(api, "csrf-token");

    expect(requests[0]?.url).toBe(
      "https://example.test/api/v1/sessions/logout/"
    );
    expect(requests[0]?.headers.get("x-csrftoken")).toBe("csrf-token");
  });
});
