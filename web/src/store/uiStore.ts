import { create } from 'zustand'
import type { BuildingType } from '@/core/data/types'
import type { HexCoord } from '@/core/hexCoord'

// UI 交互状态
export type BuildMode =
  | { kind: 'none' }
  | { kind: 'build'; building: BuildingType }
  | { kind: 'place_initial' }
  | { kind: 'move_robber' }

export type DialogKind =
  | 'none'
  | 'trade'
  | 'discard'
  | 'robber_move'
  | 'gold_choice'
  | 'monopoly'
  | 'year_of_plenty'
  | 'victory'
  | 'rules'

interface UiStoreState {
  buildMode: BuildMode
  dialog: DialogKind
  selectedHex: HexCoord | null
  hoveredVertex: number | null
  hoveredEdge: number | null
  boardTransform: { x: number; y: number; scale: number }

  setBuildMode: (m: BuildMode) => void
  setDialog: (d: DialogKind) => void
  setSelectedHex: (h: HexCoord | null) => void
  setHoveredVertex: (v: number | null) => void
  setHoveredEdge: (e: number | null) => void
  setBoardTransform: (t: { x: number; y: number; scale: number }) => void
  reset: () => void
}

export const useUiStore = create<UiStoreState>((set) => ({
  buildMode: { kind: 'none' },
  dialog: 'none',
  selectedHex: null,
  hoveredVertex: null,
  hoveredEdge: null,
  boardTransform: { x: 0, y: 0, scale: 1 },

  setBuildMode(m) {
    set({ buildMode: m })
  },
  setDialog(d) {
    set({ dialog: d })
  },
  setSelectedHex(h) {
    set({ selectedHex: h })
  },
  setHoveredVertex(v) {
    set({ hoveredVertex: v })
  },
  setHoveredEdge(e) {
    set({ hoveredEdge: e })
  },
  setBoardTransform(t) {
    set({ boardTransform: t })
  },
  reset() {
    set({
      buildMode: { kind: 'none' },
      dialog: 'none',
      selectedHex: null,
      hoveredVertex: null,
      hoveredEdge: null,
      boardTransform: { x: 0, y: 0, scale: 1 },
    })
  },
}))
