import { useGameStore } from '@/store/gameStore'
import { PLAYER_COLOR_HEX } from '@/utils/colors'
import { publicVictoryPoints, handSize } from '@/core/gameState'
import { Crown, Swords, Route } from 'lucide-react'
import { cn } from '@/lib/utils'

// 顶部玩家信息条
export default function PlayerBar() {
  const snapshot = useGameStore((s) => s.snapshot)
  if (!snapshot) return null

  return (
    <div className="parchment-card border-x-0 border-t-0 px-4 py-2 flex items-center gap-3 overflow-x-auto">
      {snapshot.players.map((p) => {
        const c = PLAYER_COLOR_HEX[p.color]
        const isCurrent = p.id === snapshot.currentPlayerId
        const vp = publicVictoryPoints(p, snapshot)
        const cards = handSize(p.hand)
        const devCount = p.devCards.length
        const hasLongestRoad = snapshot.longestRoadPlayerId === p.id
        const hasLargestArmy = snapshot.largestArmyPlayerId === p.id
        return (
          <div
            key={p.id}
            className={cn(
              'relative flex items-center gap-2 px-3 py-1.5 rounded-md border-2 transition-all min-w-[160px]',
              isCurrent ? 'scale-105 shadow-lg' : 'opacity-70',
            )}
            style={{
              backgroundColor: c.main,
              borderColor: isCurrent ? '#e6b840' : c.dark,
              color: c.text,
            }}
          >
            {/* 颜色徽章 */}
            <div
              className="w-3 h-3 rounded-full border border-ink-700"
              style={{ backgroundColor: c.dark }}
            />
            <div className="flex flex-col flex-1">
              <div className="flex items-center gap-1">
                <span className="font-display font-bold text-sm">{p.name}</span>
                {p.isAi && (
                  <span className="badge text-[8px] !py-0 !px-1" style={{ color: c.text }}>
                    AI
                  </span>
                )}
                {isCurrent && (
                  <span className="text-[10px] animate-pulse">▼</span>
                )}
              </div>
              <div className="flex items-center gap-2 text-[10px] opacity-90">
                <span>胜利点 <strong className="font-display text-xs">{vp}</strong></span>
                <span>资源 {cards}</span>
                <span>卡 {devCount}</span>
              </div>
            </div>
            {/* 最长道路/最大军队徽章 */}
            <div className="flex flex-col gap-0.5">
              {hasLongestRoad && (
                <div
                  className="flex items-center gap-0.5 px-1 rounded text-[9px] font-display"
                  style={{ backgroundColor: 'rgba(255,255,255,0.25)' }}
                  title="最长道路 +2 VP"
                >
                  <Route size={9} /> 2
                </div>
              )}
              {hasLargestArmy && (
                <div
                  className="flex items-center gap-0.5 px-1 rounded text-[9px] font-display"
                  style={{ backgroundColor: 'rgba(255,255,255,0.25)' }}
                  title="最大军队 +2 VP"
                >
                  <Swords size={9} /> 2
                </div>
              )}
            </div>
            {/* 当前玩家皇冠 */}
            {isCurrent && (
              <Crown
                size={16}
                className="absolute -top-2 -right-1 text-gold drop-shadow"
                fill="#e6b840"
              />
            )}
          </div>
        )
      })}
    </div>
  )
}
