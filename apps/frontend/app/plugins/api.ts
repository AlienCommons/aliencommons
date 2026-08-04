import type { ClientOptions } from "openapi-fetch";

import { createApiClient } from "~/api/client";

const MISSING_INTERNAL_API_URL = "http://nuxt-api-base.invalid";

export default defineNuxtPlugin(() => {
  const config = useRuntimeConfig();
  const incomingHeaders = import.meta.server
    ? useRequestHeaders(["cookie"])
    : {};
  const csrfCookie = useCookie<string | null>("csrftoken", {
    readonly: true,
  });

  const apiInternalBase = config.apiInternalBase.trim();
  const missingInternalBase = import.meta.server && !apiInternalBase;
  const baseUrl = import.meta.server
    ? apiInternalBase || MISSING_INTERNAL_API_URL
    : config.public.apiBase;
  const unavailableFetch: ClientOptions["fetch"] = async () => {
    throw new Error(
      "NUXT_API_INTERNAL_BASE must be configured for server-side API requests."
    );
  };

  const api = createApiClient({
    baseUrl,
    cookie: incomingHeaders.cookie,
    csrfToken: () => csrfCookie.value ?? undefined,
    fetch: missingInternalBase ? unavailableFetch : undefined,
    onUnsafeResponse: import.meta.client
      ? () => refreshCookie("csrftoken")
      : undefined,
  });

  return {
    provide: {
      api,
    },
  };
});
