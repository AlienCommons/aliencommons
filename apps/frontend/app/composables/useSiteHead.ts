export function useSiteHead() {
  const localeHead = useLocaleHead({ seo: true });

  useHead(() => ({
    htmlAttrs: localeHead.value.htmlAttrs,
    link: [
      ...(localeHead.value.link ?? []),
      { href: "/favicon.svg", rel: "icon", type: "image/svg+xml" },
    ],
    meta: localeHead.value.meta,
    titleTemplate: (title) =>
      title && title !== "AlienCommons"
        ? `${title} · AlienCommons`
        : "AlienCommons",
  }));
}
