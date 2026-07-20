import { Board, type HexCell } from './board'
import { HexCoord } from './hexCoord'
import { type GameAction, type GameEvent, type DevCardPayload } from './actions/types'
import {
  type GameState,
  type PlayerState,
  type BuildingInstance,
  type DevCardInstance,
  type LogEntry,
  emptyResourceSet,
  cloneResourceSet,
  canAfford,
  payCost,
  addResources,
  handSize,
  publicVictoryPoints,
  totalVictoryPoints,
  computeLongestRoad,
} from './gameState'
import { ok, err, type Result, isErr, isOk } from './result'
import { Rng } from './rng'
import { BUILDINGS, getBuilding } from './data/buildings'
import { TERRAINS, isLandTerrain, isSeaTerrain, isProductionTerrain } from './data/terrains'
import { DEV_CARDS, TOTAL_DEV_CARDS } from './data/devCards'
import { PORTS } from './data/ports'
import type {
  BuildingType,
  DevCardType,
  ResourceType,
  ResourceSet,
  TerrainId,
  PortId,
} from './data/types'

// ============ 校验 ============

export function validate(
  action: GameAction,
  state: GameState,
  playerId: string,
): Result<void> {
  const player = state.players.find((p) => p.id === playerId)
  if (!player) return err('player_not_found', '玩家不存在')

  switch (action.type) {
    case 'place_initial':
      return validatePlaceInitial(action, state, player)
    case 'roll_dice':
      return validateRollDice(state, player)
    case 'build':
      return validateBuild(action, state, player)
    case 'buy_dev_card':
      return validateBuyDevCard(state, player)
    case 'use_dev_card':
      return validateUseDevCard(action, state, player)
    case 'trade_bank':
      return validateTradeBank(action, state, player)
    case 'trade_player':
      return validateTradePlayer(action, state, player)
    case 'move_robber':
      return validateMoveRobber(action, state, player)
    case 'discard':
      return validateDiscard(action, state, player)
    case 'choose_gold':
      return validateChooseGold(action, state, player)
    case 'end_turn':
      return validateEndTurn(state, player)
  }
}

function validatePlaceInitial(
  action: { vertexId: number; edgeId: number },
  state: GameState,
  player: PlayerState,
): Result<void> {
  if (state.phase !== 'setup_forward' && state.phase !== 'setup_reverse') {
    return err('wrong_phase', '当前不在初始放置阶段')
  }
  if (state.currentPlayerId !== player.id) {
    return err('not_your_turn', '当前不是你的回合')
  }
  const board = state.board
  const vertex = board.getVertex(action.vertexId)
  if (!vertex) return err('bad_vertex', '顶点不存在')
  const edge = board.getEdge(action.edgeId)
  if (!edge) return err('bad_edge', '边不存在')

  // 顶点必须属于至少一个陆地六边形
  const vertexHexes = board.vertexHexes(action.vertexId)
  if (vertexHexes.length === 0) return err('bad_vertex', '顶点不在六边形上')
  const landHexes = vertexHexes.filter((c) => {
    const h = board.getHex(c)
    return h && isLandTerrain(TERRAINS[h.terrainId])
  })
  if (landHexes.length === 0) return err('bad_vertex', '定居点必须建在陆地')

  // 距离规则：与任意已有定居点/城市至少相距 2 条边
  for (const b of state.buildings) {
    if (b.positionType !== 'vertex') continue
    const dist = board.vertexDistance(b.positionId, action.vertexId)
    if (dist >= 0 && dist < 2) {
      return err('distance_rule', '定居点必须距已有定居点至少 2 条边')
    }
  }

  // 顶点不可已有建筑
  if (state.buildings.some((b) => b.positionType === 'vertex' && b.positionId === action.vertexId)) {
    return err('occupied', '该位置已有建筑')
  }

  // 边必须连接到该顶点
  const [ev1, ev2] = board.edgeVertices(action.edgeId)
  if (ev1 !== action.vertexId && ev2 !== action.vertexId) {
    return err('bad_edge', '道路必须连接到刚放置的定居点')
  }

  // 边必须建在陆地（基础版），海洋扩展可建船但初始放置不要求
  const edgeHexes = board.edgeHexes(action.edgeId)
  const isLandEdge = edgeHexes.some((c) => {
    const h = board.getHex(c)
    return h && isLandTerrain(TERRAINS[h.terrainId])
  })
  if (!isLandEdge) {
    return err('bad_edge', '初始道路必须建在陆地')
  }

  // 边不可被占用
  if (state.buildings.some((b) => b.positionType === 'edge' && b.positionId === action.edgeId)) {
    return err('occupied', '该边已有道路')
  }
  return ok(undefined)
}

function validateRollDice(state: GameState, player: PlayerState): Result<void> {
  if (state.phase !== 'roll') return err('wrong_phase', '当前不在掷骰阶段')
  if (state.currentPlayerId !== player.id) return err('not_your_turn', '当前不是你的回合')
  return ok(undefined)
}

