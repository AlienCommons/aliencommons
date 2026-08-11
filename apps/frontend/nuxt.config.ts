import tailwindcss from "@tailwindcss/vite";

const apiInternalBase = process.env.NUXT_API_INTERNAL_BASE?.trim();

export default defineNuxtConfig({
  $development: {
    nitro: {
      devProxy: apiInternalBase
        ? {
            "/api": {
              changeOrigin: true,
              target: apiInternalBase,
            },
          }
        : {},
    },
  },
  compatibilityDate: "2025-07-15",
  css: ["~/assets/css/main.css"],
  devtools: { enabled: true },
  i18n: {
    defaultLocale: "en",
    detectBrowserLanguage: {
      cookieKey: "aliencommons_locale",
      fallbackLocale: "en",
      redirectOn: "root",
      useCookie: true,
    },
    locales: [
      {
        code: "en",
        file: "en.json",
        language: "en-US",
        name: "English",
      },
      {
        code: "zh",
        file: "zh.json",
        language: "zh-Hans",
        name: "简体中文",
      },
    ],
    strategy: "prefix_except_default",
  },
  icon: {
    clientBundle: {
      scan: true,
    },
    fallbackToApi: false,
  },
  modules: ["@pinia/nuxt", "@nuxt/icon", "@nuxtjs/i18n"],
  runtimeConfig: {
    apiInternalBase: "",
    public: {
      apiBase: "/api",
      i18n: {
        baseUrl: "",
      },
    },
  },
  vite: {
    plugins: [tailwindcss()],
  },
});
