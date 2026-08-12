export function getAvatarInitial(name: string): string {
  return name.trim().slice(0, 1).toUpperCase() || "?";
}

export function getSkeletonRowIds(rows: number): number[] {
  const count = Number.isFinite(rows) ? Math.max(1, Math.trunc(rows)) : 1;
  return Array.from({ length: count }, (_, index) => index + 1);
}
