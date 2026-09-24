<script setup>
/* ============================================================
   特工选择条：6 张卡片，点击切换当前特工
   ============================================================ */
import { AGENTS, roleShort } from '../data/agents'
import { state, selectAgent } from '../store/session'
import { beep } from '../composables/useSound'

function onSelect(i) {
  // 点击已选中的特工只给一声反馈，不重播动画
  if (i === state.agentIndex) {
    beep(520, 0.06)
    return
  }
  selectAgent(i)
  beep(760, 0.07)
}
</script>

<template>
  <div class="strip">
    <div
      v-for="(a, i) in AGENTS"
      :key="a.id"
      class="card"
      :class="{ sel: i === state.agentIndex }"
      :style="{ '--ac': a.color }"
      @click="onSelect(i)"
    >
      <div class="cp"></div>
      <span class="cr">{{ roleShort(a.role) }}</span>
      <span class="cm">{{ a.mono }}</span>
      <span class="cn">{{ a.name }}</span>
    </div>
  </div>
</template>

<style scoped>
.strip {
  display: grid;
  grid-template-columns: repeat(6, 1fr);
  gap: 10px;
  max-width: 1240px;
  width: 100%;
  margin: 26px auto 4px;
}

.card {
  position: relative;
  cursor: pointer;
  overflow: hidden;
  aspect-ratio: 3/4;
  min-height: 110px;
  border: 1px solid var(--line);
  background: linear-gradient(160deg, #0e1721, #0a1119);
  clip-path: polygon(0 0, 100% 0, 100% calc(100% - 16px), calc(100% - 16px) 100%, 0 100%);
  transition: transform .25s, border-color .25s;
  transform: translateY(0);
}
.card .cp {
  position: absolute;
  inset: 0;
  opacity: .85;
  transition: .35s;
  background:
    repeating-linear-gradient(58deg, color-mix(in srgb, var(--ac) 34%, transparent) 0 2px, transparent 2px 18px),
    radial-gradient(80% 80% at 70% 25%, color-mix(in srgb, var(--ac) 42%, transparent), transparent 72%),
    linear-gradient(160deg, #0b131c, #090f16);
}
.card .cm {
  position: absolute;
  right: -6px;
  bottom: -26px;
  font-family: var(--disp);
  font-weight: 700;
  font-size: 96px;
  color: transparent;
  -webkit-text-stroke: 1.5px color-mix(in srgb, var(--ac) 70%, #fff 10%);
  opacity: .7;
  transition: .35s;
}
.card .cn {
  position: absolute;
  left: 9px;
  bottom: 8px;
  font-family: var(--disp);
  font-weight: 700;
  font-size: 15px;
  letter-spacing: 1.5px;
  text-transform: uppercase;
}
.card .cr {
  position: absolute;
  left: 9px;
  top: 9px;
  font-family: var(--mono);
  font-size: 9px;
  letter-spacing: 1px;
  color: var(--ac);
}

.card:hover {
  transform: translateY(-7px);
  border-color: color-mix(in srgb, var(--ac) 70%, transparent);
}
.card:hover .cm { opacity: 1; transform: translateY(-6px); }

.card.sel {
  border-color: var(--ac);
  box-shadow: 0 0 26px -8px var(--ac);
}
.card.sel::after {
  content: "";
  position: absolute;
  left: 0;
  bottom: 0;
  width: 100%;
  height: 3px;
  background: var(--ac);
}

@media (max-width: 1020px) {
  .strip { grid-template-columns: repeat(3, 1fr); }
}
@media (max-width: 640px) {
  .strip { grid-template-columns: repeat(3, 1fr); gap: 8px; }
}
</style>
