import type { components } from "~/api/generated/v1";

import type { ApiClient } from "./client";
import { unwrapApiResponse } from "./errors";

export type AuthUser = components["schemas"]["UserRetrieve"];
export type LoginCredentials = components["schemas"]["UserLoginRequest"];

export async function fetchCurrentUser(api: ApiClient): Promise<AuthUser> {
  const response = unwrapApiResponse(await api.GET("/v1/profiles/me/"));
  return response.data;
}

export async function loginSession(
  api: ApiClient,
  credentials: LoginCredentials,
  csrfToken: string
): Promise<void> {
  unwrapApiResponse(
    await api.POST("/v1/sessions/login/", {
      body: credentials,
      params: { header: { "X-CSRFToken": csrfToken } },
    })
  );
}

export async function logoutSession(
  api: ApiClient,
  csrfToken: string
): Promise<void> {
  unwrapApiResponse(
    await api.POST("/v1/sessions/logout/", {
      params: { header: { "X-CSRFToken": csrfToken } },
    })
  );
}
