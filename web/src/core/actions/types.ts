import type { BuildingType, DevCardType, ResourceType, ResourceSet } from '@/core/data/types'
import type { HexCoord } from '@/core/hexCoord'

export type DevCardPayload =
  | { kind: 'knight' }
  | { kind: 'road_building' }
  | { kind: 'year_of_plenty'; resources: ResourceType[] }
  | { kind: 'monopoly'; resource: ResourceType }
  | { kind: 'victory_point' }

export type GameAction =
  | { type: 'place_initial'; vertexId: number; edgeId: number }
  | { type: 'roll_dice' }
  | { type: 'build'; building: BuildingType; positionId: number }
  | { type: 'buy_dev_card' }
  | { type: 'use_dev_card'; cardId: number; payload: DevCardPayload }
  | { type: 'trade_bank'; give: ResourceSet; receive: ResourceType; portId?: string }
  | { type: 'trade_player'; targetPlayerId: string; give: ResourceSet; receive: ResourceSet }
  | { type: 'move_robber'; hexCoord: HexCoord; stealTargetPlayerId?: string }
  | { type: 'discard'; playerId: string; cards: ResourceSet }
  | { type: 'choose_gold'; playerId: string; resources: ResourceType[] }
  | { type: 'end_turn' }

export interface ActionResult {
  newState: unknown // 实际为 GameState，避免循环引用这里用 unknown
  events: GameEvent[]
}

export interface GameEvent {
  kind:
    | 'dice_rolled'
    | 'resources_produced'
    | 'building_built'
    | 'dev_card_bought'
    | 'dev_card_used'
    | 'trade_completed'
    | 'robber_moved'
    | 'resource_stolen'
    | 'cards_discarded'
    | 'longest_rood_changed'
    | 'largest_army_changed'
    | 'phase_changed'
    | 'turn_started'
    | 'victory'
    | 'info'
  payload: Record<string, unknown>
}
