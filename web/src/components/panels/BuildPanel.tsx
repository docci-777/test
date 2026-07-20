import { useGameStore } from '@/store/gameStore'
import { useUiStore } from '@/store/uiStore'
import InkButton from '@/components/ui/InkButton'
import { BUILDINGS } from '@/core/data/buildings'
import { RESOURCE_INFO } from '@/utils/colors'
import { canAfford } from '@/core/gameState'
import type { BuildingType, ResourceType } from '@/core/data/types'
import { cn } from '@/lib/utils'

interface BuildButtonDef {
  building: BuildingType
  emoji: string
  cost: Partial<Record<ResourceType, number>>
}

const BUILD_BUTTONS: BuildButtonDef[] = [
  { building: 'settlement', emoji: '🏠', cost: BUILDINGS.settlement.cost },
  { building: 'city', emoji: '🏛', cost: BUILDINGS.city.cost },
  { building: 'road', emoji: '🛣', cost: BUILDINGS.road.cost },
  { building: 'ship', emoji: '⛵', cost: BUILDINGS.ship.cost },
  { building: 'dev_card', emoji: '📜', cost: BUILDINGS.dev_card.cost },
]

function CostBadge({ cost }: { cost: Partial<Record<ResourceType, number>> }) {
  return (
    <div className="flex items-center gap-1 text-[10px] flex-wrap justify-center">
      {(Object.keys(cost) as ResourceType[]).map((r) => (
        <span key={r} className="flex items-center gap-0.5" title={RESOURCE_INFO[r].name}>
          <span>{RESOURCE_INFO[r].icon}</span>
          <span className="font-display font-bold">{cost[r]}</span>
        </span>
      ))}
    </div>
  )
}

export default function BuildPanel() {
  const snapshot = useGameStore((s) => s.snapshot)
  const submitAction = useGameStore((s) => s.submitAction)
  const buildMode = useUiStore((s) => s.buildMode)
  const setBuildMode = useUiStore((s) => s.setBuildMode)

  if (!snapshot) return null

  const currentPlayer = snapshot.players.find((p) => p.id === snapshot.currentPlayerId)
  if (!currentPlayer || currentPlayer.isAi) return null
  if (snapshot.phase !== 'action') return null

  function handleBuildClick(b: BuildingType) {
    if (b === 'dev_card') {
      void submitAction({ type: 'buy_dev_card' })
      return
    }
    const current = buildMode.kind === 'build' ? buildMode.building : null
    if (current === b) {
      setBuildMode({ kind: 'none' })
    } else {
      setBuildMode({ kind: 'build', building: b })
    }
  }

  function isActive(b: BuildingType): boolean {
    return buildMode.kind === 'build' && buildMode.building === b
  }

  return (
    <div className="parchment-card px-3 py-2 flex items-center gap-2 overflow-x-auto">
      <span className="font-display text-xs font-bold text-ink-700/70 whitespace-nowrap">
        建造
      </span>
      <div className="flex items-center gap-1.5">
        {BUILD_BUTTONS.map((b) => {
          const def = BUILDINGS[b.building]
          const affordable = canAfford(currentPlayer.hand, b.cost)
          // 道路建设卡激活中：道路免费
          const isFreeRoad =
            b.building === 'road' &&
            currentPlayer.freeRoadsRemaining > 0 &&
            snapshot.pendingRoadBuilding === currentPlayer.id
          const enabled = affordable || isFreeRoad
          const active = isActive(b.building)
          return (
            <InkButton
              key={b.building}
              size="sm"
              variant={active ? 'primary' : 'default'}
              disabled={!enabled}
              onClick={() => handleBuildClick(b.building)}
              className={cn('flex flex-col items-center !py-1.5 !px-2 min-w-[68px]', active && 'animate-glow')}
            >
              <span className="text-base leading-none">{b.emoji}</span>
              <span className="text-[10px] font-display leading-tight mt-0.5">{def.name}</span>
              {isFreeRoad ? (
                <span className="text-[9px] text-gold font-display">免费 ×{currentPlayer.freeRoadsRemaining}</span>
              ) : (
                <CostBadge cost={b.cost} />
              )}
            </InkButton>
          )
        })}
      </div>
      <div className="flex-1" />
      {buildMode.kind === 'build' && (
        <span className="text-xs text-ink-700/70 italic">
          已选：{BUILDINGS[buildMode.building].name}（按 Esc 取消）
        </span>
      )}
    </div>
  )
}
