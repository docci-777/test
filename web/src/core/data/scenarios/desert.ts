import type { ScenarioDef } from '@/core/data/types'

// 海洋扩展：深入沙漠
// 大片沙漠分隔岛屿，需建船跨越
// 胜利点门槛 12

const HEXES = [
  // r = -3 (5 个浅海)
  { q: -1, r: -3, terrain: 'shallow_water' as const },
  { q: 0, r: -3, terrain: 'shallow_water' as const },
  { q: 1, r: -3, terrain: 'shallow_water' as const },
  { q: 2, r: -3, terrain: 'shallow_water' as const },
  { q: 3, r: -3, terrain: 'shallow_water' as const },
  // r = -2 (6 个：左岛+沙漠+右岛)
  { q: -2, r: -2, terrain: 'shallow_water' as const },
  { q: -1, r: -2, terrain: 'mountains' as const },
  { q: 0, r: -2, terrain: 'forest' as const },
  { q: 1, r: -2, terrain: 'desert' as const },
  { q: 2, r: -2, terrain: 'pasture' as const },
  { q: 3, r: -2, terrain: 'shallow_water' as const },
  // r = -1 (7 个)
  { q: -2, r: -1, terrain: 'shallow_water' as const },
  { q: -1, r: -1, terrain: 'hills' as const },
  { q: 0, r: -1, terrain: 'fields' as const },
  { q: 1, r: -1, terrain: 'desert' as const },
  { q: 2, r: -1, terrain: 'forest' as const },
  { q: 3, r: -1, terrain: 'hills' as const },
  { q: 4, r: -1, terrain: 'shallow_water' as const },
  // r = 0 (7 个，中间含黄金)
  { q: -2, r: 0, terrain: 'shallow_water' as const },
  { q: -1, r: 0, terrain: 'pasture' as const },
  { q: 0, r: 0, terrain: 'desert' as const },
  { q: 1, r: 0, terrain: 'desert' as const },
  { q: 2, r: 0, terrain: 'desert' as const },
  { q: 3, r: 0, terrain: 'gold' as const },
  { q: 4, r: 0, terrain: 'shallow_water' as const },
  // r = 1 (7 个)
  { q: -2, r: 1, terrain: 'shallow_water' as const },
  { q: -1, r: 1, terrain: 'fields' as const },
  { q: 0, r: 1, terrain: 'mountains' as const },
  { q: 1, r: 1, terrain: 'desert' as const },
  { q: 2, r: 1, terrain: 'forest' as const },
  { q: 3, r: 1, terrain: 'pasture' as const },
  { q: 4, r: 1, terrain: 'shallow_water' as const },
  // r = 2 (6 个)
  { q: -2, r: 2, terrain: 'shallow_water' as const },
  { q: -1, r: 2, terrain: 'hills' as const },
  { q: 0, r: 2, terrain: 'gold' as const },
  { q: 1, r: 2, terrain: 'desert' as const },
  { q: 2, r: 2, terrain: 'fields' as const },
  { q: 3, r: 2, terrain: 'shallow_water' as const },
  // r = 3 (5 个浅海)
  { q: -1, r: 3, terrain: 'shallow_water' as const },
  { q: 0, r: 3, terrain: 'shallow_water' as const },
  { q: 1, r: 3, terrain: 'shallow_water' as const },
  { q: 2, r: 3, terrain: 'shallow_water' as const },
  { q: 3, r: 3, terrain: 'shallow_water' as const },
]

export const DESERT_SCENARIO: ScenarioDef = {
  id: 'seafarers_desert',
  name: '深入沙漠',
  description: '大片沙漠分隔岛屿，需建船跨越。胜利点门槛 12。',
  victoryPointThreshold: 12,
  expansion: 'seafarers',
  hexes: HEXES.map((h) => ({
    q: h.q,
    r: h.r,
    terrain: h.terrain,
  })),
}
