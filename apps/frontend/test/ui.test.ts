import { describe, expect, it } from "vite-plus/test";

import { getAvatarInitial, getSkeletonRowIds } from "../app/utils/ui";

describe("UI utilities", () => {
  it("normalizes avatar initials", () => {
    expect(getAvatarInitial("  player")).toBe("P");
    expect(getAvatarInitial(" ")).toBe("?");
  });

  it("creates stable skeleton row identifiers", () => {
    expect(getSkeletonRowIds(3)).toEqual([1, 2, 3]);
    expect(getSkeletonRowIds(0)).toEqual([1]);
    expect(getSkeletonRowIds(Number.POSITIVE_INFINITY)).toEqual([1]);
  });
});
