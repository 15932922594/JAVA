#!/usr/bin/env node
/**
 * 显示当前这台机器可用的局域网访问地址。
 *
 * 用法：npm run lan
 *
 * 前端 dev 服务器监听 0.0.0.0，所以这里列出的每个 IPv4 都能直接打开；
 * 常用网络（家里 / 工作 / 其他常连的）会单独标出来，方便一眼确认现在在哪套网络下。
 */
import os from 'node:os'

/** 常用网络清单：连上对应 Wi-Fi 时会自动高亮并给出推荐地址 */
const FAVORITES = [
  { ip: '192.168.1.13',   name: '家里网络', color: 'green' },
  { ip: '192.168.68.29',  name: '工作网络', color: 'cyan' },
  { ip: '10.14.236.114',  name: '常用网络', color: 'yellow' }
]

const WEB_PORT = 5173
const API_PORT = 8081

const colors = {
  reset: '\u001b[0m',
  dim: '\u001b[2m',
  bold: '\u001b[1m',
  green: '\u001b[32m',
  cyan: '\u001b[36m',
  yellow: '\u001b[33m',
  gray: '\u001b[90m'
}
const c = (color, text) => `${colors[color] || ''}${text}${colors.reset}`

function ipv4List() {
  const out = []
  for (const [name, addrs] of Object.entries(os.networkInterfaces())) {
    for (const addr of addrs || []) {
      if (addr.family !== 'IPv4' && addr.family !== 4) continue
      if (addr.internal) continue
      out.push({ name, address: addr.address, netmask: addr.netmask })
    }
  }
  return out
}

const list = ipv4List()

// 虚拟网卡（VMware / Hyper-V / WSL / 虚拟网卡）不对外，单独归到"其他"里
const VIRTUAL = /vmware|virtualbox|vethernet|hyper-v|wsl|loopback|tap|tun|docker|bluetooth/i
const real = list.filter((n) => !VIRTUAL.test(n.name))
const virtual = list.filter((n) => VIRTUAL.test(n.name))

console.log('')
console.log(c('bold', '  VALORANT 竞技场 · 网络检测'))
console.log(c('gray', '  ─────────────────────────────────────────'))

if (!list.length) {
  console.log(c('yellow', '  没有检测到局域网网卡，请确认已连接 Wi-Fi 或有线网络。'))
  console.log('')
  process.exit(0)
}

const activeFavorites = []

for (const nic of real) {
  const fav = FAVORITES.find((f) => f.ip === nic.address)
  if (fav) activeFavorites.push(fav)

  const tag = fav ? c(fav.color, ` [${fav.name}]`) : ''
  console.log('')
  console.log(`  ${c('bold', nic.name)}${tag}`)
  console.log(`  网卡 IP    ${c('bold', nic.address)}`)
  console.log(`  前端访问   ${c('green', `http://${nic.address}:${WEB_PORT}`)}`)
  console.log(`  后端接口   ${c('gray', `http://${nic.address}:${API_PORT}/api`)}`)
}

console.log('')
console.log(c('gray', '  ─────────────────────────────────────────'))
console.log(`  本机访问   ${c('green', `http://localhost:${WEB_PORT}`)}`)
console.log('')

for (const fav of FAVORITES) {
  const on = activeFavorites.includes(fav)
  console.log(`  ${fav.name} ${fav.ip}：${on ? c(fav.color, '已激活') : c('gray', '未连接')}`)
}

if (virtual.length) {
  console.log('')
  console.log(c('gray', `  其他虚拟网卡（外部设备访问不到，忽略即可）`))
  for (const nic of virtual) {
    console.log(c('gray', `    ${nic.name}  ${nic.address}`))
  }
}
console.log('')

if (activeFavorites.length) {
  const active = activeFavorites[0]
  console.log(c('bold', `  现在直接用 http://${active.ip}:${WEB_PORT} 打开即可。`))
  console.log('')
} else {
  console.log(c('yellow', '  当前不在常用网络下。上面的地址依然可以正常使用（监听 0.0.0.0）。'))
  console.log('')
}
