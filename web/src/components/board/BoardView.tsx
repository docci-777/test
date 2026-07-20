import { useState, useEffect, useRef } from 'react'
import { useGameStore } from '@/store/gameStore'
import { useUiStore, type BuildMode } from '@/store/uiStore'
import { HexCoord } from '@/core/hexCoord'
import { validate } from '@/core/rulesEngine'
import { isOk } from '@/core/result'
import { TERRAINS, isLandTerrain } from '@/core/data/terrains'
import type { BuildingType, PlayerColor } from '@/core/data/types'
import type { BuildingInstance, GameState } from '@/core/gameState'
import type { Board } from '@/core/board'
import { HEX_SIZE, hexToPixel, vertexPhysToPixel } from '@/utils/hexMath'
import { PLAYER_COLOR_HEX } from '@/utils/colors'
import HexTile from './HexTile'
import VertexSlot from './VertexSlot'
import EdgeSlot from './EdgeSlot'
import Robber from './Robber'
import PortIndicator from './PortIndicator'

interface BoardViewProps {
  className?: string
}

interface PortPair {
  v1: number
  v2: number
  portId: string
}

// 计算港口对：相邻两顶点共享同一 portId
function computePortPairs(board: Board): PortPair[] {
  const portVertices = board.allPortVertices()
  const rendered = new Set<number>()
  const pairs: PortPair[] = []
  for (const v of portVertices) {
    if (rendered.has(v)) continue
    const portId = board.getPort(v)
    if (!portId) continue
    const adj = board.adjacentVertices(v).find((a) => board.getPort(a) === portId)
    if (adj !== undefined) {
      pairs.push({ v1: v, v2: adj, portId })
      rendered.add(v)
      rendered.add(adj)
    } else {
      pairs.push({ v1: v, v2: v, portId })
      rendered.add(v)
    }
  }
  return pairs
}

// 棋盘像素边界
function computeBoardBounds(board: Board): { minX: number; minY: number; width: number; height: number } {
  let minX = Infinity
  let minY = Infinity
  let maxX = -Infinity
  let maxY = -Infinity
  for (const cell of board.allHexes()) {
    const { x, y } = hexToPixel(cell.coord)
    if (x - HEX_SIZE < minX) minX = x - HEX_SIZE
    if (x + HEX_SIZE > maxX) maxX = x + HEX_SIZE
    if (y - HEX_SIZE < minY) minY = y - HEX_SIZE
    if (y + HEX_SIZE > maxY) maxY = y + HEX_SIZE
  }
  const padding = HEX_SIZE * 0.8
  return {
    minX: minX - padding,
    minY: minY - padding,
    width: maxX - minX + padding * 2,
    height: maxY - minY + padding * 2,
  }
}

