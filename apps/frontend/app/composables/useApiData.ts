import type { ApiClient } from "~/api/client";

export function useApiData<T>(
  key: string,
  handler: (api: ApiClient) => Promise<T>
) {
  const api = useApi();
  return useAsyncData<T>(key, () => handler(api));
}
