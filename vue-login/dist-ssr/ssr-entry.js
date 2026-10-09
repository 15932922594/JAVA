import { reactive, computed, onMounted, onBeforeUnmount, inject, ref, mergeProps, useSSRContext, unref, watch, withCtx, openBlock, createBlock, createVNode, toDisplayString, Fragment, renderList, provide, nextTick, createSSRApp } from "vue";
import { ssrRenderAttrs, ssrRenderList, ssrRenderStyle, ssrRenderClass, ssrRenderAttr, ssrInterpolate, ssrRenderSlot, ssrRenderComponent, ssrIncludeBooleanAttr, ssrLooseContain, renderToString } from "vue/server-renderer";
const STAT_LABELS = ["火力", "机动", "控制", "防御"];
const AGENTS = [
  {
    id: "vector",
    name: "VECTOR",
    mono: "V",
    role: "突击 · ASSAULT",
    color: "#FF4655",
    bio: "以极高机动性撕裂防线的突进型特工，擅长在瞬间改写交火态势。",
    stats: [92, 76, 44, 38]
  },
  {
    id: "arclight",
    name: "ARCLIGHT",
    mono: "A",
    role: "侦察 · RECON",
    color: "#00E0C6",
    bio: "用电弧脉冲扫描战场，为队伍点亮迷雾中的每一个目标。",
    stats: [58, 86, 72, 46]
  },
  {
    id: "phantom",
    name: "PHANTOM",
    mono: "P",
    role: "控场 · CONTROL",
    color: "#A66CFF",
    bio: "制造幻象与烟幕，掌控每一次交火的节奏与视野。",
    stats: [52, 74, 93, 50]
  },
  {
    id: "onyx",
    name: "ONYX",
    mono: "O",
    role: "守护 · SENTINEL",
    color: "#FFB443",
    bio: "以坚固壁垒庇护队友，是阵地攻防中不可撼动的支点。",
    stats: [46, 52, 64, 96]
  },
  {
    id: "tempest",
    name: "TEMPEST",
    mono: "T",
    role: "控场 · CONTROL",
    color: "#4DA6FF",
    bio: "召唤风暴封锁通路，让敌人在自己的领地寸步难行。",
    stats: [54, 70, 90, 62]
  },
  {
    id: "ember",
    name: "EMBER",
    mono: "E",
    role: "突击 · ASSAULT",
    color: "#FF6B4A",
    bio: "以烈焰灼烧前线的爆发型特工，高风险，也高回报。",
    stats: [90, 64, 52, 54]
  }
];
function roleShort(role) {
  return role.split(" · ")[1] ?? role;
}
const EMAIL = /^[^\s@]+@[^\s@]+\.[^\s@]{2,}$/;
const state = reactive({
  /** 当前选中的特工下标 */
  agentIndex: 0,
  /** 当前面板：login | register */
  mode: "login",
  /** 开机页是否已结束 */
  booted: false,
  /** 音效开关（默认静音，与原页面一致） */
  soundOn: false,
  /** Toast */
  toast: { visible: false, text: "", ok: false },
  /** 登录表单 */
  login: {
    id: "",
    pass: "",
    remember: false
  },
  /** 注册表单 */
  register: {
    name: "",
    email: "",
    pass: "",
    pass2: "",
    terms: false
  }
});
const currentAgent = computed(() => AGENTS[state.agentIndex]);
const accent = computed(() => currentAgent.value.color);
const progress = computed(() => {
  if (state.mode === "login") {
    const a = state.login.id.trim().length >= 3 ? 1 : 0;
    const b = state.login.pass.length >= 6 ? 1 : 0;
    return (a + b) / 2;
  }
  const n = state.register.name.trim().length >= 2 ? 1 : 0;
  const e = EMAIL.test(state.register.email.trim()) ? 1 : 0;
  const s = state.register.pass.length >= 6 ? 1 : 0;
  const c = state.register.pass2 !== "" && state.register.pass2 === state.register.pass ? 1 : 0;
  const t = state.register.terms ? 1 : 0;
  const g = 1;
  return (n + e + s + c + t + g) / 6;
});
const agentLevel = computed(
  () => String(1 + Math.floor(progress.value * 9) + state.agentIndex * 3).padStart(2, "0")
);
const SEC_COLORS = ["#FF4655", "#FFB443", "#3ddc97", "#00E0C6"];
const SEC_TEXTS = ["低", "中", "高", "极高"];
const securityLevel = computed(() => {
  const v = state.register.pass;
  if (!v.length) return 0;
  let s = 0;
  if (v.length >= 6) s++;
  if (v.length >= 10) s++;
  if (/[A-Z]/.test(v) && /[a-z]/.test(v)) s++;
  if (/\d/.test(v) || /[^A-Za-z0-9]/.test(v)) s++;
  return Math.min(4, Math.max(1, s));
});
function selectAgent(i) {
  state.agentIndex = i;
}
function switchMode(mode) {
  state.mode = mode;
}
let toastTimer = null;
function showToast(text, ok = false) {
  state.toast.text = text;
  state.toast.ok = !!ok;
  state.toast.visible = true;
  clearTimeout(toastTimer);
  toastTimer = setTimeout(() => {
    state.toast.visible = false;
  }, 3e3);
}
function resetRegister() {
  Object.assign(state.register, {
    name: "",
    email: "",
    pass: "",
    pass2: "",
    terms: false
  });
}
function useSession() {
  return {
    state,
    currentAgent,
    accent,
    progress,
    agentLevel,
    securityLevel,
    selectAgent,
    switchMode,
    showToast,
    resetRegister
  };
}
function useParallax() {
  function onMove(e) {
    const mx = ((e.clientX / window.innerWidth - 0.5) * 2).toFixed(3);
    const my = ((e.clientY / window.innerHeight - 0.5) * 2).toFixed(3);
    document.body.style.setProperty("--mx", mx);
    document.body.style.setProperty("--my", my);
  }
  onMounted(() => window.addEventListener("mousemove", onMove));
  onBeforeUnmount(() => window.removeEventListener("mousemove", onMove));
}
const FX_KEY = Symbol("app-fx");
function useEffects() {
  return inject(FX_KEY, { flash: () => {
  } });
}
const _export_sfc = (sfc, props) => {
  const target = sfc.__vccOpts || sfc;
  for (const [key, val] of props) {
    target[key] = val;
  }
  return target;
};
const _sfc_main$c = {
  __name: "FxBackground",
  __ssrInlineRender: true,
  setup(__props) {
    const canvasEl = ref(null);
    let raf = 0;
    let cleanupFns = [];
    onMounted(() => {
      const cv = canvasEl.value;
      const ctx = cv.getContext("2d");
      const dpr = Math.min(window.devicePixelRatio || 1, 2);
      let W = 0;
      let H = 0;
      let P = [];
      let mx = 0;
      let my = 0;
      let tx = 0;
      let ty = 0;
      function resize() {
        W = cv.width = innerWidth * dpr;
        H = cv.height = innerHeight * dpr;
        cv.style.width = innerWidth + "px";
        cv.style.height = innerHeight + "px";
      }
      function make() {
        P = [];
        const n = Math.round(innerWidth / 16);
        for (let i = 0; i < n; i++) {
          P.push({
            x: Math.random() * W,
            y: Math.random() * H,
            r: Math.random() * 1.8 + 0.4,
            vx: (Math.random() - 0.5) * 0.28,
            vy: (Math.random() - 0.5) * 0.28,
            a: Math.random() * 0.5 + 0.15
          });
        }
      }
      function onResize() {
        resize();
        make();
      }
      function onMove(e) {
        mx = (e.clientX / innerWidth - 0.5) * 2;
        my = (e.clientY / innerHeight - 0.5) * 2;
      }
      function loop() {
        tx += (mx - tx) * 0.05;
        ty += (my - ty) * 0.05;
        ctx.clearRect(0, 0, W, H);
        for (let i = 0; i < P.length; i++) {
          const p = P[i];
          p.x += p.vx * dpr;
          p.y += p.vy * dpr;
          if (p.x < 0) p.x = W;
          if (p.x > W) p.x = 0;
          if (p.y < 0) p.y = H;
          if (p.y > H) p.y = 0;
          ctx.beginPath();
          ctx.fillStyle = "rgba(236,232,225," + p.a + ")";
          ctx.arc(p.x + tx * 22 * dpr, p.y + ty * 22 * dpr, p.r * dpr, 0, 6.283);
          ctx.fill();
          for (let j = i + 1; j < P.length; j++) {
            const q = P[j];
            const dx = p.x - q.x;
            const dy = p.y - q.y;
            const d2 = dx * dx + dy * dy;
            if (d2 < 2e4 * dpr * dpr) {
              const o = (1 - d2 / (2e4 * dpr * dpr)) * 0.14;
              ctx.strokeStyle = "rgba(255,70,85," + o + ")";
              ctx.lineWidth = 1;
              ctx.beginPath();
              ctx.moveTo(p.x + tx * 22 * dpr, p.y + ty * 22 * dpr);
              ctx.lineTo(q.x + tx * 22 * dpr, q.y + ty * 22 * dpr);
              ctx.stroke();
            }
          }
        }
        raf = requestAnimationFrame(loop);
      }
      resize();
      make();
      window.addEventListener("resize", onResize);
      window.addEventListener("mousemove", onMove);
      loop();
      cleanupFns = [
        () => window.removeEventListener("resize", onResize),
        () => window.removeEventListener("mousemove", onMove),
        () => cancelAnimationFrame(raf)
      ];
    });
    onBeforeUnmount(() => cleanupFns.forEach((fn) => fn()));
    return (_ctx, _push, _parent, _attrs) => {
      _push(`<div${ssrRenderAttrs(mergeProps({ class: "fx" }, _attrs))} data-v-3f3f59d4><canvas id="fx" data-v-3f3f59d4></canvas><div class="grad" data-v-3f3f59d4></div><div class="diag" data-v-3f3f59d4></div><div class="grid" data-v-3f3f59d4></div><div class="sweep" data-v-3f3f59d4></div><span class="corner-mark cm1" data-v-3f3f59d4></span><span class="corner-mark cm2" data-v-3f3f59d4></span></div>`);
    };
  }
};
const _sfc_setup$c = _sfc_main$c.setup;
_sfc_main$c.setup = (props, ctx) => {
  const ssrContext = useSSRContext();
  (ssrContext.modules || (ssrContext.modules = /* @__PURE__ */ new Set())).add("src/components/FxBackground.vue");
  return _sfc_setup$c ? _sfc_setup$c(props, ctx) : void 0;
};
const FxBackground = /* @__PURE__ */ _export_sfc(_sfc_main$c, [["__scopeId", "data-v-3f3f59d4"]]);
const HOT_SELECTOR = "button,a,input,.card,.chk,.tab,.soc,.btn";
const _sfc_main$b = {
  __name: "Crosshair",
  __ssrInlineRender: true,
  setup(__props) {
    const el = ref(null);
    const hot = ref(false);
    let rx = 0;
    let ry = 0;
    let tx = 0;
    let ty = 0;
    let rot = 0;
    let raf = 0;
    function onMove(e) {
      rx = e.clientX;
      ry = e.clientY;
    }
    function onOver(e) {
      if (e.target.closest && e.target.closest(HOT_SELECTOR)) hot.value = true;
    }
    function onOut(e) {
      if (e.target.closest && e.target.closest(HOT_SELECTOR)) hot.value = false;
    }
    function loop() {
      tx += (rx - tx) * 0.2;
      ty += (ry - ty) * 0.2;
      const target = hot.value ? 45 : 0;
      rot += (target - rot) * 0.15;
      const node = el.value;
      if (node) {
        node.style.transform = `translate(${tx}px,${ty}px) rotate(${rot.toFixed(2)}deg)`;
      }
      raf = requestAnimationFrame(loop);
    }
    onMounted(() => {
      rx = tx = window.innerWidth / 2;
      ry = ty = window.innerHeight / 2;
      window.addEventListener("mousemove", onMove);
      document.addEventListener("mouseover", onOver);
      document.addEventListener("mouseout", onOut);
      raf = requestAnimationFrame(loop);
    });
    onBeforeUnmount(() => {
      window.removeEventListener("mousemove", onMove);
      document.removeEventListener("mouseover", onOver);
      document.removeEventListener("mouseout", onOut);
      cancelAnimationFrame(raf);
    });
    return (_ctx, _push, _parent, _attrs) => {
      _push(`<div${ssrRenderAttrs(mergeProps({
        ref_key: "el",
        ref: el,
        class: ["reticle", { hot: hot.value }]
      }, _attrs))} data-v-e25acc13><span class="r t" data-v-e25acc13></span><span class="r b" data-v-e25acc13></span><span class="r l" data-v-e25acc13></span><span class="r rr" data-v-e25acc13></span><span class="r dot" data-v-e25acc13></span></div>`);
    };
  }
};
const _sfc_setup$b = _sfc_main$b.setup;
_sfc_main$b.setup = (props, ctx) => {
  const ssrContext = useSSRContext();
  (ssrContext.modules || (ssrContext.modules = /* @__PURE__ */ new Set())).add("src/components/Crosshair.vue");
  return _sfc_setup$b ? _sfc_setup$b(props, ctx) : void 0;
};
const Crosshair = /* @__PURE__ */ _export_sfc(_sfc_main$b, [["__scopeId", "data-v-e25acc13"]]);
let actx = null;
function beep(freq, dur, type = "triangle") {
  if (!state.soundOn) return;
  try {
    if (!actx) actx = new (window.AudioContext || window.webkitAudioContext)();
    const osc = actx.createOscillator();
    const gain = actx.createGain();
    osc.type = type;
    osc.frequency.value = freq;
    gain.gain.setValueAtTime(0.06, actx.currentTime);
    gain.gain.exponentialRampToValueAtTime(1e-4, actx.currentTime + dur);
    osc.connect(gain);
    gain.connect(actx.destination);
    osc.start();
    osc.stop(actx.currentTime + dur);
  } catch {
  }
}
computed(() => state.soundOn);
const _sfc_main$a = {
  __name: "ClickEffects",
  __ssrInlineRender: true,
  setup(__props) {
    const rings = ref([]);
    let uid = 0;
    function onClick(e) {
      const id = ++uid;
      rings.value.push({ id, x: e.clientX, y: e.clientY });
      beep(420, 0.05, "sine");
      setTimeout(() => {
        rings.value = rings.value.filter((r) => r.id !== id);
      }, 720);
    }
    onMounted(() => document.addEventListener("click", onClick));
    onBeforeUnmount(() => document.removeEventListener("click", onClick));
    return (_ctx, _push, _parent, _attrs) => {
      _push(`<!--[-->`);
      ssrRenderList(rings.value, (r) => {
        _push(`<span class="ring go" style="${ssrRenderStyle({ left: r.x + "px", top: r.y + "px" })}" data-v-4d5922a3></span>`);
      });
      _push(`<!--]-->`);
    };
  }
};
const _sfc_setup$a = _sfc_main$a.setup;
_sfc_main$a.setup = (props, ctx) => {
  const ssrContext = useSSRContext();
  (ssrContext.modules || (ssrContext.modules = /* @__PURE__ */ new Set())).add("src/components/ClickEffects.vue");
  return _sfc_setup$a ? _sfc_setup$a(props, ctx) : void 0;
};
const ClickEffects = /* @__PURE__ */ _export_sfc(_sfc_main$a, [["__scopeId", "data-v-4d5922a3"]]);
const _sfc_main$9 = {
  __name: "TopHud",
  __ssrInlineRender: true,
  setup(__props) {
    return (_ctx, _push, _parent, _attrs) => {
      _push(`<header${ssrRenderAttrs(mergeProps({ class: "hud-top" }, _attrs))} data-v-a346a00f><div class="brand" data-v-a346a00f><span class="slash" data-v-a346a00f></span>AGENT <b data-v-a346a00f>ACCESS</b></div><span class="sp" data-v-a346a00f></span><button class="${ssrRenderClass([{ muted: !unref(state).soundOn }, "icon-btn"])}" title="音效" aria-label="音效开关" data-v-a346a00f><svg width="19" height="19" viewBox="0 0 24 24" fill="none" data-v-a346a00f><path d="M4 9v6h4l5 4V5L8 9H4Z" stroke="currentColor" stroke-width="1.7" stroke-linejoin="round" data-v-a346a00f></path><path d="M16.5 8.5a5 5 0 0 1 0 7" stroke="currentColor" stroke-width="1.7" stroke-linecap="round"${ssrRenderAttr("opacity", unref(state).soundOn ? "1" : ".25")} data-v-a346a00f></path></svg></button></header>`);
    };
  }
};
const _sfc_setup$9 = _sfc_main$9.setup;
_sfc_main$9.setup = (props, ctx) => {
  const ssrContext = useSSRContext();
  (ssrContext.modules || (ssrContext.modules = /* @__PURE__ */ new Set())).add("src/components/TopHud.vue");
  return _sfc_setup$9 ? _sfc_setup$9(props, ctx) : void 0;
};
const TopHud = /* @__PURE__ */ _export_sfc(_sfc_main$9, [["__scopeId", "data-v-a346a00f"]]);
const _sfc_main$8 = {
  __name: "BootScreen",
  __ssrInlineRender: true,
  props: {
    /** 淡出中（父级控制，用于启动 CSS 过渡） */
    gone: { type: Boolean, default: false }
  },
  emits: ["enter"],
  setup(__props, { emit: __emit }) {
    const emit = __emit;
    const width = ref(0);
    const ready = ref(false);
    let timer = null;
    let entered = false;
    function enter() {
      if (entered) return;
      entered = true;
      beep(960, 0.12);
      setTimeout(() => beep(1320, 0.16), 110);
      emit("enter");
    }
    function onKey() {
      enter();
    }
    onMounted(() => {
      timer = setInterval(() => {
        width.value = Math.min(100, width.value + Math.random() * 11 + 4);
        if (width.value >= 100) {
          clearInterval(timer);
          ready.value = true;
        }
      }, 90);
      window.addEventListener("keydown", onKey);
    });
    onBeforeUnmount(() => {
      clearInterval(timer);
      window.removeEventListener("keydown", onKey);
    });
    return (_ctx, _push, _parent, _attrs) => {
      _push(`<div${ssrRenderAttrs(mergeProps({
        class: ["boot", { gone: __props.gone }]
      }, _attrs))} data-v-7f680903><div class="blogo" data-v-7f680903><span class="sl" data-v-7f680903></span><span data-v-7f680903>AGENT ACCESS</span></div><div class="bbar" data-v-7f680903><i style="${ssrRenderStyle({ width: width.value + "%" })}" data-v-7f680903></i></div><div class="${ssrRenderClass([{ on: ready.value }, "bhint"])}" data-v-7f680903>点击任意位置 / PRESS ANY KEY</div></div>`);
    };
  }
};
const _sfc_setup$8 = _sfc_main$8.setup;
_sfc_main$8.setup = (props, ctx) => {
  const ssrContext = useSSRContext();
  (ssrContext.modules || (ssrContext.modules = /* @__PURE__ */ new Set())).add("src/components/BootScreen.vue");
  return _sfc_setup$8 ? _sfc_setup$8(props, ctx) : void 0;
};
const BootScreen = /* @__PURE__ */ _export_sfc(_sfc_main$8, [["__scopeId", "data-v-7f680903"]]);
const _sfc_main$7 = {
  __name: "AgentShowcase",
  __ssrInlineRender: true,
  setup(__props) {
    const monoEl = ref(null);
    const widths = ref(currentAgent.value.stats.map(() => 0));
    function playStats() {
      widths.value = currentAgent.value.stats.map(() => 0);
      setTimeout(() => {
        widths.value = [...currentAgent.value.stats];
      }, 120);
    }
    function playMono() {
      const el = monoEl.value;
      if (!el) return;
      el.style.transition = "none";
      el.style.transform = "translateY(20px)";
      el.style.opacity = "0";
      void el.offsetWidth;
      setTimeout(() => {
        el.style.transition = ".45s cubic-bezier(.2,1,.3,1)";
        el.style.transform = "none";
        el.style.opacity = ".6";
      }, 80);
    }
    onMounted(playStats);
    watch(
      () => state.agentIndex,
      () => {
        playMono();
        playStats();
      }
    );
    return (_ctx, _push, _parent, _attrs) => {
      _push(`<section${ssrRenderAttrs(mergeProps({ class: "showcase" }, _attrs))} data-v-cd6addc1><div class="portrait" style="${ssrRenderStyle({ "--ac": unref(currentAgent).color })}" data-v-cd6addc1><div class="pbg" data-v-cd6addc1></div><div class="glow" data-v-cd6addc1></div><div class="pscan" data-v-cd6addc1></div><span class="ptag" data-v-cd6addc1>SELECTED · ${ssrInterpolate(unref(currentAgent).name)}</span><span class="mono" data-v-cd6addc1>${ssrInterpolate(unref(currentAgent).mono)}</span><span class="plvl" data-v-cd6addc1>LV.<span data-v-cd6addc1>${ssrInterpolate(unref(agentLevel))}</span></span></div><div class="ameta" data-v-cd6addc1><div class="arole" data-v-cd6addc1>${ssrInterpolate(unref(currentAgent).role)}</div><h2 class="aname" data-v-cd6addc1>${ssrInterpolate(unref(currentAgent).name)}</h2><p class="abio" data-v-cd6addc1>${ssrInterpolate(unref(currentAgent).bio)}</p><div class="stats" data-v-cd6addc1><!--[-->`);
      ssrRenderList(unref(currentAgent).stats, (v, k) => {
        _push(`<div class="stat-row" data-v-cd6addc1><span data-v-cd6addc1>${ssrInterpolate(unref(STAT_LABELS)[k])}</span><div class="trk" data-v-cd6addc1><i style="${ssrRenderStyle({ width: widths.value[k] + "%", background: unref(currentAgent).color })}" data-v-cd6addc1></i></div><span data-v-cd6addc1>${ssrInterpolate(v)}</span></div>`);
      });
      _push(`<!--]--></div></div></section>`);
    };
  }
};
const _sfc_setup$7 = _sfc_main$7.setup;
_sfc_main$7.setup = (props, ctx) => {
  const ssrContext = useSSRContext();
  (ssrContext.modules || (ssrContext.modules = /* @__PURE__ */ new Set())).add("src/components/AgentShowcase.vue");
  return _sfc_setup$7 ? _sfc_setup$7(props, ctx) : void 0;
};
const AgentShowcase = /* @__PURE__ */ _export_sfc(_sfc_main$7, [["__scopeId", "data-v-cd6addc1"]]);
const _sfc_main$6 = {
  __name: "AgentStrip",
  __ssrInlineRender: true,
  setup(__props) {
    return (_ctx, _push, _parent, _attrs) => {
      _push(`<div${ssrRenderAttrs(mergeProps({ class: "strip" }, _attrs))} data-v-b711562e><!--[-->`);
      ssrRenderList(unref(AGENTS), (a, i) => {
        _push(`<div class="${ssrRenderClass([{ sel: i === unref(state).agentIndex }, "card"])}" style="${ssrRenderStyle({ "--ac": a.color })}" data-v-b711562e><div class="cp" data-v-b711562e></div><span class="cr" data-v-b711562e>${ssrInterpolate(unref(roleShort)(a.role))}</span><span class="cm" data-v-b711562e>${ssrInterpolate(a.mono)}</span><span class="cn" data-v-b711562e>${ssrInterpolate(a.name)}</span></div>`);
      });
      _push(`<!--]--></div>`);
    };
  }
};
const _sfc_setup$6 = _sfc_main$6.setup;
_sfc_main$6.setup = (props, ctx) => {
  const ssrContext = useSSRContext();
  (ssrContext.modules || (ssrContext.modules = /* @__PURE__ */ new Set())).add("src/components/AgentStrip.vue");
  return _sfc_setup$6 ? _sfc_setup$6(props, ctx) : void 0;
};
const AgentStrip = /* @__PURE__ */ _export_sfc(_sfc_main$6, [["__scopeId", "data-v-b711562e"]]);
const EYE_ON = '<svg width="17" height="17" viewBox="0 0 24 24" fill="none"><path d="M2.5 12S6 5.5 12 5.5 21.5 12 21.5 12 18 18.5 12 18.5 2.5 12 2.5 12Z" stroke="currentColor" stroke-width="1.7"/><circle cx="12" cy="12" r="3" stroke="currentColor" stroke-width="1.7"/></svg>';
const EYE_OFF = '<svg width="17" height="17" viewBox="0 0 24 24" fill="none"><path d="M4 4l16 16" stroke="currentColor" stroke-width="1.7" stroke-linecap="round"/><path d="M6.4 7.4A17 17 0 0 0 2.5 12S6 18.5 12 18.5c1.1 0 2.1-.2 3-.6M9.9 5.8A9.6 9.6 0 0 1 12 5.5c6 0 9.5 6.5 9.5 6.5a17 17 0 0 1-3.1 3.8" stroke="currentColor" stroke-width="1.7" stroke-linecap="round"/></svg>';
const _sfc_main$5 = {
  __name: "FieldInput",
  __ssrInlineRender: true,
  props: {
    modelValue: { type: String, default: "" },
    label: { type: String, default: "" },
    /** text | email | password */
    type: { type: String, default: "text" },
    placeholder: { type: String, default: "" },
    autocomplete: { type: String, default: "off" },
    maxlength: { type: [String, Number], default: void 0 },
    /** 是否渲染密码显隐按钮 */
    password: { type: Boolean, default: false },
    /** 错误态 */
    bad: { type: Boolean, default: false },
    errorText: { type: String, default: "" }
  },
  emits: ["update:modelValue"],
  setup(__props) {
    const props = __props;
    ref(null);
    const focused = ref(false);
    const revealed = ref(false);
    const inputType = computed(() => {
      if (!props.password) return props.type;
      return revealed.value ? "text" : "password";
    });
    const eyeIcon = computed(() => revealed.value ? EYE_OFF : EYE_ON);
    return (_ctx, _push, _parent, _attrs) => {
      _push(`<div${ssrRenderAttrs(mergeProps({
        class: ["field", { focus: focused.value, bad: __props.bad }]
      }, _attrs))}>`);
      if (__props.label) {
        _push(`<label>${ssrInterpolate(__props.label)}</label>`);
      } else {
        _push(`<!---->`);
      }
      _push(`<div class="fin">`);
      ssrRenderSlot(_ctx.$slots, "icon", {}, null, _push, _parent);
      _push(`<input${ssrRenderAttr("type", inputType.value)}${ssrRenderAttr("value", __props.modelValue)}${ssrRenderAttr("placeholder", __props.placeholder)}${ssrRenderAttr("autocomplete", __props.autocomplete)}${ssrRenderAttr("maxlength", __props.maxlength)}>`);
      if (__props.password) {
        _push(`<button class="eye" type="button" aria-label="显示密码">${eyeIcon.value ?? ""}</button>`);
      } else {
        _push(`<!---->`);
      }
      _push(`</div><span class="emsg">${ssrInterpolate(__props.errorText)}</span>`);
      ssrRenderSlot(_ctx.$slots, "default", {}, null, _push, _parent);
      _push(`</div>`);
    };
  }
};
const _sfc_setup$5 = _sfc_main$5.setup;
_sfc_main$5.setup = (props, ctx) => {
  const ssrContext = useSSRContext();
  (ssrContext.modules || (ssrContext.modules = /* @__PURE__ */ new Set())).add("src/components/FieldInput.vue");
  return _sfc_setup$5 ? _sfc_setup$5(props, ctx) : void 0;
};
const _sfc_main$4 = {
  __name: "LoginForm",
  __ssrInlineRender: true,
  setup(__props) {
    const { flash } = useEffects();
    const form = state.login;
    const errors = reactive({ id: false, pass: false });
    const loading = ref(false);
    watch(() => form.id, () => {
      errors.id = false;
    });
    watch(() => form.pass, () => {
      errors.pass = false;
    });
    return (_ctx, _push, _parent, _attrs) => {
      _push(`<form${ssrRenderAttrs(mergeProps({
        class: "form",
        novalidate: ""
      }, _attrs))}>`);
      _push(ssrRenderComponent(_sfc_main$5, {
        modelValue: unref(form).id,
        "onUpdate:modelValue": ($event) => unref(form).id = $event,
        label: "Riot ID / 邮箱",
        placeholder: "agent#0000",
        autocomplete: "username",
        bad: errors.id,
        "error-text": "请输入 Riot ID 或有效邮箱"
      }, {
        icon: withCtx((_, _push2, _parent2, _scopeId) => {
          if (_push2) {
            _push2(`<svg class="ic" width="17" height="17" viewBox="0 0 24 24" fill="none"${_scopeId}><circle cx="12" cy="8" r="3.6" stroke="currentColor" stroke-width="1.7"${_scopeId}></circle><path d="M5 19.5c1.3-3 4-4.5 7-4.5s5.7 1.5 7 4.5" stroke="currentColor" stroke-width="1.7" stroke-linecap="round"${_scopeId}></path></svg>`);
          } else {
            return [
              (openBlock(), createBlock("svg", {
                class: "ic",
                width: "17",
                height: "17",
                viewBox: "0 0 24 24",
                fill: "none"
              }, [
                createVNode("circle", {
                  cx: "12",
                  cy: "8",
                  r: "3.6",
                  stroke: "currentColor",
                  "stroke-width": "1.7"
                }),
                createVNode("path", {
                  d: "M5 19.5c1.3-3 4-4.5 7-4.5s5.7 1.5 7 4.5",
                  stroke: "currentColor",
                  "stroke-width": "1.7",
                  "stroke-linecap": "round"
                })
              ]))
            ];
          }
        }),
        _: 1
      }, _parent));
      _push(ssrRenderComponent(_sfc_main$5, {
        modelValue: unref(form).pass,
        "onUpdate:modelValue": ($event) => unref(form).pass = $event,
        label: "密码",
        placeholder: "••••••••",
        autocomplete: "current-password",
        password: "",
        bad: errors.pass,
        "error-text": "密码至少 6 位"
      }, {
        icon: withCtx((_, _push2, _parent2, _scopeId) => {
          if (_push2) {
            _push2(`<svg class="ic" width="17" height="17" viewBox="0 0 24 24" fill="none"${_scopeId}><rect x="4" y="10" width="16" height="11" rx="2" stroke="currentColor" stroke-width="1.7"${_scopeId}></rect><path d="M8 10V7a4 4 0 0 1 8 0v3" stroke="currentColor" stroke-width="1.7" stroke-linecap="round"${_scopeId}></path></svg>`);
          } else {
            return [
              (openBlock(), createBlock("svg", {
                class: "ic",
                width: "17",
                height: "17",
                viewBox: "0 0 24 24",
                fill: "none"
              }, [
                createVNode("rect", {
                  x: "4",
                  y: "10",
                  width: "16",
                  height: "11",
                  rx: "2",
                  stroke: "currentColor",
                  "stroke-width": "1.7"
                }),
                createVNode("path", {
                  d: "M8 10V7a4 4 0 0 1 8 0v3",
                  stroke: "currentColor",
                  "stroke-width": "1.7",
                  "stroke-linecap": "round"
                })
              ]))
            ];
          }
        }),
        _: 1
      }, _parent));
      _push(`<div class="row"><label class="chk"><input${ssrIncludeBooleanAttr(Array.isArray(unref(form).remember) ? ssrLooseContain(unref(form).remember, null) : unref(form).remember) ? " checked" : ""} type="checkbox"><span class="bx"><svg width="11" height="11" viewBox="0 0 24 24" fill="none"><path d="m5 13 4 4L19 7" stroke="currentColor" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"></path></svg></span>保持登录 </label><a class="lnk" href="#">忘记密码?</a></div><button type="submit" class="${ssrRenderClass([{ loading: loading.value }, "btn"])}"${ssrIncludeBooleanAttr(loading.value) ? " disabled" : ""}><span>进入战场</span><span class="dots"><i></i><i></i><i></i></span></button><div class="alt">或</div><div class="socials"><button class="soc" type="button">RIOT 账号</button><button class="soc" type="button">STEAM</button></div></form>`);
    };
  }
};
const _sfc_setup$4 = _sfc_main$4.setup;
_sfc_main$4.setup = (props, ctx) => {
  const ssrContext = useSSRContext();
  (ssrContext.modules || (ssrContext.modules = /* @__PURE__ */ new Set())).add("src/components/LoginForm.vue");
  return _sfc_setup$4 ? _sfc_setup$4(props, ctx) : void 0;
};
const _sfc_main$3 = {
  __name: "RegisterForm",
  __ssrInlineRender: true,
  setup(__props) {
    const { flash } = useEffects();
    const form = state.register;
    const errors = reactive({ name: false, email: false, pass: false, pass2: false, terms: false });
    const loading = ref(false);
    watch(() => form.name, () => {
      errors.name = false;
    });
    watch(() => form.email, () => {
      errors.email = false;
    });
    watch(() => form.pass, () => {
      errors.pass = false;
    });
    watch(() => form.pass2, () => {
      errors.pass2 = false;
    });
    watch(() => form.terms, () => {
      errors.terms = false;
    });
    const secFill = computed(() => SEC_COLORS[securityLevel.value - 1] || SEC_COLORS[0]);
    const secText = computed(() => SEC_TEXTS[securityLevel.value - 1] || "低");
    const secTextColor = computed(() => SEC_COLORS[securityLevel.value - 1] || "#7f8e9b");
    function segStyle(n) {
      const on = n <= securityLevel.value;
      return {
        background: on ? secFill.value : "rgba(236,232,225,.1)",
        boxShadow: on ? `0 0 10px ${secFill.value}` : "none"
      };
    }
    return (_ctx, _push, _parent, _attrs) => {
      _push(`<form${ssrRenderAttrs(mergeProps({
        class: "form",
        novalidate: ""
      }, _attrs))}>`);
      _push(ssrRenderComponent(_sfc_main$5, {
        modelValue: unref(form).name,
        "onUpdate:modelValue": ($event) => unref(form).name = $event,
        label: "特工代号",
        placeholder: "CODENAME",
        autocomplete: "username",
        maxlength: 14,
        bad: errors.name,
        "error-text": "代号至少 2 个字符"
      }, {
        icon: withCtx((_, _push2, _parent2, _scopeId) => {
          if (_push2) {
            _push2(`<svg class="ic" width="17" height="17" viewBox="0 0 24 24" fill="none"${_scopeId}><path d="M12 2 3 7v10l9 5 9-5V7l-9-5Z" stroke="currentColor" stroke-width="1.7" stroke-linejoin="round"${_scopeId}></path></svg>`);
          } else {
            return [
              (openBlock(), createBlock("svg", {
                class: "ic",
                width: "17",
                height: "17",
                viewBox: "0 0 24 24",
                fill: "none"
              }, [
                createVNode("path", {
                  d: "M12 2 3 7v10l9 5 9-5V7l-9-5Z",
                  stroke: "currentColor",
                  "stroke-width": "1.7",
                  "stroke-linejoin": "round"
                })
              ]))
            ];
          }
        }),
        _: 1
      }, _parent));
      _push(ssrRenderComponent(_sfc_main$5, {
        modelValue: unref(form).email,
        "onUpdate:modelValue": ($event) => unref(form).email = $event,
        label: "邮箱",
        type: "email",
        placeholder: "agent@nexus.net",
        autocomplete: "email",
        bad: errors.email,
        "error-text": "邮箱格式不正确"
      }, {
        icon: withCtx((_, _push2, _parent2, _scopeId) => {
          if (_push2) {
            _push2(`<svg class="ic" width="17" height="17" viewBox="0 0 24 24" fill="none"${_scopeId}><rect x="3" y="5" width="18" height="14" rx="2" stroke="currentColor" stroke-width="1.7"${_scopeId}></rect><path d="m4 7 8 6 8-6" stroke="currentColor" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round"${_scopeId}></path></svg>`);
          } else {
            return [
              (openBlock(), createBlock("svg", {
                class: "ic",
                width: "17",
                height: "17",
                viewBox: "0 0 24 24",
                fill: "none"
              }, [
                createVNode("rect", {
                  x: "3",
                  y: "5",
                  width: "18",
                  height: "14",
                  rx: "2",
                  stroke: "currentColor",
                  "stroke-width": "1.7"
                }),
                createVNode("path", {
                  d: "m4 7 8 6 8-6",
                  stroke: "currentColor",
                  "stroke-width": "1.7",
                  "stroke-linecap": "round",
                  "stroke-linejoin": "round"
                })
              ]))
            ];
          }
        }),
        _: 1
      }, _parent));
      _push(ssrRenderComponent(_sfc_main$5, {
        modelValue: unref(form).pass,
        "onUpdate:modelValue": ($event) => unref(form).pass = $event,
        label: "密码",
        placeholder: "至少 6 位",
        autocomplete: "new-password",
        password: "",
        bad: errors.pass,
        "error-text": "密码至少 6 位"
      }, {
        icon: withCtx((_, _push2, _parent2, _scopeId) => {
          if (_push2) {
            _push2(`<svg class="ic" width="17" height="17" viewBox="0 0 24 24" fill="none"${_scopeId}><rect x="4" y="10" width="16" height="11" rx="2" stroke="currentColor" stroke-width="1.7"${_scopeId}></rect><path d="M8 10V7a4 4 0 0 1 8 0v3" stroke="currentColor" stroke-width="1.7" stroke-linecap="round"${_scopeId}></path></svg>`);
          } else {
            return [
              (openBlock(), createBlock("svg", {
                class: "ic",
                width: "17",
                height: "17",
                viewBox: "0 0 24 24",
                fill: "none"
              }, [
                createVNode("rect", {
                  x: "4",
                  y: "10",
                  width: "16",
                  height: "11",
                  rx: "2",
                  stroke: "currentColor",
                  "stroke-width": "1.7"
                }),
                createVNode("path", {
                  d: "M8 10V7a4 4 0 0 1 8 0v3",
                  stroke: "currentColor",
                  "stroke-width": "1.7",
                  "stroke-linecap": "round"
                })
              ]))
            ];
          }
        }),
        default: withCtx((_, _push2, _parent2, _scopeId) => {
          if (_push2) {
            _push2(`<div class="${ssrRenderClass([{ on: unref(securityLevel) > 0 }, "secu"])}"${_scopeId}><div class="lb"${_scopeId}><span${_scopeId}>SECURITY 加密等级</span><span style="${ssrRenderStyle({ color: secTextColor.value })}"${_scopeId}>${ssrInterpolate(secText.value)}</span></div><div class="segs"${_scopeId}><!--[-->`);
            ssrRenderList(4, (n) => {
              _push2(`<i style="${ssrRenderStyle(segStyle(n))}"${_scopeId}></i>`);
            });
            _push2(`<!--]--></div></div>`);
          } else {
            return [
              createVNode("div", {
                class: ["secu", { on: unref(securityLevel) > 0 }]
              }, [
                createVNode("div", { class: "lb" }, [
                  createVNode("span", null, "SECURITY 加密等级"),
                  createVNode("span", {
                    style: { color: secTextColor.value }
                  }, toDisplayString(secText.value), 5)
                ]),
                createVNode("div", { class: "segs" }, [
                  (openBlock(), createBlock(Fragment, null, renderList(4, (n) => {
                    return createVNode("i", {
                      key: n,
                      style: segStyle(n)
                    }, null, 4);
                  }), 64))
                ])
              ], 2)
            ];
          }
        }),
        _: 1
      }, _parent));
      _push(ssrRenderComponent(_sfc_main$5, {
        modelValue: unref(form).pass2,
        "onUpdate:modelValue": ($event) => unref(form).pass2 = $event,
        label: "确认密码",
        placeholder: "再输一次",
        autocomplete: "new-password",
        password: "",
        bad: errors.pass2,
        "error-text": "两次密码不一致"
      }, {
        icon: withCtx((_, _push2, _parent2, _scopeId) => {
          if (_push2) {
            _push2(`<svg class="ic" width="17" height="17" viewBox="0 0 24 24" fill="none"${_scopeId}><path d="M12 3 4.5 6.5v5c0 4.4 3.1 8.4 7.5 9.5 4.4-1.1 7.5-5.1 7.5-9.5v-5L12 3Z" stroke="currentColor" stroke-width="1.7" stroke-linejoin="round"${_scopeId}></path><path d="m9 12 2 2 4-4" stroke="currentColor" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round"${_scopeId}></path></svg>`);
          } else {
            return [
              (openBlock(), createBlock("svg", {
                class: "ic",
                width: "17",
                height: "17",
                viewBox: "0 0 24 24",
                fill: "none"
              }, [
                createVNode("path", {
                  d: "M12 3 4.5 6.5v5c0 4.4 3.1 8.4 7.5 9.5 4.4-1.1 7.5-5.1 7.5-9.5v-5L12 3Z",
                  stroke: "currentColor",
                  "stroke-width": "1.7",
                  "stroke-linejoin": "round"
                }),
                createVNode("path", {
                  d: "m9 12 2 2 4-4",
                  stroke: "currentColor",
                  "stroke-width": "1.7",
                  "stroke-linecap": "round",
                  "stroke-linejoin": "round"
                })
              ]))
            ];
          }
        }),
        _: 1
      }, _parent));
      _push(`<div class="${ssrRenderClass([{ bad: errors.terms }, "field"])}"><label class="chk" style="${ssrRenderStyle({ "text-transform": "none", "font-size": "12px" })}"><input type="checkbox"${ssrIncludeBooleanAttr(unref(form).terms) ? " checked" : ""}><span class="bx"><svg width="11" height="11" viewBox="0 0 24 24" fill="none"><path d="m5 13 4 4L19 7" stroke="currentColor" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"></path></svg></span> 我已阅读并同意 <a class="lnk" href="#">服务条款</a> 与 <a class="lnk" href="#">隐私政策</a></label><span class="emsg">请先同意服务条款</span></div><button type="submit" class="${ssrRenderClass([{ loading: loading.value }, "btn"])}"${ssrIncludeBooleanAttr(loading.value) ? " disabled" : ""}><span>创建特工</span><span class="dots"><i></i><i></i><i></i></span></button></form>`);
    };
  }
};
const _sfc_setup$3 = _sfc_main$3.setup;
_sfc_main$3.setup = (props, ctx) => {
  const ssrContext = useSSRContext();
  (ssrContext.modules || (ssrContext.modules = /* @__PURE__ */ new Set())).add("src/components/RegisterForm.vue");
  return _sfc_setup$3 ? _sfc_setup$3(props, ctx) : void 0;
};
const _sfc_main$2 = {
  __name: "AuthPanel",
  __ssrInlineRender: true,
  setup(__props) {
    const hint = ref("");
    const isLogin = computed(() => state.mode === "login");
    const title = computed(() => isLogin.value ? "特工接入" : "注册新特工");
    const subtitle = computed(
      () => isLogin.value ? "使用你的 Riot ID 凭证继续执行任务" : "创建你的账号，加入战场"
    );
    function syncAgentHint() {
      hint.value = `当前特工： ${currentAgent.value.name} · ${currentAgent.value.role}`;
    }
    watch(() => state.agentIndex, syncAgentHint);
    onMounted(syncAgentHint);
    return (_ctx, _push, _parent, _attrs) => {
      _push(`<section${ssrRenderAttrs(mergeProps({ class: "auth" }, _attrs))} data-v-1663f3e9><div class="tabs" data-v-1663f3e9><button class="${ssrRenderClass([{ on: isLogin.value }, "tab"])}" type="button" data-v-1663f3e9>登录</button><button class="${ssrRenderClass([{ on: !isLogin.value }, "tab"])}" type="button" data-v-1663f3e9>创建账号</button></div><div class="ahead" data-v-1663f3e9><h1 data-v-1663f3e9>${ssrInterpolate(title.value)}</h1><p data-v-1663f3e9>${ssrInterpolate(subtitle.value)}</p></div>`);
      _push(ssrRenderComponent(_sfc_main$4, {
        class: { on: isLogin.value }
      }, null, _parent));
      _push(ssrRenderComponent(_sfc_main$3, {
        class: { on: !isLogin.value }
      }, null, _parent));
      _push(`<div class="hint" data-v-1663f3e9>${ssrInterpolate(hint.value)}</div></section>`);
    };
  }
};
const _sfc_setup$2 = _sfc_main$2.setup;
_sfc_main$2.setup = (props, ctx) => {
  const ssrContext = useSSRContext();
  (ssrContext.modules || (ssrContext.modules = /* @__PURE__ */ new Set())).add("src/components/AuthPanel.vue");
  return _sfc_setup$2 ? _sfc_setup$2(props, ctx) : void 0;
};
const AuthPanel = /* @__PURE__ */ _export_sfc(_sfc_main$2, [["__scopeId", "data-v-1663f3e9"]]);
const _sfc_main$1 = {
  __name: "AppToast",
  __ssrInlineRender: true,
  setup(__props) {
    return (_ctx, _push, _parent, _attrs) => {
      _push(`<div${ssrRenderAttrs(mergeProps({
        class: ["toast", { on: unref(state).toast.visible, ok: unref(state).toast.ok }]
      }, _attrs))} data-v-dbfc020f>${ssrInterpolate(unref(state).toast.text)}</div>`);
    };
  }
};
const _sfc_setup$1 = _sfc_main$1.setup;
_sfc_main$1.setup = (props, ctx) => {
  const ssrContext = useSSRContext();
  (ssrContext.modules || (ssrContext.modules = /* @__PURE__ */ new Set())).add("src/components/AppToast.vue");
  return _sfc_setup$1 ? _sfc_setup$1(props, ctx) : void 0;
};
const AppToast = /* @__PURE__ */ _export_sfc(_sfc_main$1, [["__scopeId", "data-v-dbfc020f"]]);
const _sfc_main = {
  __name: "App",
  __ssrInlineRender: true,
  setup(__props) {
    const { showToast: showToast2 } = useSession();
    useParallax();
    function applyAccent(color) {
      if (typeof document === "undefined") return;
      document.documentElement.style.setProperty("--ac", color);
    }
    watch(accent, applyAccent, { immediate: true });
    const bootVisible = ref(true);
    const bootGone = ref(false);
    function enterTerminal() {
      bootGone.value = true;
      document.documentElement.style.setProperty("--mx", "0");
      setTimeout(() => {
        bootVisible.value = false;
        state.booted = true;
      }, 700);
      setTimeout(() => showToast2("终端已就绪 · 请选择你的特工", true), 780);
    }
    const flashEl = ref(null);
    const flashing = ref(false);
    let flashTimer = null;
    async function flash() {
      flashing.value = false;
      await nextTick();
      if (flashEl.value) void flashEl.value.offsetWidth;
      flashing.value = true;
      clearTimeout(flashTimer);
      flashTimer = setTimeout(() => {
        flashing.value = false;
      }, 520);
    }
    provide(FX_KEY, { flash });
    onBeforeUnmount(() => clearTimeout(flashTimer));
    return (_ctx, _push, _parent, _attrs) => {
      _push(`<!--[-->`);
      _push(ssrRenderComponent(FxBackground, null, null, _parent));
      _push(`<div class="scanline" data-v-386c7bf8></div><div class="noise" data-v-386c7bf8></div>`);
      _push(ssrRenderComponent(Crosshair, null, null, _parent));
      _push(ssrRenderComponent(TopHud, null, null, _parent));
      _push(`<div class="wrap" data-v-386c7bf8><div class="stage" data-v-386c7bf8>`);
      _push(ssrRenderComponent(AgentShowcase, null, null, _parent));
      _push(ssrRenderComponent(AuthPanel, null, null, _parent));
      _push(`</div>`);
      _push(ssrRenderComponent(AgentStrip, null, null, _parent));
      _push(`</div>`);
      _push(ssrRenderComponent(ClickEffects, null, null, _parent));
      _push(ssrRenderComponent(AppToast, null, null, _parent));
      _push(`<div class="${ssrRenderClass([{ go: flashing.value }, "flash"])}" data-v-386c7bf8></div>`);
      if (bootVisible.value) {
        _push(ssrRenderComponent(BootScreen, {
          gone: bootGone.value,
          onEnter: enterTerminal
        }, null, _parent));
      } else {
        _push(`<!---->`);
      }
      _push(`<!--]-->`);
    };
  }
};
const _sfc_setup = _sfc_main.setup;
_sfc_main.setup = (props, ctx) => {
  const ssrContext = useSSRContext();
  (ssrContext.modules || (ssrContext.modules = /* @__PURE__ */ new Set())).add("src/App.vue");
  return _sfc_setup ? _sfc_setup(props, ctx) : void 0;
};
const App = /* @__PURE__ */ _export_sfc(_sfc_main, [["__scopeId", "data-v-386c7bf8"]]);
async function render() {
  const app = createSSRApp(App);
  return await renderToString(app);
}
export {
  render
};
