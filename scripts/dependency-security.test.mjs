import assert from "node:assert/strict";
import { createRequire } from "node:module";
import { test } from "node:test";

// Resolve the actual Nitro build dependency, not a separate test-only copy.
let dependencyRequire = createRequire(
  new URL("../apps/frontend/package.json", import.meta.url)
);
for (const dependency of [
  "nuxt/package.json",
  "@nuxt/nitro-server/package.json",
  "nitropack/package.json",
  "@rollup/plugin-node-resolve",
]) {
  dependencyRequire = createRequire(dependencyRequire.resolve(dependency));
}

for (const entry of ["deepmerge", "deepmerge/dist/umd.js"]) {
  const merge = dependencyRequire(entry);
  test(`${entry}: GHSA-gcqx-w48m-w2h4 cannot poison result prototypes`, () => {
    const payload = JSON.parse('{"__proto__":{"polluted":true}}');
    for (const result of [
      merge(payload, {}),
      merge(Object.create(null), payload),
      merge(payload, payload),
      merge({}, { nested: payload }).nested,
      merge.all([payload, { safe: true }]),
    ]) {
      assert.equal(Object.getPrototypeOf(result), Object.prototype);
      assert.equal(result.polluted, undefined);
      assert.equal(Object.hasOwn(result, "__proto__"), false);
    }
    assert.equal({}.polluted, undefined);
  });

  test(`${entry}: preserves ordinary nested, array and symbol merges`, () => {
    const key = Symbol("option");
    const target = { nested: { left: 1 }, values: [1], [key]: { left: 1 } };
    const source = { nested: { right: 2 }, values: [2], [key]: { right: 2 } };
    assert.deepEqual(merge(target, source), {
      nested: { left: 1, right: 2 },
      values: [1, 2],
      [key]: { left: 1, right: 2 },
    });
    assert.deepEqual(target.values, [1]);
  });
}
