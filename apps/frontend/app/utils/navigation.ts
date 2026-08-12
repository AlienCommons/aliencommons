export function resolveSafeRedirect(
  candidate: unknown,
  fallback: string
): string {
  const path = Array.isArray(candidate) ? candidate[0] : candidate;
  return typeof path === "string" &&
    path.startsWith("/") &&
    !path.startsWith("//")
    ? path
    : fallback;
}
