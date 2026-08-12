import { describe, expect, it } from "vite-plus/test";

import {
  formatContentDate,
  getContentExcerpt,
  isUuid,
  parsePageNumber,
  resolveCommunityPostBody,
} from "../app/utils/community-posts";

describe("community post utilities", () => {
  it.each([
    ["3", 3],
    [["2", "4"], 2],
    ["0", 1],
    ["invalid", 1],
    [undefined, 1],
  ])("normalizes page value %j", (value, expected) => {
    expect(parsePageNumber(value)).toBe(expected);
  });

  it("formats dates in a deterministic UTC timezone", () => {
    expect(formatContentDate("2026-01-02T23:30:00-08:00", "en-US")).toBe(
      "Jan 3, 2026"
    );
  });

  it("resolves mention tokens as safe plain text", () => {
    expect(
      resolveCommunityPostBody({
        body: "Hello {{mention:0}} and {{mention:2}}",
        mention_users: [{ user_id: "user-id", username: "Builder" }],
      })
    ).toBe("Hello @Builder and {{mention:2}}");
  });

  it("truncates normalized excerpts", () => {
    expect(getContentExcerpt("  one\n two three  ", 7)).toBe("one two…");
  });

  it("recognizes UUID route parameters", () => {
    expect(isUuid("00000000-0000-0000-0000-000000000001")).toBe(true);
    expect(isUuid("not-a-uuid")).toBe(false);
  });
});