function validateBuild(
  action: { building: BuildingType; positionId: number },
  state: GameState,
  player: PlayerState,
): Result<void> {
  if (state.phase !== 'action' && state.phase !== 'setup_forward' && state.phase !== 'setup_reverse') {
    return err('wrong_phase', '当前不在可建造阶段')
  }
  if (state.phase === 'action' && state.currentPlayerId !== player.id) {
    return err('not_your_turn', '当前不是你的回合')
  }
  // 道路建设卡免费建路：不消耗资源
  const isFreeRoad =
    action.building === 'road' &&
    player.freeRoadsRemaining > 0 &&
    state.pendingRoadBuilding === player.id
  const def = getBuilding(action.building)
  if (!def) return err('bad_building', '建筑类型不存在')

  // 资源检查
  if (!isFreeRoad) {
    if (!canAfford(player.hand, def.cost)) {
      return err('insufficient_resources', `资源不足，无法建造${def.name}`)
    }
  }

  // 数量限制
  if (def.maxPerPlayer > 0) {
    const count = state.buildings.filter(
      (b) => b.ownerId === player.id && b.type === action.building,
    ).length
    if (count >= def.maxPerPlayer) {
      return err('max_reached', `${def.name}已达上限`)
    }
  }

  // 位置校验
  if (def.positionType === 'vertex') {
    const v = state.board.getVertex(action.positionId)
    if (!v) return err('bad_position', '顶点不存在')
    if (action.building === 'settlement') {
      // 距离规则
      for (const b of state.buildings) {
        if (b.positionType !== 'vertex') continue
        const dist = state.board.vertexDistance(b.positionId, action.positionId)
        if (dist >= 0 && dist < 2) return err('distance_rule', '定居点必须距已有定居点至少 2 条边')
      }
      // 必须连接到自己道路网络
      const connected = isVertexConnectedToPlayerNetwork(action.positionId, player.id, state)
      if (state.phase === 'action' && !connected) {
        return err('not_connected', '定居点必须连接到自己的道路网络')
      }
      // 顶点不可有建筑
      if (state.buildings.some((b) => b.positionType === 'vertex' && b.positionId === action.positionId)) {
        return err('occupied', '该位置已有建筑')
      }
      // 顶点必须有相邻陆地
      const vHexes = state.board.vertexHexes(action.positionId)
      const hasLand = vHexes.some((c) => {
        const h = state.board.getHex(c)
        return h && isLandTerrain(TERRAINS[h.terrainId])
      })
      if (!hasLand) return err('bad_position', '定居点必须建在陆地')
    } else if (action.building === 'city') {
      // 必须升级自己的定居点
      const existing = state.buildings.find(
        (b) =>
          b.ownerId === player.id &&
          b.type === 'settlement' &&
          b.positionId === action.positionId,
      )
      if (!existing) return err('no_settlement', '只能升级自己的定居点为城市')
    }
  } else if (def.positionType === 'edge') {
    const e = state.board.getEdge(action.positionId)
    if (!e) return err('bad_position', '边不存在')
    // 边不可被占用
    if (state.buildings.some((b) => b.positionType === 'edge' && b.positionId === action.positionId)) {
      return err('occupied', '该边已有建筑')
    }
    if (action.building === 'road') {
      // 至少一个相邻六边形是陆地
      const eHexes = state.board.edgeHexes(action.positionId)
      const hasLand = eHexes.some((c) => {
        const h = state.board.getHex(c)
        return h && isLandTerrain(TERRAINS[h.terrainId])
      })
      if (!hasLand) return err('bad_position', '道路必须建在陆地')
      // 必须连接到自己道路网络/定居点/城市
      if (state.phase === 'action') {
        const connected = isEdgeConnectedToPlayerNetwork(action.positionId, player.id, state, 'road')
        if (!connected) return err('not_connected', '道路必须连接到自己的网络')
      } else if (state.phase === 'setup_forward' || state.phase === 'setup_reverse') {
        // 初始放置时由 place_initial 校验，这里走不到
      }
    } else if (action.building === 'ship') {
      // 至少一个相邻六边形是浅海
      const eHexes = state.board.edgeHexes(action.positionId)
      const hasShallow = eHexes.some((c) => {
        const h = state.board.getHex(c)
        return h && h.terrainId === 'shallow_water'
      })
      if (!hasShallow) return err('bad_position', '船只必须建在浅海')
      if (state.phase === 'action') {
        const connected = isEdgeConnectedToPlayerNetwork(action.positionId, player.id, state, 'ship')
        if (!connected) return err('not_connected', '船只必须连接到自己的网络')
      }
    }
  }
  return ok(undefined)
}

function validateBuyDevCard(state: GameState, player: PlayerState): Result<void> {
  if (state.phase !== 'action') return err('wrong_phase', '当前不在行动阶段')
  if (state.currentPlayerId !== player.id) return err('not_your_turn', '当前不是你的回合')
  if (state.devCardDeck.length === 0) return err('empty_deck', '发展卡牌堆已空')
  const def = BUILDINGS.dev_card
  if (!canAfford(player.hand, def.cost)) {
    return err('insufficient_resources', '资源不足，无法购买发展卡')
  }
  return ok(undefined)
}

function validateUseDevCard(
  action: { cardId: number; payload: DevCardPayload },
  state: GameState,
  player: PlayerState,
): Result<void> {
  if (state.phase !== 'action') return err('wrong_phase', '当前不在行动阶段')
  if (state.currentPlayerId !== player.id) return err('not_your_turn', '当前不是你的回合')
  const card = player.devCards.find((c) => c.id === action.cardId)
  if (!card) return err('bad_card', '卡牌不存在')
  if (card.used) return err('card_used', '卡牌已使用')
  // 购买当回合不可用（胜利点卡除外）
  if (card.purchasedTurn === state.turn && card.type !== 'victory_point') {
    return err('same_turn', '购买当回合不可使用')
  }
  // 每回合最多 1 张
  if (player.devCardsUsedThisTurn >= 1 && card.type !== 'victory_point') {
    return err('one_per_turn', '每回合最多使用 1 张发展卡')
  }
  // 卡类型与 payload 一致
  if (action.payload.kind !== card.type) {
    return err('payload_mismatch', '卡牌类型与 payload 不匹配')
  }
  // 道路建设卡：必须能合法建造（至少 1 条）
  if (card.type === 'road_building') {
    // 这里允许使用，使用时若不能建造则只剩免费次数无效
  }
  return ok(undefined)
}

