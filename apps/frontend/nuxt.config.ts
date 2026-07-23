import tailwindcss from "@tailwindcss/vite";

export default defineNuxtConfig({
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
  vite: {
    plugins: [tailwindcss()],
  },
});
