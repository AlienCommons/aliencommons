import { describe, expect, it } from "vite-plus/test";

import en from "../i18n/locales/en.json";
import zh from "../i18n/locales/zh.json";

function messageKeys(messages: object, prefix = ""): string[] {
  return Object.entries(messages).flatMap(([key, value]) => {
    const path = prefix ? `${prefix}.${key}` : key;
    return typeof value === "object" && value !== null
      ? messageKeys(value, path)
      : [path];
  });
}

describe("locale messages", () => {
  it("keeps English and Chinese translation keys in sync", () => {
    expect(messageKeys(zh).sort()).toEqual(messageKeys(en).sort());
  });
});
