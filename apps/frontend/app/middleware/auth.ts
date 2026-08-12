export default defineNuxtRouteMiddleware((to) => {
  const store = useAuthStore();
  if (store.status !== "anonymous") {
    return;
  }

  const localePath = useLocalePath();
  return navigateTo(
    localePath({
      name: "login",
      query: { redirect: to.fullPath },
    })
  );
});
