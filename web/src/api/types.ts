import type { GameAction, GameEvent } from '@/core/actions/types'
import type { GameState } from '@/core/gameState'
import type { SessionConfig } from '@/app/boardGenerator'

// API 协议类型（与后端协议对齐，未来切换 HTTP 时复用）
export interface ApiResponse<TData> {
  ok: boolean
  error?: { code: string; message: string }
  data?: TData
  events: GameEvent[]
  snapshot: GameState
}

export interface SessionCreated {
  sessionId: string
  playerId: string
}

export type Unsubscribe = () => void

export interface GameApi {
  createSession(config: SessionConfig): Promise<ApiResponse<SessionCreated>>
  submitAction(
    sessionId: string,
    playerId: string,
    action: GameAction,
  ): Promise<ApiResponse<void>>
  getSnapshot(sessionId: string, playerId: string): Promise<ApiResponse<null>>
  subscribeEvents(sessionId: string, onEvent: (e: GameEvent) => void): Unsubscribe
}
