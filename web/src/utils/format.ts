import type { ResourceType, BuildingType } from '@/core/data/types'
import { RESOURCE_INFO, BUILDING_INFO } from '@/utils/colors'

const RESOURCE_ORDER: ResourceType[] = ['wood', 'brick', 'sheep', 'wheat', 'ore']

export function formatResourceSet(set: Partial<Record<ResourceType, number>>): string {
  return RESOURCE_ORDER.map((r) => `${set[r] ?? 0}${RESOURCE_INFO[r].name}`).join(' · ')
}

export function formatResourceShort(r: ResourceType): string {
  return RESOURCE_INFO[r].name
}

export function formatBuilding(b: BuildingType): string {
  return BUILDING_INFO[b].name
}

export function formatPoints(points: number): string {
  return `${points} VP`
}

export function formatNumber(n: number): string {
  return n.toString()
}
