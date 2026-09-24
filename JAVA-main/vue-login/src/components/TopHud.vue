<script setup>
import { state } from '../store/session'
import { toggleSound } from '../composables/useSound'
</script>

<template>
  <header class="hud-top">
    <div class="brand"><span class="slash"></span>AGENT <b>ACCESS</b></div>
    <span class="sp"></span>
    <button
      class="icon-btn"
      :class="{ muted: !state.soundOn }"
      title="音效"
      aria-label="音效开关"
      @click.stop="toggleSound"
    >
      <svg width="19" height="19" viewBox="0 0 24 24" fill="none">
        <path d="M4 9v6h4l5 4V5L8 9H4Z" stroke="currentColor" stroke-width="1.7" stroke-linejoin="round" />
        <path
          d="M16.5 8.5a5 5 0 0 1 0 7"
          stroke="currentColor"
          stroke-width="1.7"
          stroke-linecap="round"
          :opacity="state.soundOn ? '1' : '.25'"
        />
      </svg>
    </button>
  </header>
</template>

<style scoped>
.hud-top {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  z-index: 30;
  display: flex;
  align-items: center;
  gap: 14px;
  padding: 16px 26px;
  pointer-events: none;
}
.hud-top > * { pointer-events: auto; }

.brand {
  display: flex;
  align-items: center;
  gap: 11px;
  font-family: var(--disp);
  font-weight: 700;
  letter-spacing: 3px;
  font-size: 20px;
  text-transform: uppercase;
}
.brand .slash {
  width: 22px;
  height: 22px;
  background: var(--red);
  transform: skewX(-14deg);
  box-shadow: 0 0 18px -2px var(--red);
}
.brand b { color: var(--red); }

.hud-top .sp { flex: 1; }

.icon-btn {
  width: 42px;
  height: 42px;
  display: grid;
  place-items: center;
  background: rgba(17, 26, 36, .7);
  border: 1px solid var(--line);
  color: var(--cream);
  cursor: pointer;
  backdrop-filter: blur(6px);
  clip-path: polygon(8px 0, 100% 0, 100% calc(100% - 8px), calc(100% - 8px) 100%, 0 100%, 0 8px);
  transition: .2s;
}
.icon-btn:hover {
  border-color: var(--red);
  color: var(--red);
  box-shadow: 0 0 18px -6px var(--red);
}
.icon-btn.muted { color: var(--muted); }

@media (max-width: 640px) {
  .hud-top { padding: 12px 16px; }
  .brand { font-size: 16px; letter-spacing: 2px; }
}
</style>
