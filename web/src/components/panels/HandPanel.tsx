import { useState } from 'react'
import { useGameStore } from '@/store/gameStore'
import { useUiStore } from '@/store/uiStore'
import Parchment from '@/components/ui/Parchment'
import InkButton from '@/components/ui/InkButton'
import Modal from '@/components/ui/Modal'
import { RESOURCE_INFO, PLAYER_COLOR_HEX } from '@/utils/colors'
import { DEV_CARDS } from '@/core/data/devCards'
import type { ResourceType, DevCardType } from '@/core/data/types'
import type { DevCardInstance, PlayerState } from '@/core/gameState'
import { Sword, Sparkles, Hammer, Compass, Scroll } from 'lucide-react'

const RESOURCE_ORDER: ResourceType[] = ['wood', 'brick', 'sheep', 'wheat', 'ore']

const DEV_CARD_ICON: Record<DevCardType, typeof Sword> = {
  knight: Sword,
  victory_point: Sparkles,
  road_building: Hammer,
  year_of_plenty: Compass,
  monopoly: Scroll,
}

const DEV_CARD_NAME: Record<DevCardType, string> = {
  knight: '骑士',
  victory_point: '胜利点',
  road_building: '道路建设',
  year_of_plenty: '丰饶之年',
  monopoly: '垄断',
}

