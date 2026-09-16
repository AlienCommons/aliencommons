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
const hydrated = shallowRef(false);

onMounted(() => {
  hydrated.value = true;
});

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
  <form class="space-y-5" method="post" @submit.prevent="submit">
    <UiFormField id="email" :label="$t('auth.login.email')" required>
      <template #default="{ describedBy, id, invalid }">
        <UiBaseInput
          :id="id"
          v-model="form.email"
          :disabled="!hydrated || pending"
          :aria-describedby="describedBy"
          autocomplete="email"
          inputmode="email"
          :invalid="invalid"
          name="email"
          required
          type="email"
        />
      </template>
    </UiFormField>

    <UiFormField id="password" :label="$t('auth.login.password')" required>
      <template #default="{ describedBy, id, invalid }">
        <UiBaseInput
          :id="id"
          v-model="form.password"
          :disabled="!hydrated || pending"
          :aria-describedby="describedBy"
          autocomplete="current-password"
          :invalid="invalid"
          name="password"
          required
          type="password"
        />
      </template>
    </UiFormField>

    <UiFormError v-if="errorKey" :message="$t(errorKey)" />

    <UiBaseButton block :disabled="!hydrated" :loading="pending" type="submit">
      {{ pending ? $t("auth.login.submitting") : $t("auth.login.submit") }}
    </UiBaseButton>
  </form>
</template>
