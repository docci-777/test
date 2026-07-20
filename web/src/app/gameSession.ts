import { type GameState } from '@/core/gameState'
import { type GameAction, type GameEvent } from '@/core/actions/types'
import { apply, validate } from '@/core/rulesEngine'
import { Rng, seedFromString } from '@/core/rng'
import { ok, err, type Result, isErr } from '@/core/result'

export interface SubmitResult {
  state: GameState
  events: GameEvent[]
}

// 单机 mock session：直接持有 GameState
export class GameSession {
  state: GameState
  private rng: Rng
  private seed: string

  constructor(state: GameState, seed: string) {
    this.state = state
    this.seed = seed
    // 用种子 + 当前回合 + 已处理动作数 派生随机流，保证可复现
    this.rng = new Rng(seedFromString(seed) ^ state.turn)
  }

  submit(action: GameAction, playerId: string): Result<SubmitResult> {
    // 校验
    const v = validate(action, this.state, playerId)
    if (isErr(v)) return err(v.error.code, v.error.message)
    // 应用
    const r = apply(action, this.state, playerId, this.rng)
    if (isErr(r)) return err(r.error.code, r.error.message)
    this.state = r.value.state as GameState
    return ok({ state: this.state, events: r.value.events })
  }

  // 验证动作是否合法（不修改状态）
  canApply(action: GameAction, playerId: string): Result<void> {
    return validate(action, this.state, playerId)
  }
}
