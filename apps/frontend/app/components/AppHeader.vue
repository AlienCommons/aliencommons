<script setup lang="ts">
const localePath = useLocalePath();
</script>

<template>
  <header class="border-brand-200/80 border-b bg-white/75 backdrop-blur">
    <div
      class="mx-auto flex min-h-16 w-full max-w-6xl items-center justify-between gap-6 px-5 py-3 sm:px-8"
    >
      <NuxtLink
        :to="localePath('index')"
        class="flex items-center gap-3 rounded-sm font-semibold tracking-tight"
      >
        <img
          alt=""
          class="size-9 [image-rendering:pixelated]"
          height="36"
          src="/logo-mark.svg"
          width="36"
        />
        <span>AlienCommons</span>
      </NuxtLink>

      <nav
        :aria-label="$t('navigation.primary')"
        class="flex items-center gap-3"
      >
        <NuxtLink
          :to="localePath('index')"
          class="text-brand-700 hover:text-brand-900 hidden rounded-sm px-2 py-1 text-sm font-medium sm:inline-block"
        >
          {{ $t("navigation.home") }}
        </NuxtLink>
        <LocaleSwitcher />
      </nav>
    </div>
  </header>
</template>
