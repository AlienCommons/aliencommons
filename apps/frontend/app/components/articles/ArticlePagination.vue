<script setup lang="ts">
const props = defineProps<{
  currentPage: number;
  totalPages: number;
}>();

const localePath = useLocalePath();

function pagePath(page: number) {
  return localePath({
    name: "articles",
    query: page === 1 ? {} : { page: String(page) },
  });
}

const previousPath = computed(() => pagePath(props.currentPage - 1));
const nextPath = computed(() => pagePath(props.currentPage + 1));
</script>

<template>
  <nav
    :aria-label="$t('articles.pagination.label')"
    class="mt-8 flex items-center justify-between gap-4"
  >
    <NuxtLink
      v-if="currentPage > 1"
      class="border-brand-200 bg-white text-brand-900 hover:bg-brand-100 rounded-xl border px-4 py-2 text-sm font-semibold"
      :to="previousPath"
    >
      {{ $t("articles.pagination.previous") }}
    </NuxtLink>
    <span v-else aria-hidden="true" />

    <span class="text-brand-700 text-sm">
      {{
        $t("articles.pagination.status", {
          current: currentPage,
          total: totalPages,
        })
      }}
    </span>

    <NuxtLink
      v-if="currentPage < totalPages"
      class="border-brand-200 bg-white text-brand-900 hover:bg-brand-100 rounded-xl border px-4 py-2 text-sm font-semibold"
      :to="nextPath"
    >
      {{ $t("articles.pagination.next") }}
    </NuxtLink>
    <span v-else aria-hidden="true" />
  </nav>
</template>