// 偷取候选
function getStealCandidates(state: GameState, hexCoord: HexCoord): string[] {
  const candidates = new Set<string>()
  const vertexIds = state.board.vertexHexesByHex(hexCoord)
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

// 初始放置时顶点是否合法（不调用 validate，因为 edgeId 还没选）
function isValidInitialVertex(board: Board, state: GameState, vertexId: number): boolean {
  const vertex = board.getVertex(vertexId)
  if (!vertex) return false
  const vHexes = board.vertexHexes(vertexId)
  const hasLand = vHexes.some((c) => {
    const h = board.getHex(c)
    return h && isLandTerrain(TERRAINS[h.terrainId])
  })
  if (!hasLand) return false
  // 距离规则
  for (const b of state.buildings) {
    if (b.positionType !== 'vertex') continue
    const dist = board.vertexDistance(b.positionId, vertexId)
    if (dist >= 0 && dist < 2) return false
  }
  // 顶点已被占用
  if (state.buildings.some((b) => b.positionType === 'vertex' && b.positionId === vertexId)) {
    return false
  }
  // 必须至少有一个相邻陆地边可放初始道路
  const adjEdges = board.vertexEdges(vertexId)
  let hasValidEdge = false
  for (const eid of adjEdges) {
    const edgeHexes = board.edgeHexes(eid)
    const isLandEdge = edgeHexes.some((c) => {
      const h = board.getHex(c)
      return h && isLandTerrain(TERRAINS[h.terrainId])
    })
    if (!isLandEdge) continue
    if (state.buildings.some((b) => b.positionType === 'edge' && b.positionId === eid)) continue
    hasValidEdge = true
    break
  }
  return hasValidEdge
}

// 交互提示
function getInteractionHint(
  mode: BuildMode,
  pendingInitialVertex: number | null,
  pendingRobberHex: HexCoord | null,
): string {
  if (mode.kind === 'place_initial') {
    if (pendingInitialVertex === null) return '点击顶点放置定居点'
    return '点击相邻边放置初始道路（Esc 取消）'
  }
  if (mode.kind === 'move_robber') {
    if (pendingRobberHex) return '选择要偷取的玩家'
    return '点击陆地六边形移动强盗'
  }
  if (mode.kind === 'build') {
    switch (mode.building) {
      case 'settlement':
        return '点击顶点建造定居点（Esc 取消）'
      case 'city':
        return '点击你的定居点升级为城市（Esc 取消）'
      case 'road':
        return '点击陆地边建造道路（Esc 取消）'
      case 'ship':
        return '点击浅海边建造船只（Esc 取消）'
      default:
        return ''
    }
  }
  return ''
}

// ============ 棋盘上的建筑渲染 ============

function SettlementOnBoard({ cx, cy, color }: { cx: number; cy: number; color: PlayerColor }) {
  const c = PLAYER_COLOR_HEX[color]
  return (
    <g pointerEvents="none" transform={`translate(${cx} ${cy})`} className="animate-fadeIn">
      <ellipse cx="0" cy="9" rx="9" ry="2" fill="rgba(0,0,0,0.35)" />
      <rect x="-7" y="-2" width="14" height="10" fill={c.main} stroke="#2b1810" strokeWidth="1.5" />
      <polygon
        points="-9,-2 0,-10 9,-2"
        fill={c.dark}
        stroke="#2b1810"
        strokeWidth="1.5"
        strokeLinejoin="round"
      />
      <rect x="3" y="-8" width="2.5" height="4" fill={c.dark} stroke="#2b1810" strokeWidth="1" />
      <rect x="-1.5" y="3" width="3" height="5" fill="#2b1810" />
    </g>
  )
}

function CityOnBoard({ cx, cy, color }: { cx: number; cy: number; color: PlayerColor }) {
  const c = PLAYER_COLOR_HEX[color]
  return (
    <g pointerEvents="none" transform={`translate(${cx} ${cy})`} className="animate-fadeIn">
      <ellipse cx="0" cy="11" rx="11" ry="2.5" fill="rgba(0,0,0,0.35)" />
      <rect x="-9" y="-2" width="18" height="11" fill={c.main} stroke="#2b1810" strokeWidth="1.5" />
      <rect x="-10" y="-8" width="6" height="17" fill={c.dark} stroke="#2b1810" strokeWidth="1.5" />
      <polygon
        points="-11,-8 -7,-8 -7,-13 -9,-13"
        fill={c.dark}
        stroke="#2b1810"
        strokeWidth="1.5"
        strokeLinejoin="round"
      />
      <rect x="4" y="-8" width="6" height="17" fill={c.dark} stroke="#2b1810" strokeWidth="1.5" />
      <polygon
        points="3,-8 7,-8 7,-13 5,-13"
        fill={c.dark}
        stroke="#2b1810"
        strokeWidth="1.5"
        strokeLinejoin="round"
      />
      <polygon
        points="-4,-2 4,-2 0,-9"
        fill={c.dark}
        stroke="#2b1810"
        strokeWidth="1.5"
        strokeLinejoin="round"
      />
      <rect x="-1.5" y="2" width="3" height="4" fill="#2b1810" />
    </g>
  )
}

function RoadOnBoard({
  x1,
  y1,
  x2,
  y2,
  color,
}: {
  x1: number
  y1: number
  x2: number
  y2: number
  color: PlayerColor
}) {
  const c = PLAYER_COLOR_HEX[color]
  const mx = (x1 + x2) / 2
  const my = (y1 + y2) / 2
  const angle = (Math.atan2(y2 - y1, x2 - x1) * 180) / Math.PI
  const len = Math.sqrt((x2 - x1) ** 2 + (y2 - y1) ** 2)
  const w = Math.min(len * 0.82, 44)
  return (
    <g pointerEvents="none" transform={`translate(${mx} ${my}) rotate(${angle})`} className="animate-fadeIn">
      <rect x={-w / 2} y="-3" width={w} height="6" fill={c.main} stroke="#2b1810" strokeWidth="1.2" rx="1" />
      <line
        x1={-w / 2 + 4}
        y1="0"
        x2={w / 2 - 4}
        y2="0"
        stroke={c.dark}
        strokeWidth="0.8"
        strokeDasharray="3,2"
      />
    </g>
  )
}

function ShipOnBoard({
  x1,
  y1,
  x2,
  y2,
  color,
}: {
  x1: number
  y1: number
  x2: number
  y2: number
  color: PlayerColor
}) {
  const c = PLAYER_COLOR_HEX[color]
  const mx = (x1 + x2) / 2
  const my = (y1 + y2) / 2
  const angle = (Math.atan2(y2 - y1, x2 - x1) * 180) / Math.PI
  return (
    <g pointerEvents="none" transform={`translate(${mx} ${my}) rotate(${angle})`} className="animate-fadeIn">
      <ellipse cx="0" cy="6" rx="11" ry="2" fill="rgba(0,0,0,0.3)" />
      <path
        d="M -10 2 L 10 2 L 8 7 L -8 7 Z"
        fill={c.main}
        stroke="#2b1810"
        strokeWidth="1.3"
        strokeLinejoin="round"
      />
      <line x1="0" y1="2" x2="0" y2="-9" stroke="#2b1810" strokeWidth="1.3" />
      <path
        d="M 0 -8 L 0 -1 L 7 -3 Z"
        fill={c.dark}
        stroke="#2b1810"
        strokeWidth="1"
        strokeLinejoin="round"
      />
      <line x1="0" y1="-9" x2="3" y2="-9" stroke={c.main} strokeWidth="1.3" />
    </g>
  )
}

// 地形纹理 patterns
const TERRAIN_PATTERNS = (
  <>
    <pattern id="pat-forest" width="14" height="14" patternUnits="userSpaceOnUse">
      <rect width="14" height="14" fill="#2d5a3d" />
      <circle cx="4" cy="4" r="1.6" fill="#1d3a25" />
      <circle cx="11" cy="9" r="1.6" fill="#1d3a25" />
      <circle cx="6" cy="12" r="1" fill="#1d3a25" />
    </pattern>
    <pattern id="pat-pasture" width="14" height="14" patternUnits="userSpaceOnUse">
      <rect width="14" height="14" fill="#8fbf5e" />
      <circle cx="4" cy="4" r="1" fill="#5a8e3a" />
      <circle cx="10" cy="9" r="1" fill="#5a8e3a" />
      <circle cx="7" cy="12" r="0.8" fill="#5a8e3a" />
    </pattern>
    <pattern id="pat-fields" width="14" height="14" patternUnits="userSpaceOnUse">
      <rect width="14" height="14" fill="#d4a23a" />
      <line x1="0" y1="4" x2="14" y2="4" stroke="#a07b1f" strokeWidth="0.6" />
      <line x1="0" y1="10" x2="14" y2="10" stroke="#a07b1f" strokeWidth="0.6" />
      <line x1="3" y1="0" x2="3" y2="14" stroke="#a07b1f" strokeWidth="0.4" />
      <line x1="10" y1="0" x2="10" y2="14" stroke="#a07b1f" strokeWidth="0.4" />
    </pattern>
    <pattern id="pat-hills" width="14" height="14" patternUnits="userSpaceOnUse">
      <rect width="14" height="14" fill="#b86b3a" />
      <path d="M 2 9 L 5 5 L 8 9 Z" fill="#8a4a20" />
      <path d="M 8 11 L 11 7 L 14 11 Z" fill="#8a4a20" />
    </pattern>
    <pattern id="pat-mountains" width="14" height="14" patternUnits="userSpaceOnUse">
      <rect width="14" height="14" fill="#8a8d8f" />
      <path d="M 1 10 L 5 3 L 9 10 Z" fill="#5a5d5f" />
      <path d="M 7 12 L 11 6 L 15 12 Z" fill="#5a5d5f" />
    </pattern>
    <pattern id="pat-desert" width="14" height="14" patternUnits="userSpaceOnUse">
      <rect width="14" height="14" fill="#e6c878" />
      <path d="M 0 4 Q 7 2 14 4" stroke="#b89855" strokeWidth="0.5" fill="none" />
      <path d="M 0 9 Q 7 7 14 9" stroke="#b89855" strokeWidth="0.5" fill="none" />
      <circle cx="3" cy="12" r="0.5" fill="#b89855" />
      <circle cx="11" cy="13" r="0.5" fill="#b89855" />
    </pattern>
    <pattern id="pat-gold" width="14" height="14" patternUnits="userSpaceOnUse">
      <rect width="14" height="14" fill="#e6b840" />
      <circle cx="4" cy="4" r="1" fill="#b88820" />
      <circle cx="10" cy="9" r="1" fill="#b88820" />
      <circle cx="6" cy="12" r="0.6" fill="#fff5b0" />
      <circle cx="12" cy="3" r="0.6" fill="#fff5b0" />
    </pattern>
    <pattern id="pat-shallow_water" width="20" height="10" patternUnits="userSpaceOnUse">
      <rect width="20" height="10" fill="#3a6a8f" />
      <path d="M 0 3 Q 5 1 10 3 T 20 3" stroke="#5a8ab8" strokeWidth="0.5" fill="none" />
      <path d="M 0 7 Q 5 5 10 7 T 20 7" stroke="#5a8ab8" strokeWidth="0.5" fill="none" />
    </pattern>
    <pattern id="pat-deep_water" width="20" height="10" patternUnits="userSpaceOnUse">
      <rect width="20" height="10" fill="#1e3a5f" />
      <path d="M 0 4 Q 5 2 10 4 T 20 4" stroke="#2a4a70" strokeWidth="0.5" fill="none" />
      <path d="M 0 8 Q 5 6 10 8 T 20 8" stroke="#2a4a70" strokeWidth="0.5" fill="none" />
    </pattern>
  </>
)

export default function BoardView({ className }: BoardViewProps) {
  const snapshot = useGameStore((s) => s.snapshot)
  const submitAction = useGameStore((s) => s.submitAction)
  const buildMode = useUiStore((s) => s.buildMode)
  const setBuildMode = useUiStore((s) => s.setBuildMode)
  const boardTransform = useUiStore((s) => s.boardTransform)
  const setBoardTransform = useUiStore((s) => s.setBoardTransform)

  const [pendingInitialVertex, setPendingInitialVertex] = useState<number | null>(null)
  const [pendingRobberHex, setPendingRobberHex] = useState<HexCoord | null>(null)
  const [isDragging, setIsDragging] = useState(false)
  const dragRef = useRef<{ startX: number; startY: number; origX: number; origY: number } | null>(null)

  // 阶段/玩家变化时清空 pending
  useEffect(() => {
    setPendingInitialVertex(null)
    setPendingRobberHex(null)
  }, [snapshot?.phase, snapshot?.currentPlayerId])

  // Esc 取消
  useEffect(() => {
    const handler = (e: KeyboardEvent) => {
      if (e.key === 'Escape') {
        setPendingInitialVertex(null)
        setPendingRobberHex(null)
        setBuildMode({ kind: 'none' })
      }
    }
    window.addEventListener('keydown', handler)
    return () => window.removeEventListener('keydown', handler)
  }, [setBuildMode])

  if (!snapshot) return null

  const board = snapshot.board
  const bounds = computeBoardBounds(board)
  const portPairs = computePortPairs(board)

  const currentPlayer = snapshot.players.find((p) => p.id === snapshot.currentPlayerId)
  const isHumanTurn = !!currentPlayer && !currentPlayer.isAi

  // 计算有效交互模式
  let effectiveMode: BuildMode = buildMode
  if (snapshot.phase === 'setup_forward' || snapshot.phase === 'setup_reverse') {
    effectiveMode = { kind: 'place_initial' }
  } else if (snapshot.phase === 'robber_move') {
    effectiveMode = { kind: 'move_robber' }
  } else if (snapshot.phase !== 'action') {
    effectiveMode = { kind: 'none' }
  }

  const canInteract = isHumanTurn

  // 合法顶点
  const validVertices = new Set<number>()
  if (canInteract) {
    if (effectiveMode.kind === 'place_initial' && pendingInitialVertex === null) {
      for (const v of board.allVertices()) {
        if (isValidInitialVertex(board, snapshot, v.id)) {
          validVertices.add(v.id)
        }
      }
    } else if (
      effectiveMode.kind === 'build' &&
      (effectiveMode.building === 'settlement' || effectiveMode.building === 'city')
    ) {
      const building = effectiveMode.building as BuildingType
      for (const v of board.allVertices()) {
        const action = { type: 'build' as const, building, positionId: v.id }
        if (isOk(validate(action, snapshot, snapshot.currentPlayerId))) {
          validVertices.add(v.id)
        }
      }
    }
  }

  // 合法边
  const validEdges = new Set<number>()
  if (canInteract) {
    if (effectiveMode.kind === 'place_initial' && pendingInitialVertex !== null) {
      const adjEdges = board.vertexEdges(pendingInitialVertex)
      for (const eid of adjEdges) {
        const action = {
          type: 'place_initial' as const,
          vertexId: pendingInitialVertex,
          edgeId: eid,
        }
        if (isOk(validate(action, snapshot, snapshot.currentPlayerId))) {
          validEdges.add(eid)
        }
      }
    } else if (
      effectiveMode.kind === 'build' &&
      (effectiveMode.building === 'road' || effectiveMode.building === 'ship')
    ) {
      const building = effectiveMode.building as BuildingType
      for (const e of board.allEdges()) {
        const action = { type: 'build' as const, building, positionId: e.id }
        if (isOk(validate(action, snapshot, snapshot.currentPlayerId))) {
          validEdges.add(e.id)
        }
      }
    }
  }

  // 合法强盗六边形
  const validRobberHexes = new Set<string>()
  if (canInteract && effectiveMode.kind === 'move_robber') {
    for (const cell of board.allHexes()) {
      const terrain = TERRAINS[cell.terrainId]
      if (!terrain || !terrain.robberBlocks) continue
      if (snapshot.robberCoord && snapshot.robberCoord.equals(cell.coord)) continue
      validRobberHexes.add(cell.coord.toKey())
    }
  }

  // 处理点击
  function handleVertexClick(vertexId: number) {
    if (!canInteract) return
    if (effectiveMode.kind === 'place_initial') {
      if (validVertices.has(vertexId)) {
        setPendingInitialVertex(vertexId)
      }
    } else if (
      effectiveMode.kind === 'build' &&
      (effectiveMode.building === 'settlement' || effectiveMode.building === 'city')
    ) {
      if (validVertices.has(vertexId)) {
        void submitAction({
          type: 'build',
          building: effectiveMode.building,
          positionId: vertexId,
        })
        setBuildMode({ kind: 'none' })
      }
    }
  }

  function handleEdgeClick(edgeId: number) {
    if (!canInteract) return
    if (effectiveMode.kind === 'place_initial' && pendingInitialVertex !== null) {
      if (validEdges.has(edgeId)) {
        void submitAction({
          type: 'place_initial',
          vertexId: pendingInitialVertex,
          edgeId,
        })
        setPendingInitialVertex(null)
      }
    } else if (
      effectiveMode.kind === 'build' &&
      (effectiveMode.building === 'road' || effectiveMode.building === 'ship')
    ) {
      if (validEdges.has(edgeId)) {
        void submitAction({
          type: 'build',
          building: effectiveMode.building,
          positionId: edgeId,
        })
        setBuildMode({ kind: 'none' })
      }
    }
  }

  function handleHexClick(coord: HexCoord) {
    if (!canInteract || effectiveMode.kind !== 'move_robber') return
    if (!validRobberHexes.has(coord.toKey())) return
    const candidates = getStealCandidates(snapshot, coord)
    if (candidates.length <= 1) {
      void submitAction({
        type: 'move_robber',
        hexCoord: coord,
        stealTargetPlayerId: candidates[0],
      })
    } else {
      setPendingRobberHex(new HexCoord(coord.q, coord.r))
    }
  }

  function handlePickStealTarget(playerId: string) {
    if (!pendingRobberHex) return
    void submitAction({
      type: 'move_robber',
      hexCoord: pendingRobberHex,
      stealTargetPlayerId: playerId,
    })
    setPendingRobberHex(null)
  }

  // 平移与缩放
  function handleWheel(e: React.WheelEvent) {
    // 注意：React onWheel 默认 passive，无法 preventDefault，但缩放无需阻止滚动
    const delta = -e.deltaY * 0.0015
    const newScale = Math.max(0.4, Math.min(3, boardTransform.scale * (1 + delta)))
    setBoardTransform({ ...boardTransform, scale: newScale })
  }

  function handleMouseDown(e: React.MouseEvent) {
    if (e.button !== 0) return
    const target = e.target as Element
    // 点击在交互槽/可选六边形上时不平移
    if (target.closest('.vertex-slot, .edge-slot, .hex-selectable')) return
    dragRef.current = {
      startX: e.clientX,
      startY: e.clientY,
      origX: boardTransform.x,
      origY: boardTransform.y,
    }
    setIsDragging(true)
  }

  function handleMouseMove(e: React.MouseEvent) {
    if (!dragRef.current) return
    const dx = e.clientX - dragRef.current.startX
    const dy = e.clientY - dragRef.current.startY
    setBoardTransform({
      ...boardTransform,
      x: dragRef.current.origX + dx,
      y: dragRef.current.origY + dy,
    })
  }

  function handleMouseUp() {
    dragRef.current = null
    setIsDragging(false)
  }

  // 渲染单个建筑
  function renderBuilding(b: BuildingInstance) {
    const player = snapshot.players.find((p) => p.id === b.ownerId)
    if (!player) return null
    const color = player.color
    if (b.positionType === 'vertex') {
      const v = board.getVertex(b.positionId)
      if (!v) return null
      const { x, y } = vertexPhysToPixel(v.physX, v.physY)
      if (b.type === 'settlement') {
        return <SettlementOnBoard key={`b-${b.id}`} cx={x} cy={y} color={color} />
      } else if (b.type === 'city') {
        return <CityOnBoard key={`b-${b.id}`} cx={x} cy={y} color={color} />
      }
    } else if (b.positionType === 'edge') {
      const [v1, v2] = board.edgeVertices(b.positionId)
      const vd1 = board.getVertex(v1)
      const vd2 = board.getVertex(v2)
      if (!vd1 || !vd2) return null
      const p1 = vertexPhysToPixel(vd1.physX, vd1.physY)
      const p2 = vertexPhysToPixel(vd2.physX, vd2.physY)
      if (b.type === 'road') {
        return <RoadOnBoard key={`b-${b.id}`} x1={p1.x} y1={p1.y} x2={p2.x} y2={p2.y} color={color} />
      } else if (b.type === 'ship') {
        return <ShipOnBoard key={`b-${b.id}`} x1={p1.x} y1={p1.y} x2={p2.x} y2={p2.y} color={color} />
      }
    }
    return null
  }

  // 强盗
  const robberElement = snapshot.robberCoord
    ? (() => {
        const { x, y } = hexToPixel(snapshot.robberCoord)
        return <Robber cx={x} cy={y} />
      })()
    : null

  // 偷取目标选择浮层
  let robberStealOverlay: React.ReactNode = null
  if (pendingRobberHex) {
    const candidates = getStealCandidates(snapshot, pendingRobberHex)
    const { x, y } = hexToPixel(pendingRobberHex)
    robberStealOverlay = (
      <g pointerEvents="all">
        {/* 半透明遮罩阻止其他点击 */}
        <rect
          x={bounds.minX - 100}
          y={bounds.minY - 100}
          width={bounds.width + 200}
          height={bounds.height + 200}
          fill="rgba(15,36,56,0.4)"
          onClick={(e) => {
            e.stopPropagation()
            setPendingRobberHex(null)
          }}
        />
        {candidates.map((pid, i) => {
          const player = snapshot.players.find((p) => p.id === pid)
          if (!player) return null
          const c = PLAYER_COLOR_HEX[player.color]
          const angle = (i / candidates.length) * 2 * Math.PI - Math.PI / 2
          const px = x + Math.cos(angle) * 60
          const py = y + Math.sin(angle) * 60
          return (
            <g
              key={pid}
              transform={`translate(${px} ${py})`}
              onClick={(e) => {
                e.stopPropagation()
                handlePickStealTarget(pid)
              }}
              style={{ cursor: 'pointer' }}
              className="animate-fadeIn"
            >
              <circle r="22" fill={c.main} stroke="#2b1810" strokeWidth="2" />
              <text
                x="0"
                y="2"
                textAnchor="middle"
                dominantBaseline="middle"
                fontSize="11"
                fontFamily="'Cinzel', serif"
                fontWeight="700"
                fill={c.text}
              >
                {player.name.slice(0, 2)}
              </text>
            </g>
          )
        })}
        {/* 提示文字 */}
        <g transform={`translate(${x} ${y - 50})`} pointerEvents="none">
          <rect x="-60" y="-12" width="120" height="20" fill="#f0e2c1" stroke="#2b1810" strokeWidth="1" rx="3" />
          <text
            x="0"
            y="0"
            textAnchor="middle"
            dominantBaseline="middle"
            fontSize="11"
            fontFamily="'Cinzel', serif"
            fontWeight="600"
            fill="#2b1810"
          >
            选择偷取目标
          </text>
        </g>
      </g>
    )
  }

  const interactionHint = canInteract
    ? getInteractionHint(effectiveMode, pendingInitialVertex, pendingRobberHex)
    : ''

  return (
    <div
      className={`ocean-bg relative overflow-hidden select-none ${className ?? ''}`}
      onWheel={handleWheel}
      onMouseDown={handleMouseDown}
      onMouseMove={handleMouseMove}
      onMouseUp={handleMouseUp}
      onMouseLeave={handleMouseUp}
      style={{ cursor: isDragging ? 'grabbing' : 'grab' }}
    >
      <svg
        className="board-svg"
        viewBox={`${bounds.minX} ${bounds.minY} ${bounds.width} ${bounds.height}`}
        preserveAspectRatio="xMidYMid meet"
        style={{
          width: '100%',
          height: '100%',
          transform: `translate(${boardTransform.x}px, ${boardTransform.y}px) scale(${boardTransform.scale})`,
          transformOrigin: 'center center',
        }}
      >
        <defs>{TERRAIN_PATTERNS}</defs>

        {/* 1. 海洋六边形（先渲染作为底图） */}
        {board
          .allHexes()
          .filter((c) => TERRAINS[c.terrainId]?.category === 'sea')
          .map((cell) => {
            const { x, y } = hexToPixel(cell.coord)
            return (
              <HexTile
                key={`hex-${cell.id}`}
                cx={x}
                cy={y}
                terrainId={cell.terrainId}
                showToken={false}
              />
            )
          })}

        {/* 2. 陆地六边形（可点击用于强盗移动） */}
        {board
          .allHexes()
          .filter((c) => TERRAINS[c.terrainId]?.category === 'land')
          .map((cell) => {
            const { x, y } = hexToPixel(cell.coord)
            const isRobberTarget =
              effectiveMode.kind === 'move_robber' && validRobberHexes.has(cell.coord.toKey())
            return (
              <HexTile
                key={`hex-${cell.id}`}
                cx={x}
                cy={y}
                terrainId={cell.terrainId}
                numberToken={cell.numberToken}
                selectable={isRobberTarget}
                onClick={isRobberTarget ? () => handleHexClick(cell.coord) : undefined}
                highlighted={pendingRobberHex?.equals(cell.coord) ?? false}
              />
            )
          })}

        {/* 3. 港口 */}
        {portPairs.map((p, i) => {
          const vd1 = board.getVertex(p.v1)
          const vd2 = board.getVertex(p.v2)
          if (!vd1 || !vd2) return null
          const pp1 = vertexPhysToPixel(vd1.physX, vd1.physY)
          const pp2 = vertexPhysToPixel(vd2.physX, vd2.physY)
          const mx = (pp1.x + pp2.x) / 2
          const my = (pp1.y + pp2.y) / 2
          // 从棋盘中心向外偏移
          const dx = mx
          const dy = my
          const len = Math.sqrt(dx * dx + dy * dy) || 1
          const px = mx + (dx / len) * 22
          const py = my + (dy / len) * 22
          return <PortIndicator key={`port-${i}`} cx={px} cy={py} portId={p.portId} />
        })}

        {/* 4. 道路与船只（先于建筑） */}
        {snapshot.buildings
          .filter((b) => b.type === 'road' || b.type === 'ship')
          .map(renderBuilding)}

        {/* 5. 顶点建筑：定居点 / 城市 */}
        {snapshot.buildings
          .filter((b) => b.type === 'settlement' || b.type === 'city')
          .map(renderBuilding)}

        {/* 6. 强盗 */}
        {robberElement}

        {/* 7. 交互槽：边 */}
        {Array.from(validEdges).map((eid) => {
          const [v1, v2] = board.edgeVertices(eid)
          const vd1 = board.getVertex(v1)
          const vd2 = board.getVertex(v2)
          if (!vd1 || !vd2) return null
          const p1 = vertexPhysToPixel(vd1.physX, vd1.physY)
          const p2 = vertexPhysToPixel(vd2.physX, vd2.physY)
          return (
            <EdgeSlot
              key={`slot-e-${eid}`}
              x1={p1.x}
              y1={p1.y}
              x2={p2.x}
              y2={p2.y}
              active
              onClick={() => handleEdgeClick(eid)}
            />
          )
        })}

        {/* 8. 交互槽：顶点 */}
        {Array.from(validVertices).map((vid) => {
          const v = board.getVertex(vid)
          if (!v) return null
          const { x, y } = vertexPhysToPixel(v.physX, v.physY)
          return (
            <VertexSlot
              key={`slot-v-${vid}`}
              cx={x}
              cy={y}
              active
              selected={pendingInitialVertex === vid}
              onClick={() => handleVertexClick(vid)}
            />
          )
        })}

        {/* 9. 偷取目标浮层 */}
        {robberStealOverlay}
      </svg>

      {/* 交互提示 */}
      {interactionHint && (
        <div className="absolute top-2 left-2 parchment-card px-3 py-1.5 text-xs font-display text-ink-700 pointer-events-none animate-fadeIn">
          {interactionHint}
        </div>
      )}

      {/* 缩放控制 */}
      <div className="absolute bottom-2 right-2 flex flex-col gap-1">
        <button
          className="ink-button !px-2 !py-1 text-sm"
          onClick={() =>
            setBoardTransform({ ...boardTransform, scale: Math.min(3, boardTransform.scale * 1.2) })
          }
          aria-label="放大"
        >
          +
        </button>
        <button
          className="ink-button !px-2 !py-1 text-sm"
          onClick={() =>
            setBoardTransform({ ...boardTransform, scale: Math.max(0.4, boardTransform.scale / 1.2) })
          }
          aria-label="缩小"
        >
          −
        </button>
        <button
          className="ink-button !px-2 !py-1 text-xs"
          onClick={() => setBoardTransform({ x: 0, y: 0, scale: 1 })}
        >
          复位
        </button>
      </div>
    </div>
  )
}
