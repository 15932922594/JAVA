/* ============================================================
   武器外观数据 —— 价格与目录以后端 /api/game/armory 返回为准，
   这里只放展示用的主题色 / 英文名 / 简介等视觉信息（按 code 匹配）。
   ============================================================ */

/**
 * 武器卡片外观。
 * code 与后端 WeaponCatalog 一致：
 *   classic 标配 / sheriff 正义 / marshal 鸟狙 / odin 战神
 *   guardian 戍卫 / phantom 幻影 / vandal 狂徒 / operator 冥狙
 */
export const WEAPONS = {
  classic: {
    name: '标配',
    en: 'CLASSIC',
    mono: 'C',
    color: '#8fa3b0',
    desc: '制式随身手枪，免费配发，人手一把。'
  },
  sheriff: {
    name: '正义',
    en: 'SHERIFF',
    mono: 'S',
    color: '#FFB443',
    desc: '大口径左轮，一发入魂，命中头部即可致命。'
  },
  marshal: {
    name: '鸟狙',
    en: 'MARSHAL',
    mono: 'M',
    color: '#00E0C6',
    desc: '轻型栓动狙击，开镜快、移速高，游走侦察的利器。'
  },
  odin: {
    name: '战神',
    en: 'ODIN',
    mono: 'O',
    color: '#3ddc97',
    desc: '重型机枪，弹链倾泻如洪，压制一切推进企图。'
  },
  guardian: {
    name: '戍卫',
    en: 'GUARDIAN',
    mono: 'G',
    color: '#4DA6FF',
    desc: '半自动步枪，稳定而精准，中距离的可靠支点。'
  },
  phantom: {
    name: '幻影',
    en: 'PHANTOM',
    mono: 'P',
    color: '#A66CFF',
    desc: '无声冲锋步枪，弹道平直，泼水亦能收头。'
  },
  vandal: {
    name: '狂徒',
    en: 'VANDAL',
    mono: 'V',
    color: '#FF6B4A',
    desc: '经典火力步枪，远距离一枪爆头，简单粗暴。'
  },
  operator: {
    name: '冥狙',
    en: 'OPERATOR',
    mono: 'OP',
    color: '#FF4655',
    desc: '重型狙击步枪，全场最贵——命中躯干即判出局。'
  }
}

/** 兜底外观（后端目录扩展新武器时仍可渲染） */
export const WEAPON_FALLBACK = {
  name: '未知武器',
  en: 'UNKNOWN',
  mono: '?',
  color: '#7f8e9b',
  desc: ''
}
