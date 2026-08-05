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
  icon: {
    clientBundle: {
      scan: true,
    },
    fallbackToApi: false,
  },
  modules: ["@pinia/nuxt", "@nuxt/icon"],
  runtimeConfig: {
    apiInternalBase: "",
    public: {
      apiBase: "/api",
    },
  },
  vite: {
    plugins: [tailwindcss()],
  },
});
