import createClient from "openapi-fetch";
import type { Client, ClientOptions, Middleware } from "openapi-fetch";

import type { paths } from "./generated/v1";

const SAFE_METHODS = new Set(["GET", "HEAD", "OPTIONS", "TRACE"]);

export type ApiClient = Client<paths>;

export interface CreateApiClientOptions {
  baseUrl: string;
  cookie?: string;
  csrfToken?: () => string | undefined;
  fetch?: ClientOptions["fetch"];
  onUnsafeResponse?: () => void;
}

export function createApiClient(options: CreateApiClientOptions): ApiClient {
  const clientOptions: ClientOptions = {
    baseUrl: options.baseUrl,
    credentials: "include",
  };
  if (options.fetch) {
    clientOptions.fetch = options.fetch;
  }

  const client = createClient<paths>(clientOptions);
  const middleware: Middleware = {
    onRequest({ request }) {
      if (options.cookie && !request.headers.has("cookie")) {
        request.headers.set("cookie", options.cookie);
      }

      if (!SAFE_METHODS.has(request.method)) {
        const csrfToken = options.csrfToken?.();
        if (csrfToken && !request.headers.has("X-CSRFToken")) {
          request.headers.set("X-CSRFToken", csrfToken);
        }
      }
    },
    onResponse({ request }) {
      if (!SAFE_METHODS.has(request.method)) {
        options.onUnsafeResponse?.();
      }
    },
  };
  client.use(middleware);

  return client;
}
