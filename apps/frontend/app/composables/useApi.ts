import type { ApiClient } from "~/api/client";

export function useApi(): ApiClient {
  return useNuxtApp().$api;
}
