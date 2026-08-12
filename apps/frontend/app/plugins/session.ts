export default defineNuxtPlugin(async () => {
  const { initialize } = useAuthSession();
  await initialize();
});
