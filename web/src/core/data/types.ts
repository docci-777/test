// L1 核心层公共类型定义

export type ResourceType = 'wood' | 'brick' | 'sheep' | 'wheat' | 'ore'
export type ResourceSet = Record<ResourceType, number>

export type TerrainId =
  | 'mountains'
  | 'hills'
  | 'forest'
  | 'fields'
  | 'pasture'
  | 'desert'
  | 'gold'
  | 'shallow_water'
  | 'deep_water'

export type TerrainCategory = 'land' | 'sea'

export interface TerrainDef {
  id: TerrainId
  name: string
  resource: ResourceType | 'any' | null
  countBase: number
  buildable: boolean
  robberBlocks: boolean
  category: TerrainCategory
  expansion?: 'seafarers'
  shipBuildable?: boolean
}

export type BuildingType = 'road' | 'ship' | 'settlement' | 'city' | 'dev_card'
export type PositionType = 'edge' | 'vertex' | 'none'

export interface BuildingDef {
  id: BuildingType
  name: string
  cost: Partial<Record<ResourceType, number>>
  victoryPoints: number
  positionType: PositionType
  terrainCategory: TerrainCategory | 'none'
  maxPerPlayer: number
  productionMultiplier?: number
  upgradesFrom?: BuildingType
  expansion?: 'seafarers'
  movable?: boolean
}

export type DevCardType =
  | 'knight'
  | 'victory_point'
  | 'road_building'
  | 'year_of_plenty'
  | 'monopoly'

export interface DevCardDef {
  id: DevCardType
  name: string
  count: number
  victoryPoints: number
  usableSameTurn: boolean
  effect: string
  hidden?: boolean
  countsForLargestArmy: boolean
}

export type PortId =
  | 'generic_3to1'
  | 'wood_2to1'
  | 'brick_2to1'
  | 'sheep_2to1'
  | 'wheat_2to1'
  | 'ore_2to1'

export interface PortDef {
  id: PortId
  name: string
  tradeRatio: string
  giveCount: number
  receiveCount: number
  resource: ResourceType | null
  countBase: number
}

export type PlayerColor = 'red' | 'blue' | 'white' | 'orange'

export type GamePhase =
  | 'setup_forward'
  | 'setup_reverse'
  | 'roll'
  | 'action'
  | 'robber_discard'
  | 'robber_move'
  | 'robber_steal'
  | 'game_over'

// 场景布局定义
export interface ScenarioHex {
  q: number
  r: number
  terrain: TerrainId
  // numberToken 仅陆地非沙漠需要；海域/沙漠/黄金不需要
  numberToken?: number
  // 标记为初始未发现（新世界场景）
  hidden?: boolean
}

export interface ScenarioPort {
  // 港口所在的两个顶点物理坐标（hexKey + dir 描述）
  // 简化：直接给定两个相邻顶点物理坐标的规范键
  vertexKey1: string
  vertexKey2: string
  portId: PortId
}

export interface ScenarioDef {
  id: string
  name: string
  description: string
  victoryPointThreshold: number
  hexes: ScenarioHex[]
  // 港口列表，可空（基础版会自动生成）
  ports?: ScenarioPort[]
  // 海洋扩展相关
  expansion?: 'seafarers'
}