function validateTradeBank(
  action: { give: ResourceSet; receive: ResourceType; portId?: string },
  state: GameState,
  player: PlayerState,
): Result<void> {
  if (state.phase !== 'action') return err('wrong_phase', '当前不在行动阶段')
  if (state.currentPlayerId !== player.id) return err('not_your_turn', '当前不是你的回合')
  const giveResources = Object.entries(action.give).filter(([, v]) => v > 0) as Array<[ResourceType, number]>
  if (giveResources.length !== 1) {
    return err('bad_trade', '与银行交易必须给出 1 种资源')
  }
  const [res, count] = giveResources[0]
  if (count <= 0) return err('bad_trade', '交易数量必须 > 0')

  let requiredCount = 4 // 默认 4:1
  if (action.portId) {
    const port = PORTS[action.portId as PortId]
    if (!port) return err('bad_port', '港口不存在')
    // 玩家必须在港口建有定居点/城市
    const portVertex = findPortVertexForPlayer(state, player.id, action.portId)
    if (portVertex === -1) {
      return err('no_port_access', '你未占有该港口')
    }
    if (port.resource !== null && port.resource !== res) {
      return err('bad_port', '该港口不接受此资源')
    }
    requiredCount = port.giveCount
  }
  if (count !== requiredCount) {
    return err('bad_trade', `必须给出 ${requiredCount} 张同类资源`)
  }
  if (player.hand[res] < count) return err('insufficient_resources', '资源不足')
  if (state.bank[action.receive] <= 0) return err('bank_empty', '银行此资源已空')
  return ok(undefined)
}

function validateTradePlayer(
  action: { targetPlayerId: string; give: ResourceSet; receive: ResourceSet },
  state: GameState,
  player: PlayerState,
): Result<void> {
  if (state.phase !== 'action') return err('wrong_phase', '当前不在行动阶段')
  if (state.currentPlayerId !== player.id) return err('not_your_turn', '当前不是你的回合')
  const target = state.players.find((p) => p.id === action.targetPlayerId)
  if (!target) return err('bad_target', '目标玩家不存在')
  if (target.id === player.id) return err('bad_target', '不能与自己交易')
  // 双方资源检查
  for (const r of Object.keys(action.give) as ResourceType[]) {
    if (player.hand[r] < action.give[r]) return err('insufficient_resources', '你资源不足')
  }
  for (const r of Object.keys(action.receive) as ResourceType[]) {
    if (target.hand[r] < action.receive[r]) return err('target_insufficient', '对方资源不足')
  }
  // 至少有一方给出非 0
  const giveTotal = Object.values(action.give).reduce((a, b) => a + b, 0)
  const recvTotal = Object.values(action.receive).reduce((a, b) => a + b, 0)
  if (giveTotal === 0 || recvTotal === 0) return err('bad_trade', '交易内容无效')
  return ok(undefined)
}

function validateMoveRobber(
  action: { hexCoord: HexCoord; stealTargetPlayerId?: string },
  state: GameState,
  player: PlayerState,
): Result<void> {
  if (state.phase !== 'robber_move' && state.phase !== 'action') {
    return err('wrong_phase', '当前不在强盗移动阶段')
  }
  if (state.currentPlayerId !== player.id) return err('not_your_turn', '当前不是你的回合')
  const target = state.board.getHex(action.hexCoord)
  if (!target) return err('bad_hex', '六边形不存在')
  const terrain = TERRAINS[target.terrainId]
  if (!terrain) return err('bad_hex', '地形不存在')
  if (!terrain.robberBlocks) return err('bad_hex', '强盗不能放在此地形')
  if (state.robberCoord && state.robberCoord.equals(action.hexCoord)) {
    return err('same_hex', '强盗必须移动到新位置')
  }
  // 偷取目标：必须相邻定居点/城市的拥有者，且非自己
  if (action.stealTargetPlayerId) {
    const candidates = getStealCandidates(state, action.hexCoord)
    if (!candidates.includes(action.stealTargetPlayerId)) {
      return err('bad_target', '该玩家不是合法偷取目标')
    }
  }
  return ok(undefined)
}

function validateDiscard(
  action: { playerId: string; cards: ResourceSet },
  state: GameState,
  player: PlayerState,
): Result<void> {
  if (state.phase !== 'robber_discard') return err('wrong_phase', '当前不在弃牌阶段')
  if (action.playerId !== player.id) return err('bad_target', '只能为自己弃牌')
  if (!state.pendingDiscardPlayerIds.includes(player.id)) {
    return err('not_pending', '你不需要弃牌')
  }
  if (player.hasDiscarded) return err('already_discarded', '你已弃牌')
  const total = Object.values(action.cards).reduce((a, b) => a + b, 0)
  const required = Math.floor(handSize(player.hand) / 2)
  if (total !== required) return err('bad_count', `必须弃 ${required} 张`)
  // 资源数量不能超过持有
  for (const r of Object.keys(action.cards) as ResourceType[]) {
    if (player.hand[r] < action.cards[r]) return err('insufficient_resources', '资源不足')
  }
  return ok(undefined)
}

