import { defineStore } from "pinia";
import { computed, shallowRef } from "vue";

import type { AuthUser } from "~/api/session";

export type AuthStatus =
  | "idle"
  | "loading"
  | "authenticated"
  | "anonymous"
  | "error";

export const useAuthStore = defineStore("auth", () => {
  const status = shallowRef<AuthStatus>("idle");
  const user = shallowRef<AuthUser>();

  const isAuthenticated = computed(
    () => status.value === "authenticated" && user.value !== undefined
  );

  function setLoading(): void {
    status.value = "loading";
  }

  function setAuthenticated(nextUser: AuthUser): void {
    user.value = nextUser;
    status.value = "authenticated";
  }

  function setAnonymous(): void {
    user.value = undefined;
    status.value = "anonymous";
  }

  function setError(): void {
    status.value = "error";
  }

  return {
    isAuthenticated,
    setAnonymous,
    setAuthenticated,
    setError,
    setLoading,
    status,
    user,
  };
});
