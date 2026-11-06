/* ============================================================
   头像框阶梯（与后端 HeroLevel 的边框规则保持一致）
   ------------------------------------------------------------
   · 固定 11 档：Lv1~50，样式在 styles/frames.css 的 .frame-1…frame-11
   · 星穹系列：Lv.50 之后每 10 级一枚（星穹·壹 / 贰 / 叁 …），
     颜色由档位序号生成（--fp/--fr 内联变量），永无止境
   · 已解锁的边框可在图鉴里自主任意佩戴
   ============================================================ */

export const FIXED_FRAMES = [
  { tier: 1, level: 1, name: '新兵', en: 'RECRUIT' },
  { tier: 2, level: 3, name: '银翼', en: 'SILVER' },
  { tier: 3, level: 5, name: '特工', en: 'AGENT' },
  { tier: 4, level: 8, name: '黄金', en: 'GOLD' },
  { tier: 5, level: 12, name: '猩红', en: 'CRIMSON' },
  { tier: 6, level: 16, name: '青碧', en: 'TEAL' },
  { tier: 7, level: 20, name: '紫晶', en: 'AMETHYST' },
  { tier: 8, level: 25, name: '熔岩', en: 'MAGMA' },
  { tier: 9, level: 30, name: '星辉', en: 'STELLAR' },
  { tier: 10, level: 40, name: '虚空', en: 'VOID' },
  { tier: 11, level: 50, name: '不朽', en: 'IMMORTAL' }
]

/** 兼容旧引用：固定档阶梯 */
export const FRAMES = FIXED_FRAMES

const CN_NUM = ['壹', '贰', '叁', '肆', '伍', '陆', '柒', '捌', '玖', '拾']

function cnNum(n) {
  if (n <= 0) return CN_NUM[0]
  if (n <= 10) return CN_NUM[n - 1]
  const tens = Math.floor(n / 10)
  const ones = n % 10
  let s = ''
  if (tens > 1) s += CN_NUM[tens - 1]
  s += '拾'
  if (ones > 0) s += CN_NUM[ones - 1]
  return s
}

/** 等级 → 边框档位（1 起，无上限：Lv.51~59 仍是不朽，Lv.60 起每 10 级一枚星穹） */
export function frameTierOf(level) {
  const lv = Number(level) || 1
  if (lv < 60) {
    let tier = 1
    for (const f of FIXED_FRAMES) {
      if (lv >= f.level) tier = f.tier
    }
    return tier
  }
  return FIXED_FRAMES.length + Math.floor((lv - 50) / 10)
}

/** 档位 → 边框对象（含星穹系列，任意档位都有定义） */
export function frameOfTier(tier) {
  const t = Math.max(1, Number(tier) || 1)
  if (t <= FIXED_FRAMES.length) return FIXED_FRAMES[t - 1]
  const n = t - FIXED_FRAMES.length
  return {
    tier: t,
    level: 50 + n * 10,
    name: `星穹·${cnNum(n)}`,
    en: `ASTRAL ${n}`,
    proc: true
  }
}

/** 等级 → 当前边框对象 */
export function frameOf(level) {
  return frameOfTier(frameTierOf(level))
}

/** 等级 → 下一档边框（星穹无限延伸，永远有下一档） */
export function nextFrameOf(level) {
  return frameOfTier(frameTierOf(level) + 1)
}

/* ---------- 星穹系列的颜色与样式 ---------- */

/** 星穹档位的色相：按档位序号散开，相邻档颜色差异明显 */
export function frameHue(tier) {
  return (tier * 47) % 360
}

/** 星穹档位的光效节奏：三档一循环（静止 / 快脉冲 / 慢呼吸） */
export function framePatternOf(tier) {
  const p = (tier - FIXED_FRAMES.length - 1) % 3
  return p === 1 ? 'pulse' : p === 2 ? 'breathe' : ''
}

/** 星穹档位的内联颜色变量（配合 frames.css 的 .fp） */
export function frameStyleOf(tier) {
  if (tier <= FIXED_FRAMES.length) return {}
  const h = frameHue(tier)
  return {
    '--fp': `hsl(${h}, 85%, 62%)`,
    '--fr': `hsla(${h}, 85%, 62%, .25)`
  }
}

/** 档位 → 头像元素的 class（固定档用 .frame-N，星穹用 .fp + 节奏类） */
export function frameClassOf(tier) {
  if (tier <= FIXED_FRAMES.length) return [`frame-${tier}`]
  const p = framePatternOf(tier)
  return p ? ['fp', p] : ['fp']
}
