# UI foundations

These components are the smallest shared presentation layer for the Nuxt app.
They contain visual and accessibility behavior, but no product or API logic.

Nuxt auto-imports this directory with the `Ui` prefix:

| Component | Responsibility |
| --- | --- |
| `UiBaseButton` | Button variants, sizes, disabled and loading states |
| `UiBaseInput` | Native input styling, `v-model`, invalid and disabled states |
| `UiFormField` | Label, description, error and `aria-describedby` wiring |
| `UiFormError` | Form-level alert message |
| `UiUserAvatar` | Avatar image, initials fallback and size variants |
| `UiLoadingSkeleton` | Content-shaped loading placeholder |
| `UiEmptyState` | Empty result title, description, icon and action slots |

Use translated strings at the call site. Shared UI components must not own
feature-specific i18n keys.

```vue
<UiFormField id="email" :label="$t('auth.login.email')" required>
  <template #default="{ describedBy, id, invalid }">
    <UiBaseInput
      :id="id"
      v-model="email"
      :aria-describedby="describedBy"
      :invalid="invalid"
      type="email"
    />
  </template>
</UiFormField>
```

Prefer these components when their existing contract fits. Extend a contract
only when at least one real feature needs the new behavior; do not add product
state, API requests, or feature-specific layout to this directory.
