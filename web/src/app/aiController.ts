import type { GameState } from '@/core/gameState'
import type { GameAction } from '@/core/actions/types'
import { validate } from '@/core/rulesEngine'
import { BUILDINGS } from '@/core/data/buildings'
import { TERRAINS, isProductionTerrain } from '@/core/data/terrains'
import { PORTS } from '@/core/data/ports'
import type { ResourceType, BuildingType } from '@/core/data/types'
import { HexCoord } from '@/core/hexCoord'

// AI 决策：根据当前状态生成下一个动作
// 中等策略：
// 1. 初始放置：选最高产出概率的顶点 + 连接边
// 2. 掷骰阶段：直接掷
// 3. 行动阶段：按优先级建造（定居点 > 城市 > 发展卡 > 道路 > 船只）
// 4. 强盗阶段：移动到对手高产出地形，偷资源最多者
// 5. 弃牌：保留高价值资源
export function decideAiAction(state: GameState, playerId: string): GameAction | null {
  const player = state.players.find((p) => p.id === playerId)
  if (!player) return null

  switch (state.phase) {
    case 'setup_forward':
    case 'setup_reverse':
      return decideInitialPlacement(state, player.id)
    case 'roll':
      return { type: 'roll_dice' }
    case 'action':
      return decideActionPhase(state, player.id)
    case 'robber_discard':
      if (state.pendingDiscardPlayerIds.includes(player.id)) {
        return decideDiscard(state, player.id)
      }
      return null
    case 'robber_move':
      return decideRobberMove(state, player.id)
    case 'game_over':
      return null
    default:
      return null
  }
}

function decideInitialPlacement(state: GameState, playerId: string): GameAction | null {
  const board = state.board
  // 评分每个可放定居点的顶点
  const candidates: Array<{ vertexId: number; score: number; edgeId: number }> = []
  for (const v of board.allVertices()) {
    const action = { type: 'place_initial' as const, vertexId: v.id, edgeId: -1 }
    // 找一个相邻的陆地边
    const edges = board.vertexEdges(v.id)
    let chosenEdge = -1
    for (const eid of edges) {
      const eHexes = board.edgeHexes(eid)
      const isLandEdge = eHexes.some((c) => {
        const h = board.getHex(c)
        return h && TERRAINS[h.terrainId].category === 'land'
      })
      if (isLandEdge) {
        // 临时校验
        const tryAction = { type: 'place_initial' as const, vertexId: v.id, edgeId: eid }
        const r = validate(tryAction, state, playerId)
        if (r.ok) {
          chosenEdge = eid
          break
        }
      }
    }
    if (chosenEdge === -1) continue
    // 评分：相邻六边形产出概率 × 玩家稀缺度
    let score = 0
    const vHexes = board.vertexHexes(v.id)
    for (const c of vHexes) {
      const h = board.getHex(c)
      if (!h) continue
      const terrain = TERRAINS[h.terrainId]
      if (!isProductionTerrain(terrain)) continue
      // 概率点：2/12=1, 3/11=2, 4/10=3, 5/9=4, 6/8=5
      const dots = NUMBER_DOTS[h.numberToken] ?? 0
      score += dots
    }
    candidates.push({ vertexId: v.id, score, edgeId: chosenEdge })
  }
  if (candidates.length === 0) return null
  candidates.sort((a, b) => b.score - a.score)
  const top = candidates[0]
  return { type: 'place_initial', vertexId: top.vertexId, edgeId: top.edgeId }
}

