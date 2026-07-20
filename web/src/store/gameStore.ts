import { create } from 'zustand'
import type { GameEvent } from '@/core/actions/types'
import type { GameState } from '@/core/gameState'
import type { SessionConfig } from '@/app/boardGenerator'
import { gameApi } from '@/api/gameApi'
import { decideAiAction } from '@/app/aiController'
import { createInitialState } from '@/app/boardGenerator'

export type Screen = 'menu' | 'game' | 'victory'

interface GameStoreState {
  screen: Screen
  config: SessionConfig
  sessionId: string | null
  snapshot: GameState | null
  lastError: string | null
  pendingActionEvents: GameEvent[]

  startGame: (config: SessionConfig) => Promise<void>
  submitAction: (action: import('@/core/actions/types').GameAction) => Promise<boolean>
  backToMenu: () => void
  setScreen: (s: Screen) => void
  clearError: () => void
  advanceAi: () => Promise<void>
  initSession: (state: GameState, sessionId: string) => void
}

// 注意：单机 mock 模式下我们直接持有 GameState，无需 API 往返
// 但仍通过 gameApi 接口提交，保持架构一致
export const useGameStore = create<GameStoreState>((set, get) => ({
  screen: 'menu',
  config: { playerCount: 4, aiCount: 3, scenarioId: 'base_4p', seed: '', victoryPointThreshold: 10 },
  sessionId: null,
  snapshot: null,
  lastError: null,
  pendingActionEvents: [],

  async startGame(config) {
    // 单机直接初始化状态
    const state = createInitialState(config)
    set({
      screen: 'game',
      config,
      snapshot: state,
      sessionId: 'local',
      lastError: null,
      pendingActionEvents: [],
    })
  },

  async submitAction(action) {
    const state = get().snapshot
    if (!state) return false
    // 单机模式下直接在 store 内调用规则引擎，避免异步开销
    // 但为保持架构一致，这里走 mock API
    // 由于 mock API 是异步的，我们直接同步处理
    const sessionId = get().sessionId ?? 'local'
    if (sessionId === 'local') {
      // 直接本地处理
      const { apply } = await import('@/core/rulesEngine')
      const { Rng, seedFromString } = await import('@/core/rng')
      const rng = new Rng(seedFromString(get().config.seed || 'local') ^ state.turn)
      const { validate } = await import('@/core/rulesEngine')
      const playerId = state.currentPlayerId
      const v = validate(action, state, playerId)
      if (!v.ok) {
        set({ lastError: (v as { error: { message: string } }).error.message })
        return false
      }
      const r = apply(action, state, playerId, rng)
      if (!r.ok) {
        set({ lastError: (r as { error: { message: string } }).error.message })
        return false
      }
      const newState = r.value.state as GameState
      set({
        snapshot: newState,
        pendingActionEvents: r.value.events,
        lastError: null,
        screen: newState.phase === 'game_over' ? 'victory' : 'game',
      })
      return true
    }
    // 联机模式（未实现）
    const res = await gameApi.submitAction(sessionId, state.currentPlayerId, action)
    if (!res.ok) {
      set({ lastError: res.error?.message ?? '未知错误' })
      return false
    }
    set({
      snapshot: res.snapshot,
      pendingActionEvents: res.events,
      lastError: null,
      screen: res.snapshot.phase === 'game_over' ? 'victory' : 'game',
    })
    return true
  },

  async advanceAi() {
    const state = get().snapshot
    if (!state) return
    const currentPlayer = state.players.find((p) => p.id === state.currentPlayerId)
    if (!currentPlayer?.isAi) return
    const action = decideAiAction(state, currentPlayer.id)
    if (action) {
      await get().submitAction(action)
    }
  },

  backToMenu() {
    set({ screen: 'menu', snapshot: null, sessionId: null, lastError: null, pendingActionEvents: [] })
  },

  setScreen(s) {
    set({ screen: s })
  },

  clearError() {
    set({ lastError: null })
  },

  initSession(state, sessionId) {
    set({ snapshot: state, sessionId, screen: 'game' })
  },
}))
