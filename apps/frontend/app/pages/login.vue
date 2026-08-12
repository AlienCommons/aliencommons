<script setup lang="ts">
definePageMeta({ middleware: "guest" });

const route = useRoute();
const localePath = useLocalePath();
const { t } = useI18n();

const redirectPath = computed(() =>
  resolveSafeRedirect(route.query.redirect, localePath("index"))
);

async function handleSignedIn(): Promise<void> {
  await navigateTo(redirectPath.value);
}

useSeoMeta({
  description: () => t("auth.login.description"),
  title: () => t("auth.login.metaTitle"),
});
</script>

<template>
  <section
    class="mx-auto flex w-full max-w-md flex-1 items-center px-5 py-16 sm:px-8"
  >
    <div class="w-full">
      <p
        class="text-accent-600 mb-3 text-sm font-bold tracking-widest uppercase"
      >
        {{ $t("auth.login.eyebrow") }}
      </p>
      <h1 class="text-brand-900 text-4xl font-semibold tracking-tight">
        {{ $t("auth.login.title") }}
      </h1>
      <p class="text-brand-700 mt-3 leading-7">
        {{ $t("auth.login.description") }}
      </p>

      <div
        class="border-brand-200 bg-brand-100/55 mt-8 rounded-2xl border p-5 sm:p-6"
      >
        <AuthLoginForm @signed-in="handleSignedIn" />
      </div>
    </div>
  </section>
</template>
