import { Board } from '@/core/board'
import { HexCoord } from '@/core/hexCoord'
import { Rng, seedFromString } from '@/core/rng'
import { TERRAINS, isLandTerrain } from '@/core/data/terrains'
import { PORT_DECK } from '@/core/data/ports'
import { DEV_CARDS } from '@/core/data/devCards'
import type {
  ScenarioDef,
  TerrainId,
  DevCardType,
  ResourceSet,
} from '@/core/data/types'
import { type GameState, type PlayerState, emptyResourceSet } from '@/core/gameState'
import { PLAYER_COLORS, PLAYER_NAMES } from '@/utils/colors'
import { BASE_SCENARIO } from '@/core/data/scenarios/base4p'
import { NEW_WORLD_SCENARIO } from '@/core/data/scenarios/newWorld'
import { DESERT_SCENARIO } from '@/core/data/scenarios/desert'

const SCENARIO_MAP: Record<string, ScenarioDef> = {
  [BASE_SCENARIO.id]: BASE_SCENARIO,
  [NEW_WORLD_SCENARIO.id]: NEW_WORLD_SCENARIO,
  [DESERT_SCENARIO.id]: DESERT_SCENARIO,
}

const STANDARD_NUMBERS = [2, 3, 3, 4, 4, 5, 5, 6, 6, 8, 8, 9, 9, 10, 10, 11, 11, 12]

// 基础版地形分布（19 格陆地）
const BASE_TERRAIN_DECK: TerrainId[] = [
  'mountains',
  'mountains',
  'mountains',
  'mountains',
  'hills',
  'hills',
  'hills',
  'forest',
  'forest',
  'forest',
  'forest',
  'fields',
  'fields',
  'fields',
  'fields',
  'pasture',
  'pasture',
  'pasture',
  'pasture',
  'desert',
]

export interface SessionConfig {
  playerCount: number
  aiCount: number
  scenarioId: string
  seed: string
  victoryPointThreshold: number
}

export function getScenario(id: string): ScenarioDef {
  return SCENARIO_MAP[id] ?? BASE_SCENARIO
}

export function createInitialState(config: SessionConfig): GameState {
  const scenario = getScenario(config.scenarioId)
  const rng = new Rng(seedFromString(config.seed))
  const board = generateBoard(scenario, rng)

  // 玩家：人类在前，AI 在后
  const totalPlayers = config.playerCount
  const players: PlayerState[] = []
  for (let i = 0; i < totalPlayers; i++) {
    const color = PLAYER_COLORS[i]
    const isAi = i >= totalPlayers - config.aiCount
    players.push({
      id: `p${i + 1}`,
      name: isAi ? `AI·${PLAYER_NAMES[color]}` : PLAYER_NAMES[color],
      color,
      isAi,
      hand: emptyResourceSet(),
      devCards: [],
      knightsPlayed: 0,
      longestRoadLength: 0,
      pendingDevCards: [],
      freeRoadsRemaining: 0,
      hasDiscarded: false,
      devCardsUsedThisTurn: 0,
    })
  }

  const turnOrder = players.map((p) => p.id)
  const bank: ResourceSet = { wood: 19, brick: 19, sheep: 19, wheat: 19, ore: 19 }

  // 发展卡牌堆
  const devCardDeck: DevCardType[] = []
  for (const [type, def] of Object.entries(DEV_CARDS) as Array<
    [DevCardType, (typeof DEV_CARDS)[DevCardType]]
  >) {
    for (let i = 0; i < def.count; i++) devCardDeck.push(type)
  }
  const shuffledDeck = rng.shuffle(devCardDeck)

  // 强盗初始位置：沙漠
  let robberCoord: HexCoord | null = null
  for (const cell of board.allHexes()) {
    if (cell.terrainId === 'desert') {
      robberCoord = new HexCoord(cell.coord.q, cell.coord.r)
      break
    }
  }
  if (!robberCoord) {
    const first = board.allHexes().find((c) => isLandTerrain(TERRAINS[c.terrainId]))
    if (first) robberCoord = new HexCoord(first.coord.q, first.coord.r)
  }

  return {
    board,
    players,
    currentPlayerId: turnOrder[0],
    turnOrder,
    phase: 'setup_forward',
    turn: 0,
    dice: null,
    robberCoord,
    longestRoadPlayerId: null,
    largestArmyPlayerId: null,
    bank,
    devCardDeck: shuffledDeck,
    buildings: [],
    log: [{ turn: 0, playerId: null, text: '游戏开始', kind: 'info' }],
    victoryPointThreshold: config.victoryPointThreshold,
    setupRound: 1,
    setupIndex: 0,
    pendingDiscardPlayerIds: [],
    robberStealCandidates: [],
    pendingGoldChoices: [],
    pendingYearOfPlenty: null,
    pendingMonopoly: null,
    pendingRoadBuilding: null,
    winnerId: null,
  }
}

