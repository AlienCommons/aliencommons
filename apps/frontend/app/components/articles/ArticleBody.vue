<script setup lang="ts">
defineProps<{
  html: string;
}>();
</script>

<template>
  <!-- The API sanitizes published HTML with an explicit allowlist. -->
  <div class="article-body" v-html="html" />
</template>

<style scoped>
.article-body {
  color: var(--color-brand-900);
  font-size: 1.0625rem;
  line-height: 1.85;
  overflow-wrap: anywhere;
}

.article-body :deep(h1),
.article-body :deep(h2),
.article-body :deep(h3),
.article-body :deep(h4) {
  margin-top: 2em;
  margin-bottom: 0.75em;
  font-weight: 650;
  line-height: 1.25;
  letter-spacing: -0.02em;
}

.article-body :deep(h1) {
  font-size: 2rem;
}

.article-body :deep(h2) {
  font-size: 1.6rem;
}

.article-body :deep(h3) {
  font-size: 1.3rem;
}

.article-body :deep(p),
.article-body :deep(blockquote),
.article-body :deep(pre),
.article-body :deep(ul),
.article-body :deep(ol) {
  margin-block: 1.25rem;
}

.article-body :deep(ul),
.article-body :deep(ol) {
  padding-left: 1.5rem;
}

.article-body :deep(ul) {
  list-style: disc;
}

.article-body :deep(ol) {
  list-style: decimal;
}

.article-body :deep(blockquote) {
  border-left: 4px solid var(--color-brand-200);
  color: var(--color-brand-700);
  padding-left: 1rem;
}

.article-body :deep(a) {
  color: var(--color-accent-600);
  text-decoration: underline;
  text-underline-offset: 0.2em;
}

.article-body :deep(code) {
  border-radius: 0.35rem;
  background: var(--color-brand-100);
  padding: 0.15em 0.35em;
  font-size: 0.9em;
}

.article-body :deep(pre) {
  overflow-x: auto;
  border-radius: 0.75rem;
  background: var(--color-brand-900);
  padding: 1rem;
  color: white;
}

.article-body :deep(pre code) {
  background: transparent;
  padding: 0;
}

.article-body :deep(img) {
  max-width: 100%;
  height: auto;
  border-radius: 0.75rem;
}
</style>
