import type { TerrainDef } from './types'

// 移植自 project/data/terrains.json
export const TERRAINS: Record<string, TerrainDef> = {
  mountains: {
    id: 'mountains',
    name: '山脉',
    resource: 'ore',
    countBase: 4,
    buildable: true,
    robberBlocks: true,
    category: 'land',
  },
  hills: {
    id: 'hills',
    name: '丘陵',
    resource: 'brick',
    countBase: 3,
    buildable: true,
    robberBlocks: true,
    category: 'land',
  },
  forest: {
    id: 'forest',
    name: '森林',
    resource: 'wood',
    countBase: 4,
    buildable: true,
    robberBlocks: true,
    category: 'land',
  },
  fields: {
    id: 'fields',
    name: '麦田',
    resource: 'wheat',
    countBase: 4,
    buildable: true,
    robberBlocks: true,
    category: 'land',
  },
  pasture: {
    id: 'pasture',
    name: '牧场',
    resource: 'sheep',
    countBase: 4,
    buildable: true,
    robberBlocks: true,
    category: 'land',
  },
  desert: {
    id: 'desert',
    name: '沙漠',
    resource: null,
    countBase: 1,
    buildable: true,
    robberBlocks: true,
    category: 'land',
  },
  gold: {
    id: 'gold',
    name: '黄金地形',
    resource: 'any',
    countBase: 0,
    buildable: true,
    robberBlocks: true,
    category: 'land',
    expansion: 'seafarers',
  },
  shallow_water: {
    id: 'shallow_water',
    name: '浅海',
    resource: null,
    countBase: 0,
    buildable: true,
    robberBlocks: false,
    category: 'sea',
    expansion: 'seafarers',
    shipBuildable: true,
  },
  deep_water: {
    id: 'deep_water',
    name: '深海',
    resource: null,
    countBase: 0,
    buildable: false,
    robberBlocks: false,
    category: 'sea',
    expansion: 'seafarers',
    shipBuildable: false,
  },
}

export function getTerrain(id: string): TerrainDef | undefined {
  return TERRAINS[id]
}

export function isLandTerrain(t: TerrainDef): boolean {
  return t.category === 'land'
}

export function isSeaTerrain(t: TerrainDef): boolean {
  return t.category === 'sea'
}

export function isProductionTerrain(t: TerrainDef): boolean {
  return t.category === 'land' && t.resource !== null && t.id !== 'desert'
}
