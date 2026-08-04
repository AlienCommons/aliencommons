import { unwrapApiResponse } from "~/api/errors";

export async function ensureCsrfToken(): Promise<string> {
  if (import.meta.server) {
    throw new Error("CSRF bootstrap must run in the browser.");
  }

  const api = useApi();
  const payload = unwrapApiResponse(await api.GET("/v1/sessions/csrf/"));
  refreshCookie("csrftoken");
  return payload.data.csrf_token;
}
