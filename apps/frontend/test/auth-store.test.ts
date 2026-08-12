import { createPinia, setActivePinia } from "pinia";
import { beforeEach, describe, expect, it } from "vite-plus/test";

import type { AuthUser } from "../app/api/session";
import { useAuthStore } from "../app/stores/auth";

const user: AuthUser = {
  avatar: "https://example.test/avatar.png",
  date_joined: "2026-01-01T00:00:00Z",
  email: "player@example.test",
  id: "00000000-0000-0000-0000-000000000001",
  is_moderator: false,
  signature: "",
  username: "Player",
};

describe("auth store", () => {
  beforeEach(() => {
    setActivePinia(createPinia());
  });

  it("moves from loading to an authenticated user", () => {
    const store = useAuthStore();

    store.setLoading();
    store.setAuthenticated(user);

    expect(store.status).toBe("authenticated");
    expect(store.isAuthenticated).toBe(true);
    expect(store.user).toEqual(user);
  });

  it("clears user data when the session becomes anonymous", () => {
    const store = useAuthStore();
    store.setAuthenticated(user);

    store.setAnonymous();

    expect(store.status).toBe("anonymous");
    expect(store.isAuthenticated).toBe(false);
    expect(store.user).toBeUndefined();
  });
});
