export default defineNuxtRouteMiddleware(() => {
  const store = useAuthStore();
  if (!store.isAuthenticated) {
    return;
  }

  return navigateTo(useLocalePath()("index"));
});
