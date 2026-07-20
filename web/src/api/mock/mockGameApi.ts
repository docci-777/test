import type { GameApi, ApiResponse, SessionCreated, Unsubscribe } from '../types'
import type { GameAction, GameEvent } from '@/core/actions/types'
import type { GameState } from '@/core/gameState'
import type { SessionConfig } from '@/app/boardGenerator'
import { createInitialState } from '@/app/boardGenerator'
import { GameSession } from '@/app/gameSession'

// Mock 实现：所有状态保存在内存中，复用前端规则引擎
// 未来联机时，将此类替换为 HttpGameApi / WsGameApi 即可
class MockGameApiImpl implements GameApi {
  private sessions: Map<string, { session: GameSession; state: GameState; events: GameEvent[]; subscribers: Set<(e: GameEvent) => void> }> = new Map()
  private nextId = 1

  async createSession(config: SessionConfig): Promise<ApiResponse<SessionCreated>> {
    const state = createInitialState(config)
    const sessionId = `s${this.nextId++}`
    const seed = config.seed || sessionId
    const session = new GameSession(state, seed)
    this.sessions.set(sessionId, {
      session,
      state,
      events: [],
      subscribers: new Set(),
    })
    return {
      ok: true,
      events: [],
      snapshot: state,
      data: { sessionId, playerId: state.turnOrder[0] },
    }
  }

  async submitAction(
    sessionId: string,
    playerId: string,
    action: GameAction,
  ): Promise<ApiResponse<void>> {
    const entry = this.sessions.get(sessionId)
    if (!entry) {
      return {
        ok: false,
        error: { code: 'session_not_found', message: '会话不存在' },
        events: [],
        snapshot: null as unknown as GameState,
      }
    }
    const result = entry.session.submit(action, playerId)
    if (!result.ok) {
      return {
        ok: false,
        error: { code: 'submit_failed', message: '提交失败' },
        events: [],
        snapshot: entry.session.state,
      }
    }
    entry.state = result.value.state
    entry.events.push(...result.value.events)
    // 通知订阅者
    for (const e of result.value.events) {
      for (const cb of entry.subscribers) cb(e)
    }
    return {
      ok: true,
      events: result.value.events,
      snapshot: entry.session.state,
    }
  }

  async getSnapshot(sessionId: string, _playerId: string): Promise<ApiResponse<null>> {
    const entry = this.sessions.get(sessionId)
    if (!entry) {
      return {
        ok: false,
        error: { code: 'session_not_found', message: '会话不存在' },
        events: [],
        snapshot: null as unknown as GameState,
      }
    }
    return {
      ok: true,
      events: [],
      snapshot: entry.session.state,
    }
  }

  subscribeEvents(sessionId: string, onEvent: (e: GameEvent) => void): Unsubscribe {
    const entry = this.sessions.get(sessionId)
    if (!entry) return () => {}
    entry.subscribers.add(onEvent)
    return () => entry.subscribers.delete(onEvent)
  }
}

// 当前 mock 单例
export const mockGameApi: GameApi = new MockGameApiImpl()

// 未来真实实现（HTTP）应实现同一 GameApi 接口
// export const httpGameApi: GameApi = new HttpGameApiImpl()
