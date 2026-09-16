import { expect, test } from "@playwright/test";

test("server-rendered login cannot submit credentials before hydration", async ({
  browser,
  baseURL,
}) => {
  const context = await browser.newContext({ javaScriptEnabled: false });
  try {
    const page = await context.newPage();
    await page.goto(`${baseURL}/login`);
    await expect(page.getByLabel("Email")).toBeDisabled();
    await expect(page.getByLabel("Password")).toBeDisabled();
    await expect(
      page.getByRole("button", { name: "Sign in", exact: true })
    ).toBeDisabled();
    await expect(page.locator("form")).toHaveAttribute("method", "post");
  } finally {
    await context.close();
  }
});

test("login rejects bad credentials, persists through SSR, and logs out", async ({
  page,
}) => {
  await page.goto("/login");
  await page.getByLabel("Email").fill("reader@demo.invalid");
  await page.getByLabel("Password").fill("wrong-password");
  await page.getByRole("button", { name: "Sign in", exact: true }).click();
  await expect(page.getByRole("alert")).toHaveText(
    "The email or password is incorrect."
  );

  await page.getByLabel("Password").fill("local-demo-only");
  await page.getByRole("button", { name: "Sign in", exact: true }).click();
  await expect(
    page.getByRole("button", { name: "Sign out", exact: true })
  ).toBeVisible();
  await page.reload();
  await expect(page.getByText("demo-reader", { exact: true })).toBeVisible();
  await expect(
    page.getByText("Demo community post about redstone.", { exact: true })
  ).toBeVisible();
  await expect(
    page.getByRole("button", { name: "Sign out", exact: true })
  ).toBeVisible();

  // A fresh HTTP request must render the session on the server, before hydration.
  const rendered = await page.request.get("/");
  expect(await rendered.text()).toContain("demo-reader");
  await page.getByRole("button", { name: "Sign out", exact: true }).click();
  await expect(
    page.getByRole("link", { name: "Sign in", exact: true })
  ).toBeVisible();
  await page.reload();
  await expect(
    page.getByRole("link", { name: "Sign in", exact: true })
  ).toBeVisible();
});

test("public articles render on the server and navigate to a readable detail", async ({
  page,
  request,
}) => {
  const response = await request.get("/articles");
  expect(response.status()).toBe(200);
  expect(await response.text()).toContain("Demo published article");

  await page.goto("/articles");
  await expect(
    page.getByRole("heading", { name: "Published articles", exact: true })
  ).toBeVisible();
  await page
    .getByRole("link", { name: "Read Demo published article", exact: true })
    .click();
  await expect(
    page.getByRole("heading", { name: "Demo published article", exact: true })
  ).toBeVisible();
  await expect(
    page.getByText("A repeatable Technical Minecraft example.", { exact: true })
  ).toBeVisible();
});

test("language switching keeps the current page across reloads", async ({
  page,
}) => {
  await page.goto("/articles");
  await page
    .getByRole("link", { name: "Switch to Simplified Chinese" })
    .click();
  await expect(page).toHaveURL(/\/zh\/articles$/);
  await expect(page.locator("html")).toHaveAttribute("lang", "zh-Hans");
  await page.reload();
  await expect(page).toHaveURL(/\/zh\/articles$/);
  await page.getByRole("link", { name: "切换到英文" }).click();
  await expect(page).toHaveURL(/\/articles$/);
});

test("community content is readable and missing publications return a real 404", async ({
  page,
}) => {
  await page.goto("/community");
  await expect(
    page.getByText("Demo community post about redstone.", { exact: true })
  ).toBeVisible();
  await page
    .getByRole("link", { name: "Read post by demo-author", exact: true })
    .click();
  await expect(
    page.getByText("Demo community post about redstone.", { exact: true })
  ).toBeVisible();

  const response = await page.goto(
    "/articles/00000000-0000-4000-8000-000000000000"
  );
  expect(response?.status()).toBe(404);
  await expect(
    page.getByRole("heading", { name: "Page not found", exact: true })
  ).toBeVisible();
  await page.getByRole("button", { name: "Return home", exact: true }).click();
  await expect(page).toHaveURL("http://127.0.0.1:43100/");
});
