import { ApiResponseError } from "~/api/errors";
import { fetchCurrentUser, loginSession, logoutSession } from "~/api/session";
import type { LoginCredentials } from "~/api/session";

function isUnauthenticated(error: unknown): boolean {
  return (
    error instanceof ApiResponseError &&
    (error.status === 401 || error.status === 403)
  );
}

export function useAuthSession() {
  const api = useApi();
  const store = useAuthStore();
  const { isAuthenticated, status, user } = storeToRefs(store);

  async function refresh(): Promise<void> {
    store.setLoading();
    try {
      store.setAuthenticated(await fetchCurrentUser(api));
    } catch (error) {
      if (isUnauthenticated(error)) {
        store.setAnonymous();
        return;
      }

      store.setError();
    }
  }

  async function initialize(): Promise<void> {
    if (store.status !== "idle") {
      return;
    }
    await refresh();
  }

  async function login(credentials: LoginCredentials): Promise<void> {
    const csrfToken = await ensureCsrfToken();
    await loginSession(api, credentials, csrfToken);
    await refresh();

    if (!store.isAuthenticated) {
      throw new Error("The session was created without an authenticated user.");
    }
  }

  async function logout(): Promise<void> {
    try {
      const csrfToken = await ensureCsrfToken();
      await logoutSession(api, csrfToken);
      store.setAnonymous();
    } catch (error) {
      if (isUnauthenticated(error)) {
        store.setAnonymous();
        return;
      }
      throw error;
    }
  }

  return {
    initialize,
    isAuthenticated: readonly(isAuthenticated),
    login,
    logout,
    refresh,
    status: readonly(status),
    user: readonly(user),
  };
}