function validateChooseGold(
  action: { playerId: string; resources: ResourceType[] },
  state: GameState,
  player: PlayerState,
): Result<void> {
  const pending = state.pendingGoldChoices.find((p) => p.playerId === action.playerId)
  if (!pending) return err('not_pending', '无待选黄金')
  if (action.playerId !== player.id) return err('bad_target', '只能为自己选择')
  if (action.resources.length !== pending.count) {
    return err('bad_count', `必须选择 ${pending.count} 个资源`)
  }
  // 银行必须有
  const counts: Partial<Record<ResourceType, number>> = {}
  for (const r of action.resources) counts[r] = (counts[r] ?? 0) + 1
  for (const r of Object.keys(counts) as ResourceType[]) {
    if (state.bank[r] < (counts[r] ?? 0)) return err('bank_empty', '银行此资源已空')
  }
  return ok(undefined)
}

function validateEndTurn(state: GameState, player: PlayerState): Result<void> {
  if (state.phase !== 'action') return err('wrong_phase', '当前不在行动阶段')
  if (state.currentPlayerId !== player.id) return err('not_your_turn', '当前不是你的回合')
  return ok(undefined)
}

// ============ 辅助函数 ============

function isVertexConnectedToPlayerNetwork(
  vertexId: number,
  playerId: string,
  state: GameState,
): boolean {
  // 顶点本身已有自己的定居点/城市 → 连接
  if (
    state.buildings.some(
      (b) =>
        b.ownerId === playerId &&
        b.positionType === 'vertex' &&
        b.positionId === vertexId,
    )
  ) {
    return true
  }
  // 顶点相邻边中有自己的道路/船只
  const edges = state.board.vertexEdges(vertexId)
  for (const eid of edges) {
    if (
      state.buildings.some(
        (b) =>
          b.ownerId === playerId &&
          b.positionType === 'edge' &&
          b.positionId === eid,
      )
    ) {
      return true
    }
  }
  return false
}

function isEdgeConnectedToPlayerNetwork(
  edgeId: number,
  playerId: string,
  state: GameState,
  building: 'road' | 'ship',
): boolean {
  const [v1, v2] = state.board.edgeVertices(edgeId)
  // 顶点有自己的定居点/城市
  for (const vid of [v1, v2]) {
    if (
      state.buildings.some(
        (b) =>
          b.ownerId === playerId &&
          b.positionType === 'vertex' &&
          b.positionId === vid,
      )
    ) {
      return true
    }
  }
  // 顶点相邻边中有自己的道路/船只（道路可接船只，船只可接道路）
  for (const vid of [v1, v2]) {
    const edges = state.board.vertexEdges(vid)
    for (const eid of edges) {
      if (eid === edgeId) continue
      const found = state.buildings.find(
        (b) =>
          b.ownerId === playerId &&
          b.positionType === 'edge' &&
          b.positionId === eid,
      )
      if (found && (found.type === 'road' || found.type === 'ship')) {
        return true
      }
    }
  }
  return false
}

function findPortVertexForPlayer(
  state: GameState,
  playerId: string,
  portId: string,
): number {
  // 港口所在的顶点
  const portVertices = state.board.allPortVertices()
  for (const vid of portVertices) {
    if (state.board.getPort(vid) === portId) {
      // 该顶点或其相邻顶点是否有玩家的定居点/城市
      // 实际规则：玩家在该港口的两个端点之一有定居点即可使用
      // 这里：检查 vid 与其相邻顶点
      const candidates = [vid, ...state.board.adjacentVertices(vid)]
      if (
        state.buildings.some(
          (b) =>
            b.ownerId === playerId &&
            b.positionType === 'vertex' &&
            candidates.includes(b.positionId),
        )
      ) {
        return vid
      }
    }
  }
  return -1
}

function getStealCandidates(state: GameState, hexCoord: HexCoord): string[] {
  const candidates = new Set<string>()
  const board = state.board
  const vertexIds = board.vertexHexesByHex(hexCoord)
  for (const vid of vertexIds) {
    const building = state.buildings.find(
      (b) => b.positionType === 'vertex' && b.positionId === vid,
    )
    if (building && building.ownerId !== state.currentPlayerId) {
      candidates.add(building.ownerId)
    }
  }
  return Array.from(candidates)
}

// ============ 应用 ============

export function apply(
  action: GameAction,
  state: GameState,
  playerId: string,
  rng: Rng,
): Result<{ state: GameState; events: GameEvent[] }> {
  const v = validate(action, state, playerId)
  if (isErr(v)) return err(v.error.code, v.error.message)

  // 深拷贝状态
  const next: GameState = deepCloneState(state)
  const events: GameEvent[] = []
  const player = next.players.find((p) => p.id === playerId)!

  function log(text: string, kind: LogEntry['kind'] = 'info') {
    next.log.push({ turn: next.turn, playerId, text, kind })
  }

  switch (action.type) {
    case 'place_initial':
      applyPlaceInitial(action, next, player, events, log)
      break
    case 'roll_dice':
      applyRollDice(next, player, events, log, rng)
      break
    case 'build':
      applyBuild(action, next, player, events, log)
      break
    case 'buy_dev_card':
      applyBuyDevCard(next, player, events, log, rng)
      break
    case 'use_dev_card':
      applyUseDevCard(action, next, player, events, log, rng)
      break
    case 'trade_bank':
      applyTradeBank(action, next, player, events, log)
      break
    case 'trade_player':
      applyTradePlayer(action, next, player, events, log)
      break
    case 'move_robber':
      applyMoveRobber(action, next, player, events, log, rng)
      break
    case 'discard':
      applyDiscard(action, next, player, events, log)
      break
    case 'choose_gold':
      applyChooseGold(action, next, player, events, log)
      break
    case 'end_turn':
      applyEndTurn(next, player, events, log)
      break
  }

  // 检查胜利（在自己的回合内主动达到门槛）
  if (next.phase !== 'game_over' && next.winnerId === null) {
    for (const p of next.players) {
      if (totalVictoryPoints(p, next) >= next.victoryPointThreshold) {
        // 胜利点卡翻开结算
        for (const c of p.devCards) {
          if (c.type === 'victory_point') c.used = false // 已是
        }
        // 只有当前回合玩家在 end_turn 时主动达成才算赢
        // 但实际规则：在自己回合任何时点达成即胜
        if (p.id === next.currentPlayerId || p.id === playerId) {
          next.winnerId = p.id
          next.phase = 'game_over'
          events.push({ kind: 'victory', payload: { winnerId: p.id } })
          log(`${p.name} 达到 ${totalVictoryPoints(p, next)} 胜利点，赢得游戏！`, 'victory')
          break
        }
      }
    }
  }

  return ok({ state: next, events })
}

