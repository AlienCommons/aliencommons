import { describe, expect, it } from "vite-plus/test";

import { resolveSafeRedirect } from "../app/utils/navigation";

describe("resolveSafeRedirect", () => {
  it("accepts a same-origin application path", () => {
    expect(resolveSafeRedirect("/zh/articles/42", "/zh")).toBe(
      "/zh/articles/42"
    );
  });

  it.each(["//malicious.test", "https://malicious.test", undefined])(
    "rejects unsafe redirect %s",
    (candidate) => {
      expect(resolveSafeRedirect(candidate, "/zh")).toBe("/zh");
    }
  );
});
