<script setup>
/* ============================================================
   通用输入字段
   负责：聚焦高亮、错误态、密码显隐
   图标用具名插槽传入，额外内容（如加密等级条）用默认插槽
   ============================================================ */
import { computed, ref } from 'vue'

const props = defineProps({
  modelValue: { type: String, default: '' },
  label: { type: String, default: '' },
  /** text | email | password */
  type: { type: String, default: 'text' },
  placeholder: { type: String, default: '' },
  autocomplete: { type: String, default: 'off' },
  maxlength: { type: [String, Number], default: undefined },
  /** 是否渲染密码显隐按钮 */
  password: { type: Boolean, default: false },
  /** 错误态 */
  bad: { type: Boolean, default: false },
  errorText: { type: String, default: '' }
})

defineEmits(['update:modelValue'])

const EYE_ON =
  '<svg width="17" height="17" viewBox="0 0 24 24" fill="none"><path d="M2.5 12S6 5.5 12 5.5 21.5 12 21.5 12 18 18.5 12 18.5 2.5 12 2.5 12Z" stroke="currentColor" stroke-width="1.7"/><circle cx="12" cy="12" r="3" stroke="currentColor" stroke-width="1.7"/></svg>'
const EYE_OFF =
  '<svg width="17" height="17" viewBox="0 0 24 24" fill="none"><path d="M4 4l16 16" stroke="currentColor" stroke-width="1.7" stroke-linecap="round"/><path d="M6.4 7.4A17 17 0 0 0 2.5 12S6 18.5 12 18.5c1.1 0 2.1-.2 3-.6M9.9 5.8A9.6 9.6 0 0 1 12 5.5c6 0 9.5 6.5 9.5 6.5a17 17 0 0 1-3.1 3.8" stroke="currentColor" stroke-width="1.7" stroke-linecap="round"/></svg>'

const inputEl = ref(null)
const focused = ref(false)
const revealed = ref(false)

const inputType = computed(() => {
  if (!props.password) return props.type
  return revealed.value ? 'text' : 'password'
})

const eyeIcon = computed(() => (revealed.value ? EYE_OFF : EYE_ON))

function onLeave() {
  if (document.activeElement !== inputEl.value) focused.value = false
}
</script>

<template>
  <div class="field" :class="{ focus: focused, bad }">
    <label v-if="label">{{ label }}</label>
    <div class="fin">
      <slot name="icon" />
      <input
        ref="inputEl"
        :type="inputType"
        :value="modelValue"
        :placeholder="placeholder"
        :autocomplete="autocomplete"
        :maxlength="maxlength"
        @input="$emit('update:modelValue', $event.target.value)"
        @focus="focused = true"
        @blur="focused = false"
        @mouseenter="focused = true"
        @mouseleave="onLeave"
      />
      <button
        v-if="password"
        class="eye"
        type="button"
        aria-label="显示密码"
        v-html="eyeIcon"
        @click.stop="revealed = !revealed"
      ></button>
    </div>
    <span class="emsg">{{ errorText }}</span>
    <slot />
  </div>
</template>