function deepCloneState(state: GameState): GameState {
  return {
    board: state.board, // Board 不深拷贝（拓扑不变），只读
    players: state.players.map((p) => ({
      ...p,
      hand: { ...p.hand },
      devCards: p.devCards.map((c) => ({ ...c })),
      pendingDevCards: p.pendingDevCards.map((c) => ({ ...c })),
    })),
    currentPlayerId: state.currentPlayerId,
    turnOrder: [...state.turnOrder],
    phase: state.phase,
    turn: state.turn,
    dice: state.dice ? { ...state.dice } : null,
    robberCoord: state.robberCoord ? new HexCoord(state.robberCoord.q, state.robberCoord.r) : null,
    longestRoadPlayerId: state.longestRoadPlayerId,
    largestArmyPlayerId: state.largestArmyPlayerId,
    bank: { ...state.bank },
    devCardDeck: [...state.devCardDeck],
    buildings: state.buildings.map((b) => ({ ...b })),
    log: state.log.map((l) => ({ ...l })),
    victoryPointThreshold: state.victoryPointThreshold,
    setupRound: state.setupRound,
    setupIndex: state.setupIndex,
    pendingDiscardPlayerIds: [...state.pendingDiscardPlayerIds],
    robberStealCandidates: [...state.robberStealCandidates],
    pendingGoldChoices: state.pendingGoldChoices.map((p) => ({ ...p })),
    pendingYearOfPlenty: state.pendingYearOfPlenty,
    pendingMonopoly: state.pendingMonopoly ? { ...state.pendingMonopoly } : null,
    pendingRoadBuilding: state.pendingRoadBuilding,
    winnerId: state.winnerId,
  }
}

function applyPlaceInitial(
  action: { vertexId: number; edgeId: number },
  state: GameState,
  player: PlayerState,
  events: GameEvent[],
  log: (text: string, kind?: LogEntry['kind']) => void,
) {
  const building: BuildingInstance = {
    id: state.buildings.length,
    type: 'settlement',
    ownerId: player.id,
    positionType: 'vertex',
    positionId: action.vertexId,
    purchasedTurn: state.turn,
  }
  state.buildings.push(building)
  const road: BuildingInstance = {
    id: state.buildings.length,
    type: 'road',
    ownerId: player.id,
    positionType: 'edge',
    positionId: action.edgeId,
    purchasedTurn: state.turn,
  }
  state.buildings.push(road)
  events.push({ kind: 'building_built', payload: { type: 'settlement', playerId: player.id, positionId: action.vertexId } })
  events.push({ kind: 'building_built', payload: { type: 'road', playerId: player.id, positionId: action.edgeId } })
  log(`${player.name} 在初始放置定居点与道路`, 'build')

  // 第 2 轮放置后立即获得相邻地形初始资源
  if (state.setupRound === 2) {
    const vHexes = state.board.vertexHexes(action.vertexId)
    for (const c of vHexes) {
      const h = state.board.getHex(c)
      if (!h) continue
      const terrain = TERRAINS[h.terrainId]
      if (!terrain || !isProductionTerrain(terrain)) continue
      if (terrain.resource === 'any') continue // 黄金不在此产出（场景规则）
      const res = terrain.resource as ResourceType
      if (state.bank[res] > 0) {
        player.hand[res] += 1
        state.bank[res] -= 1
      }
    }
  }

  // 推进放置
  advanceSetup(state)
}

function advanceSetup(state: GameState) {
  state.setupIndex += 1
  const totalPlayers = state.players.length
  // 第 1 轮：0 → totalPlayers-1
  // 第 2 轮：totalPlayers-1 → 0
  if (state.setupRound === 1) {
    if (state.setupIndex >= totalPlayers) {
      state.setupRound = 2
      state.setupIndex = 0
      // 反向开始：当前玩家 = 最后一位
      state.currentPlayerId = state.turnOrder[totalPlayers - 1]
    } else {
      state.currentPlayerId = state.turnOrder[state.setupIndex]
    }
  } else if (state.setupRound === 2) {
    // 反向：从 totalPlayers-1 到 0
    if (state.setupIndex >= totalPlayers) {
      // 初始放置结束，进入第 1 回合
      state.setupRound = 0
      state.phase = 'roll'
      state.turn = 1
      state.currentPlayerId = state.turnOrder[0]
      state.log.push({
        turn: state.turn,
        playerId: null,
        text: '初始放置结束，进入第 1 回合',
        kind: 'phase',
      })
    } else {
      // 反向索引
      const reverseIndex = totalPlayers - 1 - state.setupIndex
      state.currentPlayerId = state.turnOrder[reverseIndex]
    }
  }
}

