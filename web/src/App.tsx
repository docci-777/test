import { useEffect } from 'react'
import { useGameStore } from '@/store/gameStore'
import MainMenu from '@/pages/MainMenu'
import GameScreen from '@/pages/GameScreen'
import VictoryScreen from '@/pages/VictoryScreen'

export default function App() {
  const screen = useGameStore((s) => s.screen)
  const snapshot = useGameStore((s) => s.snapshot)
  const advanceAi = useGameStore((s) => s.advanceAi)

  const currentPlayerId = snapshot?.currentPlayerId ?? null
  const currentPlayer = snapshot?.players.find((p) => p.id === currentPlayerId) ?? null

  // AI 自动行动
  useEffect(() => {
    if (screen !== 'game' || !currentPlayer || !currentPlayer.isAi) return
    const timer = setTimeout(() => {
      void advanceAi()
    }, 600)
    return () => clearTimeout(timer)
  }, [screen, currentPlayer, advanceAi, snapshot])

  if (screen === 'menu') return <MainMenu />
  if (screen === 'victory') return <VictoryScreen />
  return <GameScreen />
}
