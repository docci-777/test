import { useEffect, useRef } from 'react'
import { useGameStore } from '@/store/gameStore'
import { PLAYER_COLOR_HEX } from '@/utils/colors'
import Parchment from '@/components/ui/Parchment'
import type { LogEntry } from '@/core/gameState'

const KIND_ICON: Record<LogEntry['kind'], string> = {
  roll: '🎲',
  produce: '📦',
  build: '🔨',
  trade: '🤝',
  robber: '🥷',
  dev_card: '📜',
  phase: '⏳',
  victory: '👑',
  info: '•',
}

export default function TurnLog() {
  const snapshot = useGameStore((s) => s.snapshot)
  const scrollRef = useRef<HTMLDivElement>(null)

  useEffect(() => {
    if (scrollRef.current) {
      scrollRef.current.scrollTop = scrollRef.current.scrollHeight
    }
  }, [snapshot?.log.length])

  if (!snapshot) return null

  return (
    <Parchment className="p-2 flex flex-col h-full min-h-0">
      <div className="flex items-center gap-2 pb-1 mb-1 border-b border-ink-700/20">
        <span className="font-display font-bold text-sm text-ink-700">回合日志</span>
      </div>
      <div
        ref={scrollRef}
        className="flex-1 overflow-y-auto text-[11px] flex flex-col gap-0.5 min-h-0"
      >
        {snapshot.log.map((entry, i) => {
          const player = entry.playerId
            ? snapshot.players.find((p) => p.id === entry.playerId)
            : null
          const c = player ? PLAYER_COLOR_HEX[player.color] : null
          return (
            <div
              key={i}
              className="flex items-start gap-1.5 px-1 py-0.5 rounded hover:bg-ink-700/5"
            >
              <span className="text-xs leading-tight">{KIND_ICON[entry.kind]}</span>
              <span className="text-[10px] text-ink-700/50 font-mono leading-tight mt-0.5">
                T{entry.turn}
              </span>
              {player && (
                <span
                  className="text-[10px] font-display font-bold leading-tight mt-0.5"
                  style={{ color: c!.dark }}
                >
                  {player.name}
                </span>
              )}
              <span className="text-ink-700/85 leading-tight flex-1">{entry.text}</span>
            </div>
          )
        })}
      </div>
    </Parchment>
  )
}
