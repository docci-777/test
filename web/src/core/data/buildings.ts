import type { BuildingDef } from './types'

// 移植自 project/data/buildings.json
export const BUILDINGS: Record<string, BuildingDef> = {
  road: {
    id: 'road',
    name: '道路',
    cost: { wood: 1, brick: 1 },
    victoryPoints: 0,
    positionType: 'edge',
    terrainCategory: 'land',
    maxPerPlayer: 15,
  },
  ship: {
    id: 'ship',
    name: '船只',
    cost: { wood: 1, sheep: 1 },
    victoryPoints: 0,
    positionType: 'edge',
    terrainCategory: 'sea',
    maxPerPlayer: 15,
    expansion: 'seafarers',
    movable: true,
  },
  settlement: {
    id: 'settlement',
    name: '定居点',
    cost: { wood: 1, brick: 1, sheep: 1, wheat: 1 },
    victoryPoints: 1,
    positionType: 'vertex',
    terrainCategory: 'land',
    maxPerPlayer: 5,
    productionMultiplier: 1,
  },
  city: {
    id: 'city',
    name: '城市',
    cost: { wheat: 2, ore: 3 },
    victoryPoints: 2,
    positionType: 'vertex',
    terrainCategory: 'land',
    maxPerPlayer: 4,
    productionMultiplier: 2,
    upgradesFrom: 'settlement',
  },
  dev_card: {
    id: 'dev_card',
    name: '发展卡',
    cost: { sheep: 1, wheat: 1, ore: 1 },
    victoryPoints: 0,
    positionType: 'none',
    terrainCategory: 'none',
    maxPerPlayer: -1,
  },
}

export function getBuilding(id: string): BuildingDef | undefined {
  return BUILDINGS[id]
}

export function emptyResourceSet() {
  return { wood: 0, brick: 0, sheep: 0, wheat: 0, ore: 0 }
}
