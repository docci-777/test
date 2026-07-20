import type { ScenarioDef } from '@/core/data/types'

// 海洋扩展：新世界
// 棋盘由外圈海洋 + 内部陆地岛屿组成
// 布局：7 行六边形，宽度 5-6-7-7-7-6-5
// 胜利点门槛 13

const HEXES = [
  // r = -3 (5 个浅海)
  { q: -1, r: -3, terrain: 'shallow_water' as const },
  { q: 0, r: -3, terrain: 'shallow_water' as const },
  { q: 1, r: -3, terrain: 'shallow_water' as const },
  { q: 2, r: -3, terrain: 'shallow_water' as const },
  { q: 3, r: -3, terrain: 'shallow_water' as const },
  // r = -2 (6 个：浅海+陆地)
  { q: -2, r: -2, terrain: 'shallow_water' as const },
  { q: -1, r: -2, terrain: 'forest' as const },
  { q: 0, r: -2, terrain: 'hills' as const },
  { q: 1, r: -2, terrain: 'mountains' as const },
  { q: 2, r: -2, terrain: 'pasture' as const },
  { q: 3, r: -2, terrain: 'shallow_water' as const },
  // r = -1 (7 个)
  { q: -2, r: -1, terrain: 'shallow_water' as const },
  { q: -1, r: -1, terrain: 'fields' as const },
  { q: 0, r: -1, terrain: 'forest' as const },
  { q: 1, r: -1, terrain: 'pasture' as const },
  { q: 2, r: -1, terrain: 'fields' as const },
  { q: 3, r: -1, terrain: 'hills' as const },
  { q: 4, r: -1, terrain: 'shallow_water' as const },
  // r = 0 (7 个，中间一行含沙漠)
  { q: -2, r: 0, terrain: 'shallow_water' as const },
  { q: -1, r: 0, terrain: 'mountains' as const },
  { q: 0, r: 0, terrain: 'desert' as const },
  { q: 1, r: 0, terrain: 'gold' as const },
  { q: 2, r: 0, terrain: 'forest' as const },
  { q: 3, r: 0, terrain: 'pasture' as const },
  { q: 4, r: 0, terrain: 'shallow_water' as const },
  // r = 1 (7 个)
  { q: -2, r: 1, terrain: 'shallow_water' as const },
  { q: -1, r: 1, terrain: 'hills' as const },
  { q: 0, r: 1, terrain: 'fields' as const },
  { q: 1, r: 1, terrain: 'mountains' as const },
  { q: 2, r: 1, terrain: 'gold' as const },
  { q: 3, r: 1, terrain: 'fields' as const },
  { q: 4, r: 1, terrain: 'shallow_water' as const },
  // r = 2 (6 个)
  { q: -2, r: 2, terrain: 'shallow_water' as const },
  { q: -1, r: 2, terrain: 'forest' as const },
  { q: 0, r: 2, terrain: 'pasture' as const },
  { q: 1, r: 2, terrain: 'hills' as const },
  { q: 2, r: 2, terrain: 'mountains' as const },
  { q: 3, r: 2, terrain: 'shallow_water' as const },
  // r = 3 (5 个浅海)
  { q: -1, r: 3, terrain: 'shallow_water' as const },
  { q: 0, r: 3, terrain: 'shallow_water' as const },
  { q: 1, r: 3, terrain: 'shallow_water' as const },
  { q: 2, r: 3, terrain: 'shallow_water' as const },
  { q: 3, r: 3, terrain: 'shallow_water' as const },
]

export const NEW_WORLD_SCENARIO: ScenarioDef = {
  id: 'seafarers_new_world',
  name: '新世界',
  description: '海洋环抱的未知大陆，需要船只跨越海域开发黄金地形。胜利点门槛 13。',
  victoryPointThreshold: 13,
  expansion: 'seafarers',
  hexes: HEXES.map((h) => ({
    q: h.q,
    r: h.r,
    terrain: h.terrain,
  })),
}
