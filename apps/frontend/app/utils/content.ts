export function parsePageNumber(value: unknown): number {
  const candidate = Array.isArray(value) ? value[0] : value;
  const page = typeof candidate === "string" ? Number(candidate) : candidate;
  return typeof page === "number" && Number.isInteger(page) && page > 0
    ? page
    : 1;
}

export function formatContentDate(value: string, locale: string): string {
  return new Intl.DateTimeFormat(locale, {
    dateStyle: "medium",
    timeZone: "UTC",
  }).format(new Date(value));
}

export function getContentExcerpt(value: string, maximumLength = 220): string {
  const normalized = value.replace(/\s+/g, " ").trim();
  if (normalized.length <= maximumLength) {
    return normalized;
  }
  return `${normalized.slice(0, maximumLength).trimEnd()}…`;
}

export function isUuid(value: unknown): value is string {
  return (
    typeof value === "string" &&
    /^[\da-f]{8}-(?:[\da-f]{4}-){3}[\da-f]{12}$/i.test(value)
  );
}
