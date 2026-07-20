import type { ScenarioDef } from '@/core/data/types'

// 基础版 4 人布局：3-4-5-4-3 共 19 格
// 不预设地形与数字（开局随机生成），只指定 19 个陆地坐标 + 9 个港口边界顶点
// 港口顶点键格式："vx,vy"（与 board.ts 中 vertexKey 一致）

const BASE_HEXES = [
  // r = -2
  { q: 0, r: -2 },
  { q: 1, r: -2 },
  { q: 2, r: -2 },
  // r = -1
  { q: -1, r: -1 },
  { q: 0, r: -1 },
  { q: 1, r: -1 },
  { q: 2, r: -1 },
  // r = 0
  { q: -2, r: 0 },
  { q: -1, r: 0 },
  { q: 0, r: 0 },
  { q: 1, r: 0 },
  { q: 2, r: 0 },
  // r = 1
  { q: -2, r: 1 },
  { q: -1, r: 1 },
  { q: 0, r: 1 },
  { q: 1, r: 1 },
  // r = 2
  { q: -2, r: 2 },
  { q: -1, r: 2 },
  { q: 0, r: 2 },
]

// 标准布局的 9 个港口位置（位于外圈六边形之间的边界顶点对）
// 这里只标记"位置占位"，运行时由 boardGenerator 分配具体 PortId
// 物理坐标键 = (2q+r+dx, 3r+dy)
// 我们用 board 拓扑生成后从 boundaryVertices 挑选
export const BASE_SCENARIO: ScenarioDef = {
  id: 'base_4p',
  name: '基础版 · 4 人',
  description: '经典卡坦岛，19 格陆地布局，9 个港口环绕。胜利点门槛 10。',
  victoryPointThreshold: 10,
  hexes: BASE_HEXES.map((h, i) => ({
    q: h.q,
    r: h.r,
    terrain: 'forest', // 占位，生成器会重新分配
    // 数字牌生成器也会重新分配
  })),
}