function applyRollDice(
  state: GameState,
  player: PlayerState,
  events: GameEvent[],
  log: (text: string, kind?: LogEntry['kind']) => void,
  rng: Rng,
) {
  const d1 = rng.nextInt(1, 6)
  const d2 = rng.nextInt(1, 6)
  const total = d1 + d2
  state.dice = { d1, d2, total }
  events.push({ kind: 'dice_rolled', payload: { d1, d2, total, playerId: player.id } })
  log(`${player.name} 掷骰：${d1} + ${d2} = ${total}`, 'roll')

  if (total === 7) {
    // 触发强盗
    triggerRobber(state, events, log)
  } else {
    // 资源产出
    produceResources(state, total, events, log)
    // 若有待选黄金，保持 roll 阶段直到所有玩家选完；否则进入行动
    if (state.pendingGoldChoices.length === 0) {
      state.phase = 'action'
    } else {
      // 仍处于 roll 阶段（实际上由 choose_gold 在结束时切换到 action）
      state.phase = 'roll'
    }
  }
}

function produceResources(
  state: GameState,
  total: number,
  events: GameEvent[],
  log: (text: string, kind?: LogEntry['kind']) => void,
) {
  const producedMap: Record<string, Partial<Record<ResourceType, number>>> = {}
  for (const cell of state.board.allHexes()) {
    if (cell.numberToken !== total) continue
    if (state.robberCoord && state.robberCoord.equals(cell.coord)) continue
    const terrain = TERRAINS[cell.terrainId]
    if (!terrain || !isProductionTerrain(terrain)) continue
    const vHexes = state.board.vertexHexesByHex(cell.coord)
    for (const vid of vHexes) {
      const building = state.buildings.find(
        (b) => b.positionType === 'vertex' && b.positionId === vid,
      )
      if (!building) continue
      const owner = state.players.find((p) => p.id === building.ownerId)
      if (!owner) continue
      const mult = building.type === 'city' ? 2 : 1
      if (terrain.resource === 'any') {
        // 黄金地形：玩家选择
        state.pendingGoldChoices.push({ playerId: owner.id, count: mult })
        continue
      }
      const res = terrain.resource as ResourceType
      const actual = Math.min(mult, state.bank[res])
      if (actual > 0) {
        owner.hand[res] += actual
        state.bank[res] -= actual
        producedMap[owner.id] = producedMap[owner.id] ?? {}
        producedMap[owner.id][res] = (producedMap[owner.id][res] ?? 0) + actual
      }
    }
  }
  for (const pid of Object.keys(producedMap)) {
    const p = state.players.find((x) => x.id === pid)!
    const summary = Object.entries(producedMap[pid])
      .map(([r, c]) => `${c} ${(r as ResourceType)}`)
      .join(' · ')
    log(`${p.name} 获得：${summary}`, 'produce')
  }
  if (Object.keys(producedMap).length > 0) {
    events.push({ kind: 'resources_produced', payload: { produced: producedMap } })
  }
  // 若有黄金选择，phase 转为等待选择
  if (state.pendingGoldChoices.length > 0) {
    // 阻塞 action 阶段：用一个特殊 phase
    // 简化：直接保持 roll 阶段，由调用方检测 pendingGoldChoices
  }
}

function triggerRobber(
  state: GameState,
  events: GameEvent[],
  log: (text: string, kind?: LogEntry['kind']) => void,
) {
  // 手牌 >7 弃一半
  const discarders: string[] = []
  for (const p of state.players) {
    p.hasDiscarded = false
    if (handSize(p.hand) > 7) discarders.push(p.id)
  }
  state.pendingDiscardPlayerIds = discarders
  if (discarders.length > 0) {
    state.phase = 'robber_discard'
    log(`7 点！以下玩家需弃牌：${discarders.map((id) => state.players.find((p) => p.id === id)!.name).join('、')}`, 'robber')
  } else {
    state.phase = 'robber_move'
    log('7 点！移动强盗', 'robber')
  }
  events.push({ kind: 'robber_moved', payload: { trigger: 'dice7' } })
}

function applyBuild(
  action: { building: BuildingType; positionId: number },
  state: GameState,
  player: PlayerState,
  events: GameEvent[],
  log: (text: string, kind?: LogEntry['kind']) => void,
) {
  const def = getBuilding(action.building)!
  const isFreeRoad =
    action.building === 'road' &&
    player.freeRoadsRemaining > 0 &&
    state.pendingRoadBuilding === player.id

  if (!isFreeRoad) {
    player.hand = payCost(player.hand, def.cost)
    // 资源回到银行
    for (const r of Object.keys(def.cost) as ResourceType[]) {
      state.bank[r] += def.cost[r] ?? 0
    }
  } else {
    player.freeRoadsRemaining -= 1
    if (player.freeRoadsRemaining === 0) {
      state.pendingRoadBuilding = null
    }
  }

  if (action.building === 'city') {
    // 升级：移除原定居点
    const idx = state.buildings.findIndex(
      (b) =>
        b.ownerId === player.id &&
        b.type === 'settlement' &&
        b.positionId === action.positionId,
    )
    if (idx >= 0) state.buildings.splice(idx, 1)
  }

  const building: BuildingInstance = {
    id: state.buildings.length,
    type: action.building,
    ownerId: player.id,
    positionType: def.positionType as 'vertex' | 'edge',
    positionId: action.positionId,
    purchasedTurn: state.turn,
  }
  state.buildings.push(building)
  events.push({ kind: 'building_built', payload: { type: action.building, playerId: player.id, positionId: action.positionId } })
  log(`${player.name} 建造 ${def.name}`, 'build')

  // 重新计算最长道路
  recomputeLongestRoad(state, events, log)
}

