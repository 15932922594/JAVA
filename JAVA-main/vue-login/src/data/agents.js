/* ============================================================
   特工数据（原创设定）—— 与原页面 AGENTS 数组完全一致
   ============================================================ */

/** 属性条标签顺序 */
export const STAT_LABELS = ['火力', '机动', '控制', '防御']

/** 可选特工列表 */
export const AGENTS = [
  {
    id: 'vector',
    name: 'VECTOR',
    mono: 'V',
    role: '突击 · ASSAULT',
    color: '#FF4655',
    bio: '以极高机动性撕裂防线的突进型特工，擅长在瞬间改写交火态势。',
    stats: [92, 76, 44, 38]
  },
  {
    id: 'arclight',
    name: 'ARCLIGHT',
    mono: 'A',
    role: '侦察 · RECON',
    color: '#00E0C6',
    bio: '用电弧脉冲扫描战场，为队伍点亮迷雾中的每一个目标。',
    stats: [58, 86, 72, 46]
  },
  {
    id: 'phantom',
    name: 'PHANTOM',
    mono: 'P',
    role: '控场 · CONTROL',
    color: '#A66CFF',
    bio: '制造幻象与烟幕，掌控每一次交火的节奏与视野。',
    stats: [52, 74, 93, 50]
  },
  {
    id: 'onyx',
    name: 'ONYX',
    mono: 'O',
    role: '守护 · SENTINEL',
    color: '#FFB443',
    bio: '以坚固壁垒庇护队友，是阵地攻防中不可撼动的支点。',
    stats: [46, 52, 64, 96]
  },
  {
    id: 'tempest',
    name: 'TEMPEST',
    mono: 'T',
    role: '控场 · CONTROL',
    color: '#4DA6FF',
    bio: '召唤风暴封锁通路，让敌人在自己的领地寸步难行。',
    stats: [54, 70, 90, 62]
  },
  {
    id: 'ember',
    name: 'EMBER',
    mono: 'E',
    role: '突击 · ASSAULT',
    color: '#FF6B4A',
    bio: '以烈焰灼烧前线的爆发型特工，高风险，也高回报。',
    stats: [90, 64, 52, 54]
  }
]

/** 取角色所属阵营的英文短名，用于卡片右上角角标，如 "突击 · ASSAULT" → "ASSAULT" */
export function roleShort(role) {
  return role.split(' · ')[1] ?? role
}
