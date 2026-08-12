<script setup lang="ts">
const localePath = useLocalePath();
const { isAuthenticated, logout, status, user } = useAuthSession();
const logoutError = shallowRef(false);
const logoutPending = shallowRef(false);

async function handleSignOut(): Promise<void> {
  logoutError.value = false;
  logoutPending.value = true;
  try {
    await logout();
    await navigateTo(localePath("index"));
  } catch {
    logoutError.value = true;
  } finally {
    logoutPending.value = false;
  }
}
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
        <NuxtLink
          :to="localePath('community')"
          class="text-brand-700 hover:text-brand-900 hidden rounded-sm px-2 py-1 text-sm font-medium sm:inline-block"
        >
          {{ $t("navigation.community") }}
        </NuxtLink>
        <NuxtLink
          :to="localePath('articles')"
          class="text-brand-700 hover:text-brand-900 hidden rounded-sm px-2 py-1 text-sm font-medium sm:inline-block"
        >
          {{ $t("navigation.articles") }}
        </NuxtLink>
        <LocaleSwitcher />
        <UiLoadingSkeleton
          v-if="status === 'loading'"
          class="w-20"
          :label="$t('auth.session.loading')"
          :rows="1"
        />
        <AuthUserMenu
          v-else-if="isAuthenticated && user"
          :pending="logoutPending"
          :user="user"
          @sign-out="handleSignOut"
        />
        <NuxtLink
          v-else
          :to="localePath('login')"
          class="bg-brand-900 hover:bg-brand-700 rounded-lg px-3 py-2 text-sm font-semibold text-white transition-colors"
        >
          {{ $t("auth.login.navigation") }}
        </NuxtLink>
      </nav>
      <p v-if="logoutError" class="sr-only" role="alert">
        {{ $t("auth.logout.unavailable") }}
      </p>
    </div>
  </header>
</template>
