<script setup>
import { state } from '../store/session'
</script>

<template>
  <div class="toast" :class="{ on: state.toast.visible, ok: state.toast.ok }">
    {{ state.toast.text }}
  </div>
</template>

<style scoped>
.toast {
  position: fixed;
  top: 84px;
  right: 26px;
  z-index: 70;
  display: flex;
  align-items: center;
  gap: 11px;
  padding: 14px 18px;
  font-family: var(--mono);
  font-size: 12.5px;
  letter-spacing: 1px;
  background: rgba(9, 14, 20, .95);
  border-left: 3px solid var(--red);
  color: var(--cream);
  box-shadow: 0 20px 50px -24px #000;
  transform: translateX(140%);
  transition: transform .45s cubic-bezier(.2, 1, .3, 1);
  max-width: 88vw;
}
.toast.on { transform: translateX(0); }
.toast.ok { border-left-color: #3ddc97; }
</style>