function generateBoard(scenario: ScenarioDef, rng: Rng): Board {
  const board = new Board()
  const landCoords: HexCoord[] = []

  for (const h of scenario.hexes) {
    const coord = new HexCoord(h.q, h.r)
    board.addHex(coord, h.terrain, 0)
    if (isLandTerrain(TERRAINS[h.terrain])) landCoords.push(coord)
  }
  board.buildTopology()

  if (scenario.id === 'base_4p') {
    // 基础版：随机地形（含沙漠位置随机）
    const terrainDeck = rng.shuffle(BASE_TERRAIN_DECK.slice())
    let i = 0
    for (const coord of landCoords) {
      board.setHexTerrain(coord, terrainDeck[i++], 0)
    }
    // 数字牌：6/8 不相邻约束（最多 30 次重试）
    for (let attempts = 0; attempts < 30; attempts++) {
      const shuffled = rng.shuffle(STANDARD_NUMBERS.slice())
      const tempMap = new Map<string, number>()
      let idx = 0
      for (const coord of landCoords) {
        const cell = board.getHex(coord)!
        if (cell.terrainId === 'desert') {
          tempMap.set(coord.toKey(), 0)
          continue
        }
        tempMap.set(coord.toKey(), shuffled[idx++])
      }
      let ok = true
      for (const coord of landCoords) {
        const num = tempMap.get(coord.toKey())!
        if (num !== 6 && num !== 8) continue
        for (const nb of board.hexNeighbors(coord)) {
          if ((tempMap.get(nb.toKey()) ?? 0) === 6 || (tempMap.get(nb.toKey()) ?? 0) === 8) {
            ok = false
            break
          }
        }
        if (!ok) break
      }
      if (ok) {
        for (const [key, num] of tempMap) {
          const cell = board.getHex(HexCoord.fromKey(key))
          if (cell) cell.numberToken = num
        }
        break
      }
    }
  } else {
    // 海洋扩展：地形已由 scenario 指定，仅为陆地非沙漠分配数字
    const numbers = rng.shuffle(STANDARD_NUMBERS.slice())
    for (const coord of landCoords) {
      const cell = board.getHex(coord)!
      if (cell.terrainId === 'desert') continue
      cell.numberToken = numbers.pop() ?? 0
    }
  }

  assignPorts(board, rng)
  return board
}

function assignPorts(board: Board, rng: Rng) {
  const portsDeck = rng.shuffle(PORT_DECK.slice())
  const boundary = board.boundaryVertices()
  const usedVertices = new Set<number>()
  const portSlots: Array<{ v1: number; v2: number }> = []
  for (const v of boundary) {
    if (usedVertices.has(v)) continue
    const adj = board.adjacentVertices(v).filter((a) => boundary.includes(a) && !usedVertices.has(a))
    if (adj.length === 0) continue
    const v2 = adj[0]
    portSlots.push({ v1: v, v2 })
    usedVertices.add(v)
    usedVertices.add(v2)
    if (portSlots.length >= 9) break
  }
  for (let i = 0; i < portSlots.length && i < portsDeck.length; i++) {
    board.setPort(portSlots[i].v1, portsDeck[i])
    board.setPort(portSlots[i].v2, portsDeck[i])
  }
}
