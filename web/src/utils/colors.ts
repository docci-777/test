import type { PlayerColor, ResourceType, TerrainId, BuildingType } from '@/core/data/types'

// 玩家颜色
export const PLAYER_COLORS: PlayerColor[] = ['red', 'blue', 'white', 'orange']

export const PLAYER_COLOR_HEX: Record<PlayerColor, { main: string; dark: string; text: string }> = {
  red: { main: '#c4421f', dark: '#7a2810', text: '#fff5e6' },
  blue: { main: '#2b6cb0', dark: '#173f6b', text: '#f0f6ff' },
  white: { main: '#e8e2d5', dark: '#a8a08a', text: '#2b1810' },
  orange: { main: '#dd7e2c', dark: '#8e4a10', text: '#fff5e6' },
}

export const PLAYER_NAMES: Record<PlayerColor, string> = {
  red: '红队',
  blue: '蓝队',
  white: '白队',
  orange: '橙队',
}

// 资源
export const RESOURCE_TYPES: ResourceType[] = ['wood', 'brick', 'sheep', 'wheat', 'ore']

export const RESOURCE_INFO: Record<
  ResourceType,
  { name: string; color: string; icon: string; terrain: TerrainId }
> = {
  wood: { name: '木材', color: '#2d5a3d', icon: '🌲', terrain: 'forest' },
  brick: { name: '砖块', color: '#b86b3a', icon: '🧱', terrain: 'hills' },
  sheep: { name: '羊毛', color: '#8fbf5e', icon: '🐑', terrain: 'pasture' },
  wheat: { name: '麦子', color: '#d4a23a', icon: '🌾', terrain: 'fields' },
  ore: { name: '矿石', color: '#5a5d5f', icon: '⛏', terrain: 'mountains' },
}

// 地形
export const TERRAIN_INFO: Record<
  TerrainId,
  { name: string; color: string; icon: string; resource: ResourceType | null }
> = {
  mountains: { name: '山脉', color: '#8a8d8f', icon: '⛰', resource: 'ore' },
  hills: { name: '丘陵', color: '#b86b3a', icon: '🪨', resource: 'brick' },
  forest: { name: '森林', color: '#2d5a3d', icon: '🌲', resource: 'wood' },
  fields: { name: '麦田', color: '#d4a23a', icon: '🌾', resource: 'wheat' },
  pasture: { name: '牧场', color: '#8fbf5e', icon: '🐑', resource: 'sheep' },
  desert: { name: '沙漠', color: '#e6c878', icon: '🏜', resource: null },
  gold: { name: '黄金地形', color: '#e6b840', icon: '💰', resource: null },
  shallow_water: { name: '浅海', color: '#3a6a8f', icon: '🌊', resource: null },
  deep_water: { name: '深海', color: '#1e3a5f', icon: '🌊', resource: null },
}

// 建筑图标
export const BUILDING_INFO: Record<BuildingType, { name: string; icon: string }> = {
  road: { name: '道路', icon: '🛣' },
  ship: { name: '船只', icon: '⛵' },
  settlement: { name: '定居点', icon: '🏠' },
  city: { name: '城市', icon: '🏛' },
  dev_card: { name: '发展卡', icon: '📜' },
}

// 数字牌概率点（每个数字出现的概率，用点数表示）
export const NUMBER_DOTS: Record<number, number> = {
  2: 1,
  3: 2,
  4: 3,
  5: 4,
  6: 5,
  8: 5,
  9: 4,
  10: 3,
  11: 2,
  12: 1,
}

export function isRedNumber(n: number): boolean {
  return n === 6 || n === 8
}

// 港口图标
export const PORT_ICON: Record<string, string> = {
  generic_3to1: '⚓',
  wood_2to1: '🌲',
  brick_2to1: '🧱',
  sheep_2to1: '🐑',
  wheat_2to1: '🌾',
  ore_2to1: '⛏',
}
