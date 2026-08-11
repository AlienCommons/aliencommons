<template>
  <div class="flex min-h-dvh flex-col">
    <a
      class="bg-brand-900 fixed top-3 left-3 z-50 -translate-y-24 rounded-md px-4 py-2 text-sm font-semibold text-white transition-transform focus:translate-y-0"
      href="#main-content"
    >
      {{ $t("accessibility.skipToContent") }}
    </a>

    <AppHeader />
    <main id="main-content" class="flex flex-1 flex-col" tabindex="-1">
      <slot />
    </main>
    <AppFooter />
  </div>
</template>