const NUMBER_DOTS: Record<number, number> = {
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

function decideActionPhase(state: GameState, playerId: string): GameAction | null {
  const player = state.players.find((p) => p.id === playerId)!
  const board = state.board

  // 1. 若已购买道路建设卡且可用，先用
  // 简化：略

  // 2. 优先升级城市（若已有定居点且能升级）
  if (canAfford(player.hand, BUILDINGS.city.cost)) {
    const mySettlements = state.buildings.filter(
      (b) => b.ownerId === playerId && b.type === 'settlement',
    )
    if (mySettlements.length > 0) {
      return { type: 'build', building: 'city', positionId: mySettlements[0].positionId }
    }
  }

  // 3. 建定居点
  if (canAfford(player.hand, BUILDINGS.settlement.cost)) {
    const spot = findBestSettlementSpot(state, playerId)
    if (spot >= 0) return { type: 'build', building: 'settlement', positionId: spot }
  }

  // 4. 买发展卡
  if (canAfford(player.hand, BUILDINGS.dev_card.cost) && state.devCardDeck.length > 0) {
    // 70% 概率买
    if (Math.random() < 0.7) return { type: 'buy_dev_card' }
  }

  // 5. 建道路
  if (canAfford(player.hand, BUILDINGS.road.cost)) {
    const spot = findBestRoadSpot(state, playerId, 'road')
    if (spot >= 0) return { type: 'build', building: 'road', positionId: spot }
  }

  // 6. 建船只（海洋扩展）
  if (canAfford(player.hand, BUILDINGS.ship.cost)) {
    const spot = findBestRoadSpot(state, playerId, 'ship')
    if (spot >= 0) return { type: 'build', building: 'ship', positionId: spot }
  }

  // 7. 4:1 与银行交易，若可凑齐关键建造
  // 简化：跳过

  // 8. 结束回合
  return { type: 'end_turn' }
}

function decideDiscard(state: GameState, playerId: string): GameAction | null {
  const player = state.players.find((p) => p.id === playerId)!
  const total = Object.values(player.hand).reduce((a, b) => a + b, 0)
  const required = Math.floor(total / 2)
  // 优先弃矿石/羊毛等冗余资源
  const priority: ResourceType[] = ['ore', 'sheep', 'wheat', 'brick', 'wood']
  const cards: Record<ResourceType, number> = {
    wood: 0,
    brick: 0,
    sheep: 0,
    wheat: 0,
    ore: 0,
  }
  let remaining = required
  for (const r of priority) {
    if (remaining === 0) break
    const take = Math.min(player.hand[r], remaining)
    cards[r] = take
    remaining -= take
  }
  return { type: 'discard', playerId, cards }
}

function decideRobberMove(state: GameState, playerId: string): GameAction | null {
  const board = state.board
  // 找一个能压制对手高产出且能偷到资源的位置
  let best: { coord: HexCoord; stealTarget?: string; score: number } | null = null
  for (const cell of board.allHexes()) {
    const terrain = TERRAINS[cell.terrainId]
    if (!terrain.robberBlocks) continue
    if (state.robberCoord && state.robberCoord.equals(cell.coord)) continue
    // 该六边形相邻定居点/城市
    const vertexIds = board.vertexHexesByHex(cell.coord)
    let score = NUMBER_DOTS[cell.numberToken] ?? 0
    const stealCandidates: string[] = []
    for (const vid of vertexIds) {
      const b = state.buildings.find((x) => x.positionType === 'vertex' && x.positionId === vid)
      if (!b || b.ownerId === playerId) continue
      score += 5
      stealCandidates.push(b.ownerId)
    }
    // 偷取目标：资源最多者
    let stealTarget: string | undefined
    if (stealCandidates.length > 0) {
      stealCandidates.sort((a, b) => {
        const pa = state.players.find((p) => p.id === a)!
        const pb = state.players.find((p) => p.id === b)!
        return (
          Object.values(pb.hand).reduce((x, y) => x + y, 0) -
          Object.values(pa.hand).reduce((x, y) => x + y, 0)
        )
      })
      stealTarget = stealCandidates[0]
    }
    if (!best || score > best.score) {
      best = { coord: new HexCoord(cell.coord.q, cell.coord.r), stealTarget, score }
    }
  }
  if (!best) return null
  return {
    type: 'move_robber',
    hexCoord: best.coord,
    stealTargetPlayerId: best.stealTarget,
  }
}

function findBestSettlementSpot(state: GameState, playerId: string): number {
  const board = state.board
  let best: { vertexId: number; score: number } | null = null
  for (const v of board.allVertices()) {
    const action = { type: 'build' as const, building: 'settlement' as BuildingType, positionId: v.id }
    const r = validate(action, state, playerId)
    if (!r.ok) continue
    let score = 0
    const vHexes = board.vertexHexes(v.id)
    for (const c of vHexes) {
      const h = board.getHex(c)
      if (!h) continue
      const terrain = TERRAINS[h.terrainId]
      if (!isProductionTerrain(terrain)) continue
      score += NUMBER_DOTS[h.numberToken] ?? 0
    }
    // 港口加分
    if (board.getPort(v.id)) score += 2
    if (!best || score > best.score) best = { vertexId: v.id, score }
  }
  return best?.vertexId ?? -1
}

function findBestRoadSpot(
  state: GameState,
  playerId: string,
  building: 'road' | 'ship',
): number {
  const board = state.board
  // 找一个能扩展到自己有产出潜力顶点的边
  let best: { edgeId: number; score: number } | null = null
  for (const e of board.allEdges()) {
    const action = { type: 'build' as const, building, positionId: e.id }
    const r = validate(action, state, playerId)
    if (!r.ok) continue
    let score = 1
    // 评估该边两端顶点未来作为定居点的潜力
    const [v1, v2] = board.edgeVertices(e.id)
    for (const vid of [v1, v2]) {
      // 该顶点是否还能放定居点
      const occupied = state.buildings.some(
        (b) => b.positionType === 'vertex' && b.positionId === vid,
      )
      if (occupied) continue
      // 距离规则
      const tooClose = state.buildings.some(
        (b) => b.positionType === 'vertex' && board.vertexDistance(b.positionId, vid) < 2,
      )
      if (tooClose) continue
      const vHexes = board.vertexHexes(vid)
      for (const c of vHexes) {
        const h = board.getHex(c)
        if (!h) continue
        const terrain = TERRAINS[h.terrainId]
        if (!isProductionTerrain(terrain)) continue
        score += NUMBER_DOTS[h.numberToken] ?? 0
      }
    }
    if (!best || score > best.score) best = { edgeId: e.id, score }
  }
  return best?.edgeId ?? -1
}

function canAfford(
  hand: Record<ResourceType, number>,
  cost: Partial<Record<ResourceType, number>>,
): boolean {
  for (const k of Object.keys(cost) as ResourceType[]) {
    if (hand[k] < (cost[k] ?? 0)) return false
  }
  return true
}