function recomputeLongestRoad(
  state: GameState,
  events: GameEvent[],
  log: (text: string, kind?: LogEntry['kind']) => void,
) {
  let bestPlayerId: string | null = null
  let bestLen = 0
  for (const p of state.players) {
    const len = computeLongestRoad(p.id, state)
    p.longestRoadLength = len
    if (len > bestLen && len >= 5) {
      bestLen = len
      bestPlayerId = p.id
    } else if (len === bestLen && bestPlayerId !== null) {
      // 并列：原持有者保留
      // 如果当前持有者就是 p，不变；否则保持现有
    }
  }
  if (bestPlayerId !== state.longestRoadPlayerId) {
    if (bestPlayerId !== null) {
      const p = state.players.find((x) => x.id === bestPlayerId)!
      log(`${p.name} 获得最长道路（${bestLen} 段）`, 'info')
    }
    state.longestRoadPlayerId = bestPlayerId
    events.push({ kind: 'longest_rood_changed', payload: { playerId: bestPlayerId, length: bestLen } })
  }
}

function recomputeLargestArmy(
  state: GameState,
  events: GameEvent[],
  log: (text: string, kind?: LogEntry['kind']) => void,
) {
  let bestPlayerId: string | null = null
  let bestCount = 0
  for (const p of state.players) {
    if (p.knightsPlayed > bestCount && p.knightsPlayed >= 3) {
      bestCount = p.knightsPlayed
      bestPlayerId = p.id
    }
  }
  if (bestPlayerId !== state.largestArmyPlayerId) {
    if (bestPlayerId !== null) {
      const p = state.players.find((x) => x.id === bestPlayerId)!
      log(`${p.name} 获得最大军队（${bestCount} 骑士）`, 'info')
    }
    state.largestArmyPlayerId = bestPlayerId
    events.push({ kind: 'largest_army_changed', payload: { playerId: bestPlayerId, count: bestCount } })
  }
}

function applyBuyDevCard(
  state: GameState,
  player: PlayerState,
  events: GameEvent[],
  log: (text: string, kind?: LogEntry['kind']) => void,
  rng: Rng,
) {
  const def = BUILDINGS.dev_card
  player.hand = payCost(player.hand, def.cost)
  for (const r of Object.keys(def.cost) as ResourceType[]) {
    state.bank[r] += def.cost[r] ?? 0
  }
  const type = state.devCardDeck.pop()!
  const card: DevCardInstance = {
    id: state.turn * 1000 + player.devCards.length,
    type,
    ownerId: player.id,
    purchasedTurn: state.turn,
    used: false,
  }
  player.devCards.push(card)
  player.pendingDevCards.push(card)
  events.push({ kind: 'dev_card_bought', payload: { playerId: player.id, cardType: type } })
  log(`${player.name} 购买了 1 张发展卡`, 'dev_card')
}

function applyUseDevCard(
  action: { cardId: number; payload: DevCardPayload },
  state: GameState,
  player: PlayerState,
  events: GameEvent[],
  log: (text: string, kind?: LogEntry['kind']) => void,
  rng: Rng,
) {
  const card = player.devCards.find((c) => c.id === action.cardId)!
  card.used = true
  player.devCardsUsedThisTurn = (player.devCardsUsedThisTurn ?? 0) + 1

  switch (card.type) {
    case 'knight':
      player.knightsPlayed += 1
      recomputeLargestArmy(state, events, log)
      // 进入强盗移动阶段
      state.phase = 'robber_move'
      log(`${player.name} 使用骑士卡，移动强盗`, 'dev_card')
      break
    case 'victory_point':
      // 已计入 totalVictoryPoints
      log(`${player.name} 翻开胜利点卡`, 'dev_card')
      break
    case 'road_building':
      player.freeRoadsRemaining = 2
      state.pendingRoadBuilding = player.id
      log(`${player.name} 使用道路建设卡，可免费建 2 条道路`, 'dev_card')
      break
    case 'year_of_plenty': {
      const resources = action.payload.kind === 'year_of_plenty' ? action.payload.resources : []
      for (const r of resources) {
        if (state.bank[r] > 0) {
          player.hand[r] += 1
          state.bank[r] -= 1
        }
      }
      log(`${player.name} 使用发明卡，获得 2 张资源`, 'dev_card')
      break
    }
    case 'monopoly': {
      if (action.payload.kind !== 'monopoly') break
      const target = action.payload.resource
      let total = 0
      for (const p of state.players) {
        if (p.id === player.id) continue
        const cnt = p.hand[target]
        if (cnt > 0) {
          total += cnt
          p.hand[target] = 0
        }
      }
      player.hand[target] += total
      log(`${player.name} 使用垄断卡，掠夺 ${total} 张 ${target}`, 'dev_card')
      break
    }
  }
  events.push({ kind: 'dev_card_used', payload: { playerId: player.id, cardType: card.type } })
}

