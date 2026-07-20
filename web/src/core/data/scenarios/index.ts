import type { ScenarioDef } from '@/core/data/types'
import { BASE_SCENARIO } from './base4p'
import { NEW_WORLD_SCENARIO } from './newWorld'
import { DESERT_SCENARIO } from './desert'

export const SCENARIOS: Record<string, ScenarioDef> = {
  [BASE_SCENARIO.id]: BASE_SCENARIO,
  [NEW_WORLD_SCENARIO.id]: NEW_WORLD_SCENARIO,
  [DESERT_SCENARIO.id]: DESERT_SCENARIO,
}

export const SCENARIO_LIST: ScenarioDef[] = [BASE_SCENARIO, NEW_WORLD_SCENARIO, DESERT_SCENARIO]

export function getScenario(id: string): ScenarioDef {
  return SCENARIOS[id] ?? BASE_SCENARIO
}
