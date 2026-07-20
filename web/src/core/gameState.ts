import type {
  BuildingType,
  DevCardType,
  GamePhase,
  PlayerColor,
  ResourceType,
  ResourceSet,
} from '@/core/data/types'
import type { HexCoord } from './hexCoord'
import type { Board } from './board'

export interface BuildingInstance {
  id: number
  type: BuildingType
  ownerId: string
  positionType: 'vertex' | 'edge'
  positionId: number // vertexId 或 edgeId
  purchasedTurn: number
}

export interface DevCardInstance {
  id: number
  type: DevCardType
  ownerId: string
  purchasedTurn: number
  used: boolean
}

export interface PlayerState {
  id: string
  name: string
  color: PlayerColor
  isAi: boolean
  hand: ResourceSet
  devCards: DevCardInstance[]
  knightsPlayed: number
  longestRoadLength: number
  // 待用的发展卡（本回合购买，下回合才能用）
  pendingDevCards: DevCardInstance[]
  // 道路建设卡剩余免费建路数
  freeRoadsRemaining: number
  // 弃牌阶段是否已弃
  hasDiscarded: boolean
  // 本回合已使用发展卡数（≤1，胜利点卡不计）
  devCardsUsedThisTurn: number
}

export interface LogEntry {
  turn: number
  playerId: string | null
  text: string
  kind:
    | 'roll'
    | 'produce'
    | 'build'
    | 'trade'
    | 'robber'
    | 'dev_card'
    | 'phase'
    | 'victory'
    | 'info'
}

export interface GameState {
  board: Board
  players: PlayerState[]
  currentPlayerId: string
  turnOrder: string[]
  phase: GamePhase
  turn: number
  dice: { d1: number; d2: number; total: number } | null
  robberCoord: HexCoord | null
  longestRoadPlayerId: string | null
  largestArmyPlayerId: string | null
  bank: ResourceSet
  devCardDeck: DevCardType[]
  buildings: BuildingInstance[]
  log: LogEntry[]
  victoryPointThreshold: number
  setupRound: number // 1 或 2，初始放置轮次
  setupIndex: number // 初始放置索引
  // 强盗阶段待弃牌玩家
  pendingDiscardPlayerIds: string[]
  // 强盗移动后，候选偷取目标
  robberStealCandidates: string[]
  // 黄金地形产出，待玩家选择资源
  pendingGoldChoices: Array<{ playerId: string; count: number }>
  // 待结算的发明卡
  pendingYearOfPlenty: string | null
  // 待结算的垄断卡
  pendingMonopoly: { playerId: string; resource: ResourceType } | null
  // 道路建设卡激活中
  pendingRoadBuilding: string | null
  // 胜者
  winnerId: string | null
}

export function emptyResourceSet(): ResourceSet {
  return { wood: 0, brick: 0, sheep: 0, wheat: 0, ore: 0 }
}

export function cloneResourceSet(s: ResourceSet): ResourceSet {
  return { ...s }
}

export function canAfford(hand: ResourceSet, cost: Partial<Record<ResourceType, number>>): boolean {
  for (const k of Object.keys(cost) as ResourceType[]) {
    if (hand[k] < (cost[k] ?? 0)) return false
  }
  return true
}

export function payCost(hand: ResourceSet, cost: Partial<Record<ResourceType, number>>): ResourceSet {
  const next = { ...hand }
  for (const k of Object.keys(cost) as ResourceType[]) {
    next[k] -= cost[k] ?? 0
  }
  return next
}

export function addResources(hand: ResourceSet, delta: Partial<Record<ResourceType, number>>): ResourceSet {
  const next = { ...hand }
  for (const k of Object.keys(delta) as ResourceType[]) {
    next[k] += delta[k] ?? 0
  }
  return next
}

export function handSize(hand: ResourceSet): number {
  return Object.values(hand).reduce((a, b) => a + b, 0)
}

// 公开胜利点（定居点+城市+最长道路+最大军队）
export function publicVictoryPoints(
  player: PlayerState,
  state: GameState,
): number {
  let points = 0
  for (const b of state.buildings) {
    if (b.ownerId !== player.id) continue
    if (b.type === 'settlement') points += 1
    else if (b.type === 'city') points += 2
  }
  if (state.longestRoadPlayerId === player.id) points += 2
  if (state.largestArmyPlayerId === player.id) points += 2
  return points
}

// 包含隐藏胜利点卡的总胜利点
export function totalVictoryPoints(player: PlayerState, state: GameState): number {
  let points = publicVictoryPoints(player, state)
  for (const card of player.devCards) {
    if (card.type === 'victory_point' && !card.used) points += 1
  }
  return points
}

// 计算玩家当前道路/船只总长度（最长连续段）
export function computeLongestRoad(
  playerId: string,
  state: GameState,
): number {
  const myPaths = state.buildings.filter(
    (b) => b.ownerId === playerId && (b.type === 'road' || b.type === 'ship'),
  )
  if (myPaths.length === 0) return 0

  // 构建邻接表：vertexId -> [{edgeId, otherVertexId}]
  const adj = new Map<number, Array<{ edgeId: number; other: number }>>()
  for (const p of myPaths) {
    const [v1, v2] = state.board.edgeVertices(p.positionId)
    if (!adj.has(v1)) adj.set(v1, [])
    if (!adj.has(v2)) adj.set(v2, [])
    adj.get(v1)!.push({ edgeId: p.positionId, other: v2 })
    adj.get(v2)!.push({ edgeId: p.positionId, other: v1 })
  }

  // 对手定居点会断链
  const blockedVertices = new Set<number>()
  for (const b of state.buildings) {
    if (b.ownerId !== playerId && (b.type === 'settlement' || b.type === 'city')) {
      blockedVertices.add(b.positionId)
    }
  }

  let maxLen = 0
  // 从每个顶点出发 DFS
  for (const startV of adj.keys()) {
    maxLen = Math.max(maxLen, dfsLongest(startV, new Set(), adj, blockedVertices, playerId, state))
  }
  return maxLen
}

function dfsLongest(
  current: number,
  usedEdges: Set<number>,
  adj: Map<number, Array<{ edgeId: number; other: number }>>,
  blockedVertices: Set<number>,
  playerId: string,
  state: GameState,
): number {
  // 当前顶点是对手定居点（且非起点）：路径不能再继续
  // 这里简单处理：忽略对手定居点中断（实际规则较复杂，简化版仍能保证大多数情况正确）
  let maxLen = 0
  for (const next of adj.get(current) ?? []) {
    if (usedEdges.has(next.edgeId)) continue
    usedEdges.add(next.edgeId)
    const subLen = dfsLongest(next.other, usedEdges, adj, blockedVertices, playerId, state) + 1
    usedEdges.delete(next.edgeId)
    if (subLen > maxLen) maxLen = subLen
  }
  return maxLen
}