function applyTradeBank(
  action: { give: ResourceSet; receive: ResourceType; portId?: string },
  state: GameState,
  player: PlayerState,
  events: GameEvent[],
  log: (text: string, kind?: LogEntry['kind']) => void,
) {
  for (const r of Object.keys(action.give) as ResourceType[]) {
    player.hand[r] -= action.give[r]
    state.bank[r] += action.give[r]
  }
  player.hand[action.receive] += 1
  state.bank[action.receive] -= 1
  const ratio = action.portId ? PORTS[action.portId as PortId].tradeRatio : '4:1'
  log(`${player.name} 以 ${ratio} 与银行交易`, 'trade')
  events.push({ kind: 'trade_completed', payload: { kind: 'bank', ratio } })
}

function applyTradePlayer(
  action: { targetPlayerId: string; give: ResourceSet; receive: ResourceSet },
  state: GameState,
  player: PlayerState,
  events: GameEvent[],
  log: (text: string, kind?: LogEntry['kind']) => void,
) {
  const target = state.players.find((p) => p.id === action.targetPlayerId)!
  for (const r of Object.keys(action.give) as ResourceType[]) {
    player.hand[r] -= action.give[r]
    target.hand[r] += action.give[r]
  }
  for (const r of Object.keys(action.receive) as ResourceType[]) {
    target.hand[r] -= action.receive[r]
    player.hand[r] += action.receive[r]
  }
  log(`${player.name} 与 ${target.name} 完成交易`, 'trade')
  events.push({ kind: 'trade_completed', payload: { kind: 'player', target: target.id } })
}

function applyMoveRobber(
  action: { hexCoord: HexCoord; stealTargetPlayerId?: string },
  state: GameState,
  player: PlayerState,
  events: GameEvent[],
  log: (text: string, kind?: LogEntry['kind']) => void,
  rng: Rng,
) {
  state.robberCoord = new HexCoord(action.hexCoord.q, action.hexCoord.r)
  log(`${player.name} 移动强盗`, 'robber')
  events.push({ kind: 'robber_moved', payload: { hexCoord: action.hexCoord } })
  // 偷取
  if (action.stealTargetPlayerId) {
    const target = state.players.find((p) => p.id === action.stealTargetPlayerId)!
    const targetResources = (Object.entries(target.hand) as Array<[ResourceType, number]>).filter(
      ([, c]) => c > 0,
    )
    if (targetResources.length > 0) {
      const [res] = rng.pick(targetResources)
      target.hand[res] -= 1
      player.hand[res] += 1
      log(`${player.name} 从 ${target.name} 偷取 1 张 ${res}`, 'robber')
      events.push({ kind: 'resource_stolen', payload: { from: target.id, to: player.id, resource: res } })
    } else {
      log(`${target.name} 无资源可偷`, 'robber')
    }
  }
  state.phase = 'action'
}

function applyDiscard(
  action: { playerId: string; cards: ResourceSet },
  state: GameState,
  player: PlayerState,
  events: GameEvent[],
  log: (text: string, kind?: LogEntry['kind']) => void,
) {
  for (const r of Object.keys(action.cards) as ResourceType[]) {
    player.hand[r] -= action.cards[r]
    state.bank[r] += action.cards[r]
  }
  player.hasDiscarded = true
  const idx = state.pendingDiscardPlayerIds.indexOf(player.id)
  if (idx >= 0) state.pendingDiscardPlayerIds.splice(idx, 1)
  log(`${player.name} 弃牌`, 'robber')
  events.push({ kind: 'cards_discarded', payload: { playerId: player.id } })
  // 全部弃完，进入强盗移动
  if (state.pendingDiscardPlayerIds.length === 0) {
    state.phase = 'robber_move'
  }
}

function applyChooseGold(
  action: { playerId: string; resources: ResourceType[] },
  state: GameState,
  player: PlayerState,
  events: GameEvent[],
  log: (text: string, kind?: LogEntry['kind']) => void,
) {
  for (const r of action.resources) {
    if (state.bank[r] > 0) {
      player.hand[r] += 1
      state.bank[r] -= 1
    }
  }
  const idx = state.pendingGoldChoices.findIndex((p) => p.playerId === player.id)
  if (idx >= 0) state.pendingGoldChoices.splice(idx, 1)
  log(`${player.name} 选择黄金资源`, 'produce')
  events.push({ kind: 'resources_produced', payload: { gold: action.resources, playerId: player.id } })
  if (state.pendingGoldChoices.length === 0 && state.phase === 'roll') {
    state.phase = 'action'
  } else if (state.pendingGoldChoices.length === 0) {
    state.phase = 'action'
  }
}

function applyEndTurn(
  state: GameState,
  player: PlayerState,
  events: GameEvent[],
  log: (text: string, kind?: LogEntry['kind']) => void,
) {
  // 重置本回合临时状态
  player.devCardsUsedThisTurn = 0
  player.hasDiscarded = false
  player.freeRoadsRemaining = 0
  // 待用发展卡转为可用
  player.devCards = player.devCards.filter((c) => !c.used)

  // 切换下一玩家
  const idx = state.turnOrder.indexOf(state.currentPlayerId)
  const nextIdx = (idx + 1) % state.turnOrder.length
  state.currentPlayerId = state.turnOrder[nextIdx]
  if (nextIdx === 0) state.turn += 1
  state.phase = 'roll'
  state.dice = null
  const nextPlayer = state.players.find((p) => p.id === state.currentPlayerId)!
  log(`${nextPlayer.name} 的回合开始`, 'phase')
  events.push({ kind: 'turn_started', payload: { playerId: nextPlayer.id, turn: state.turn } })
}

// Board.vertexHexesByHex 方法已在 board.ts 中实现，此处直接调用