export default function HandPanel() {
  const snapshot = useGameStore((s) => s.snapshot)
  const submitAction = useGameStore((s) => s.submitAction)
  const setBuildMode = useUiStore((s) => s.setBuildMode)

  const [yearOfPlentyCardId, setYearOfPlentyCardId] = useState<number | null>(null)
  const [monopolyCardId, setMonopolyCardId] = useState<number | null>(null)
  const [yearOfPlentyResources, setYearOfPlentyResources] = useState<ResourceType[]>([])
  const [monopolyResource, setMonopolyResource] = useState<ResourceType | null>(null)

  if (!snapshot) return null

  // 显示人类玩家的手牌（取第一个非 AI 玩家）
  const humanPlayer = snapshot.players.find((p) => !p.isAi) ?? snapshot.players[0]
  if (!humanPlayer) return null

  const c = PLAYER_COLOR_HEX[humanPlayer.color]
  const isMyTurn = snapshot.currentPlayerId === humanPlayer.id
  const canUseDevCard = isMyTurn && snapshot.phase === 'action'

  function canUseCard(card: DevCardInstance): boolean {
    if (!canUseDevCard) return false
    if (card.used) return false
    if (card.purchasedTurn === snapshot!.turn && card.type !== 'victory_point') return false
    if (card.type !== 'victory_point' && humanPlayer.devCardsUsedThisTurn >= 1) return false
    return true
  }

  async function handleUseCard(card: DevCardInstance) {
    if (!canUseCard(card)) return
    switch (card.type) {
      case 'knight':
        await submitAction({ type: 'use_dev_card', cardId: card.id, payload: { kind: 'knight' } })
        break
      case 'victory_point':
        await submitAction({
          type: 'use_dev_card',
          cardId: card.id,
          payload: { kind: 'victory_point' },
        })
        break
      case 'road_building':
        await submitAction({
          type: 'use_dev_card',
          cardId: card.id,
          payload: { kind: 'road_building' },
        })
        // 进入免费建路模式
        setBuildMode({ kind: 'build', building: 'road' })
        break
      case 'year_of_plenty':
        setYearOfPlentyCardId(card.id)
        setYearOfPlentyResources([])
        break
      case 'monopoly':
        setMonopolyCardId(card.id)
        setMonopolyResource(null)
        break
    }
  }

  function confirmYearOfPlenty() {
    if (yearOfPlentyCardId === null) return
    if (yearOfPlentyResources.length !== 2) return
    void submitAction({
      type: 'use_dev_card',
      cardId: yearOfPlentyCardId,
      payload: { kind: 'year_of_plenty', resources: yearOfPlentyResources },
    })
    setYearOfPlentyCardId(null)
    setYearOfPlentyResources([])
  }

  function confirmMonopoly() {
    if (monopolyCardId === null || !monopolyResource) return
    void submitAction({
      type: 'use_dev_card',
      cardId: monopolyCardId,
      payload: { kind: 'monopoly', resource: monopolyResource },
    })
    setMonopolyCardId(null)
    setMonopolyResource(null)
  }

  return (
    <Parchment className="p-3 flex flex-col gap-2">
      {/* 标题 */}
      <div className="flex items-center gap-2 pb-1 border-b border-ink-700/20">
        <div
          className="w-3 h-3 rounded-full border border-ink-700"
          style={{ backgroundColor: c.main }}
        />
        <span className="font-display font-bold text-sm text-ink-700">{humanPlayer.name} 的手牌</span>
        {isMyTurn && (
          <span className="ml-auto text-[10px] text-crimson font-display animate-pulse">你的回合</span>
        )}
      </div>

      {/* 资源 */}
      <div className="grid grid-cols-5 gap-1.5">
        {RESOURCE_ORDER.map((r) => {
          const info = RESOURCE_INFO[r]
          const count = humanPlayer.hand[r]
          return (
            <div
              key={r}
              className="flex flex-col items-center gap-0.5 p-1.5 rounded border border-ink-700/30"
              style={{ backgroundColor: `${info.color}22` }}
              title={info.name}
            >
              <span className="text-lg leading-none">{info.icon}</span>
              <span
                className="font-display font-bold text-sm leading-none"
                style={{ color: info.color }}
              >
                {count}
              </span>
            </div>
          )
        })}
      </div>

      {/* 发展卡 */}
      <div className="pt-1 border-t border-ink-700/20">
        <div className="flex items-center justify-between mb-1">
          <span className="font-display text-xs font-bold text-ink-700">发展卡</span>
          <span className="text-[10px] text-ink-700/60">牌堆剩 {snapshot.devCardDeck.length}</span>
        </div>
        {humanPlayer.devCards.length === 0 ? (
          <div className="text-[11px] text-ink-700/50 italic text-center py-2">无发展卡</div>
        ) : (
          <div className="flex flex-col gap-1">
            {humanPlayer.devCards.map((card) => {
              const Icon = DEV_CARD_ICON[card.type]
              const usable = canUseCard(card)
              return (
                <div
                  key={card.id}
                  className="flex items-center gap-2 px-2 py-1 rounded border border-ink-700/30 bg-parchment-50/60"
                >
                  <Icon size={14} className="text-ink-700" />
                  <span className="font-display text-xs text-ink-700 flex-1">
                    {DEV_CARD_NAME[card.type]}
                  </span>
                  {card.purchasedTurn === snapshot.turn && card.type !== 'victory_point' && (
                    <span className="text-[9px] text-ink-700/50" title="购买当回合不可使用">
                      本回合
                    </span>
                  )}
                  {card.used && (
                    <span className="text-[9px] text-ink-700/40 italic">已使用</span>
                  )}
                  {!card.used && (
                    <InkButton
                      size="sm"
                      className="!px-2 !py-0.5 !text-[10px]"
                      disabled={!usable}
                      onClick={() => handleUseCard(card)}
                    >
                      使用
                    </InkButton>
                  )}
                </div>
              )
            })}
          </div>
        )}
      </div>

      {/* 丰饶之年对话框 */}
      <Modal
        open={yearOfPlentyCardId !== null}
        onClose={() => setYearOfPlentyCardId(null)}
        title="丰饶之年 · 选择 2 种资源"
        size="sm"
      >
        <div className="flex flex-col gap-3">
          <p className="text-sm text-ink-700/80">
            从银行任选 2 张资源（可相同）。
          </p>
          <div className="grid grid-cols-5 gap-2">
            {RESOURCE_ORDER.map((r) => {
              const info = RESOURCE_INFO[r]
              const count = yearOfPlentyResources.filter((x) => x === r).length
              const bankLeft = snapshot.bank[r]
              return (
                <button
                  key={r}
                  disabled={count >= bankLeft || yearOfPlentyResources.length >= 2}
                  onClick={() =>
                    setYearOfPlentyResources([...yearOfPlentyResources, r])
                  }
                  className="flex flex-col items-center gap-0.5 p-2 rounded border-2 border-ink-700/30 bg-parchment-50 hover:bg-parchment-100 disabled:opacity-40"
                >
                  <span className="text-xl">{info.icon}</span>
                  <span className="text-[10px] font-display text-ink-700">{info.name}</span>
                  <span className="text-[9px] text-ink-700/60">银行 {bankLeft}</span>
                  {count > 0 && (
                    <span className="text-[10px] font-bold text-crimson">×{count}</span>
                  )}
                </button>
              )
            })}
          </div>
          {yearOfPlentyResources.length > 0 && (
            <button
              className="text-xs text-crimson underline"
              onClick={() => setYearOfPlentyResources([])}
            >
              清空选择
            </button>
          )}
          <InkButton
            variant="primary"
            disabled={yearOfPlentyResources.length !== 2}
            onClick={confirmYearOfPlenty}
          >
            确认（{yearOfPlentyResources.length}/2）
          </InkButton>
        </div>
      </Modal>

      {/* 垄断对话框 */}
      <Modal
        open={monopolyCardId !== null}
        onClose={() => setMonopolyCardId(null)}
        title="垄断 · 选择 1 种资源"
        size="sm"
      >
        <div className="flex flex-col gap-3">
          <p className="text-sm text-ink-700/80">
            所有其他玩家将该资源全部交给你。
          </p>
          <div className="grid grid-cols-5 gap-2">
            {RESOURCE_ORDER.map((r) => {
              const info = RESOURCE_INFO[r]
              const selected = monopolyResource === r
              return (
                <button
                  key={r}
                  onClick={() => setMonopolyResource(r)}
                  className="flex flex-col items-center gap-0.5 p-2 rounded border-2 bg-parchment-50 hover:bg-parchment-100"
                  style={{
                    borderColor: selected ? '#c4421f' : 'rgba(43,24,16,0.3)',
                  }}
                >
                  <span className="text-xl">{info.icon}</span>
                  <span className="text-[10px] font-display text-ink-700">{info.name}</span>
                </button>
              )
            })}
          </div>
          <InkButton
            variant="primary"
            disabled={!monopolyResource}
            onClick={confirmMonopoly}
          >
            确认垄断
          </InkButton>
        </div>
      </Modal>
    </Parchment>
  )
}
