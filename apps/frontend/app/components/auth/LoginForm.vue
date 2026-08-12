<script setup lang="ts">
import { ApiResponseError } from "~/api/errors";

const emit = defineEmits<{
  signedIn: [];
}>();

const { login } = useAuthSession();
const form = reactive({
  email: "",
  password: "",
});
const errorKey = shallowRef<string>();
const pending = shallowRef(false);

async function submit(): Promise<void> {
  errorKey.value = undefined;
  pending.value = true;

  try {
    await login(form);
    emit("signedIn");
  } catch (error) {
    errorKey.value =
      error instanceof ApiResponseError &&
      [400, 401, 403].includes(error.status)
        ? "auth.login.invalidCredentials"
        : "auth.login.unavailable";
  } finally {
    pending.value = false;
  }
}
</script>

<template>
  <form class="space-y-5" @submit.prevent="submit">
    <div>
      <label
        class="text-brand-900 mb-2 block text-sm font-semibold"
        for="email"
      >
        {{ $t("auth.login.email") }}
      </label>
      <input
        id="email"
        v-model.trim="form.email"
        autocomplete="email"
        class="border-brand-200 text-brand-900 placeholder:text-brand-500 focus:border-accent-600 w-full rounded-xl border bg-white px-4 py-3 shadow-sm transition-colors"
        inputmode="email"
        name="email"
        required
        type="email"
      />
    </div>

    <div>
      <label
        class="text-brand-900 mb-2 block text-sm font-semibold"
        for="password"
      >
        {{ $t("auth.login.password") }}
      </label>
      <input
        id="password"
        v-model="form.password"
        autocomplete="current-password"
        class="border-brand-200 text-brand-900 placeholder:text-brand-500 focus:border-accent-600 w-full rounded-xl border bg-white px-4 py-3 shadow-sm transition-colors"
        name="password"
        required
        type="password"
      />
    </div>

    <p
      v-if="errorKey"
      class="rounded-xl border border-red-200 bg-red-50 px-4 py-3 text-sm text-red-800"
      role="alert"
    >
      {{ $t(errorKey) }}
    </p>

    <button
      :disabled="pending"
      class="bg-brand-900 hover:bg-brand-700 w-full rounded-xl px-4 py-3 font-semibold text-white shadow-sm transition-colors disabled:cursor-wait disabled:opacity-60"
      type="submit"
    >
      {{ pending ? $t("auth.login.submitting") : $t("auth.login.submit") }}
    </button>
  </form>
</template>
