import { useGameStore } from '@/store/gameStore'
import { useUiStore } from '@/store/uiStore'
import InkButton from '@/components/ui/InkButton'
import Dice3D from '@/components/dice/Dice3D'
import { PLAYER_COLOR_HEX, PLAYER_NAMES } from '@/utils/colors'

const PHASE_TEXT: Record<string, string> = {
  setup_forward: '初始放置 · 正序',
  setup_reverse: '初始放置 · 逆序',
  roll: '掷骰阶段',
  action: '行动阶段',
  robber_discard: '弃牌阶段',
  robber_move: '强盗移动',
  robber_steal: '强盗偷取',
  game_over: '游戏结束',
}

// 顶部阶段提示条 + 掷骰/结束回合按钮
export default function PhaseHint() {
  const snapshot = useGameStore((s) => s.snapshot)
  const submitAction = useGameStore((s) => s.submitAction)
  const setDialog = useUiStore((s) => s.setDialog)
  const clearError = useGameStore((s) => s.clearError)
  const lastError = useGameStore((s) => s.lastError)

  if (!snapshot) return null

  const currentPlayer = snapshot.players.find((p) => p.id === snapshot.currentPlayerId)
  if (!currentPlayer) return null
  const c = PLAYER_COLOR_HEX[currentPlayer.color]
  const isHuman = !currentPlayer.isAi
  const phaseText = PHASE_TEXT[snapshot.phase] ?? snapshot.phase

  return (
    <div className="parchment-card px-4 py-2 flex items-center gap-3 flex-wrap">
      {/* 当前玩家徽章 */}
      <div
        className="flex items-center gap-2 px-3 py-1 rounded-md border-2"
        style={{ backgroundColor: c.main, borderColor: c.dark, color: c.text }}
      >
        <div className="w-2 h-2 rounded-full" style={{ backgroundColor: c.dark }} />
        <span className="font-display font-bold text-sm">{currentPlayer.name}</span>
      </div>

      {/* 阶段文字 */}
      <div className="flex flex-col">
        <span className="font-display text-xs text-ink-700/70">阶段</span>
        <span className="font-display text-sm font-bold text-ink-700">{phaseText}</span>
      </div>

      {/* 回合 */}
      <div className="flex flex-col">
        <span className="font-display text-xs text-ink-700/70">回合</span>
        <span className="font-display text-sm font-bold text-ink-700">{snapshot.turn + 1}</span>
      </div>

      {/* 骰子 */}
      {snapshot.dice && (
        <div className="flex items-center gap-2">
          <Dice3D value={snapshot.dice.d1} size={32} />
          <Dice3D value={snapshot.dice.d2} size={32} />
          <span className="font-display font-bold text-lg text-ink-700">
            = {snapshot.dice.total}
          </span>
          {snapshot.dice.total === 7 && (
            <span className="text-crimson font-display text-xs animate-pulse">强盗！</span>
          )}
        </div>
      )}

      <div className="flex-1" />

      {/* 错误提示 */}
      {lastError && (
        <div className="flex items-center gap-2 px-3 py-1 bg-crimson/15 border border-crimson rounded-md animate-fadeIn">
          <span className="text-xs text-crimson font-display">{lastError}</span>
          <button
            className="text-crimson/70 hover:text-crimson"
            onClick={clearError}
            aria-label="关闭错误"
          >
            ✕
          </button>
        </div>
      )}

      {/* 操作按钮 */}
      {isHuman && (
        <div className="flex items-center gap-2">
          {snapshot.phase === 'roll' && (
            <InkButton
              variant="primary"
              size="sm"
              onClick={() => void submitAction({ type: 'roll_dice' })}
            >
              掷骰子
            </InkButton>
          )}
          {snapshot.phase === 'action' && (
            <>
              <InkButton size="sm" variant="ghost" onClick={() => setDialog('trade')}>
                交易
              </InkButton>
              <InkButton
                size="sm"
                onClick={() => void submitAction({ type: 'end_turn' })}
              >
                结束回合
              </InkButton>
            </>
          )}
          {snapshot.phase === 'robber_discard' && (
            <span className="text-xs text-ink-700 font-display">请弃牌…</span>
          )}
          {snapshot.phase === 'game_over' && (
            <span className="text-xs text-gold font-display font-bold animate-pulse">
              {PLAYER_NAMES[currentPlayer.color]} 获胜！
            </span>
          )}
        </div>
      )}
      {!isHuman && snapshot.phase !== 'game_over' && (
        <span className="text-xs text-ink-700/70 font-display animate-pulse">
          AI 思考中…
        </span>
      )}
    </div>
  )
}
