import { useState, useMemo } from 'react'
import { useGameStore } from '@/store/gameStore'
import { useUiStore } from '@/store/uiStore'
import Modal from '@/components/ui/Modal'
import InkButton from '@/components/ui/InkButton'
import { RESOURCE_INFO, PLAYER_COLOR_HEX } from '@/utils/colors'
import { PORTS } from '@/core/data/ports'
import { canAfford, handSize } from '@/core/gameState'
import type { ResourceType, ResourceSet, PortId } from '@/core/data/types'
import { cn } from '@/lib/utils'

const RESOURCE_ORDER: ResourceType[] = ['wood', 'brick', 'sheep', 'wheat', 'ore']

// 玩家可用的港口（已建有定居点/城市的港口）
function getPlayerPorts(
  state: ReturnType<typeof useGameStore.getState>['snapshot'],
  playerId: string,
): PortId[] {
  if (!state) return []
  const board = state.board
  const myVertexBuildings = state.buildings.filter(
    (b) => b.ownerId === playerId && b.positionType === 'vertex',
  )
  const portIds = new Set<string>()
  for (const b of myVertexBuildings) {
    const pid = board.getPort(b.positionId)
    if (pid) portIds.add(pid)
  }
  return Array.from(portIds) as PortId[]
}

export default function TradeDialog() {
  const open = useUiStore((s) => s.dialog === 'trade')
  const setDialog = useUiStore((s) => s.setDialog)
  const snapshot = useGameStore((s) => s.snapshot)
  const submitAction = useGameStore((s) => s.submitAction)

  const [tab, setTab] = useState<'bank' | 'player'>('bank')
  const [giveResource, setGiveResource] = useState<ResourceType | null>(null)
  const [recvResource, setRecvResource] = useState<ResourceType | null>(null)
  const [selectedPort, setSelectedPort] = useState<PortId | 'default' | null>('default')
  const [targetPlayerId, setTargetPlayerId] = useState<string | null>(null)
  const [giveSet, setGiveSet] = useState<ResourceSet>({ wood: 0, brick: 0, sheep: 0, wheat: 0, ore: 0 })
  const [recvSet, setRecvSet] = useState<ResourceSet>({ wood: 0, brick: 0, sheep: 0, wheat: 0, ore: 0 })

  if (!snapshot) return null

  const currentPlayer = snapshot.players.find((p) => p.id === snapshot.currentPlayerId)
  if (!currentPlayer) return null

  const myPorts = useMemo(() => getPlayerPorts(snapshot, currentPlayer.id), [snapshot, currentPlayer.id])

  function reset() {
    setGiveResource(null)
    setRecvResource(null)
    setSelectedPort('default')
    setTargetPlayerId(null)
    setGiveSet({ wood: 0, brick: 0, sheep: 0, wheat: 0, ore: 0 })
    setRecvSet({ wood: 0, brick: 0, sheep: 0, wheat: 0, ore: 0 })
  }

  function close() {
    reset()
    setDialog('none')
  }

  // 银行交易比例
  const tradeRatio = (() => {
    if (selectedPort === 'default' || selectedPort === null) return 4
    const port = PORTS[selectedPort]
    if (!port) return 4
    return port.giveCount
  })()

  // 银行交易：必须选择 giveResource + recvResource
  const bankTradeValid =
    tab === 'bank' &&
    giveResource !== null &&
    recvResource !== null &&
    currentPlayer.hand[giveResource] >= tradeRatio &&
    snapshot.bank[recvResource] > 0 &&
    (!selectedPort ||
      selectedPort === 'default' ||
      PORTS[selectedPort as PortId].resource === null ||
      PORTS[selectedPort as PortId].resource === giveResource)

  async function handleBankTrade() {
    if (!bankTradeValid || !giveResource || !recvResource) return
    const give: ResourceSet = { wood: 0, brick: 0, sheep: 0, wheat: 0, ore: 0 }
    give[giveResource] = tradeRatio
    await submitAction({
      type: 'trade_bank',
      give,
      receive: recvResource,
      portId: selectedPort === 'default' ? undefined : selectedPort ?? undefined,
    })
    close()
  }

  // 玩家交易
  const giveTotal = handSize(giveSet)
  const recvTotal = handSize(recvSet)
  const target = targetPlayerId ? snapshot.players.find((p) => p.id === targetPlayerId) : null
  const playerTradeValid =
    tab === 'player' &&
    target !== null &&
    target.id !== currentPlayer.id &&
    giveTotal > 0 &&
    recvTotal > 0 &&
    canAfford(currentPlayer.hand, giveSet) &&
    (target ? canAfford(target.hand, recvSet) : false)

  async function handlePlayerTrade() {
    if (!playerTradeValid || !targetPlayerId) return
    await submitAction({
      type: 'trade_player',
      targetPlayerId,
      give: giveSet,
      receive: recvSet,
    })
    close()
  }

  return (
    <Modal open={open} onClose={close} title="交易" size="md">
      <div className="flex flex-col gap-4">
        {/* Tab */}
        <div className="flex gap-1 border-b border-ink-700/30">
          <button
            className={cn(
              'px-4 py-1.5 font-display text-sm font-bold border-b-2 -mb-px',
              tab === 'bank'
                ? 'border-crimson text-crimson'
                : 'border-transparent text-ink-700/60 hover:text-ink-700',
            )}
            onClick={() => setTab('bank')}
          >
            与银行交易
          </button>
          <button
            className={cn(
              'px-4 py-1.5 font-display text-sm font-bold border-b-2 -mb-px',
              tab === 'player'
                ? 'border-crimson text-crimson'
                : 'border-transparent text-ink-700/60 hover:text-ink-700',
            )}
            onClick={() => setTab('player')}
          >
            与玩家交易
          </button>
        </div>

        {/* 银行交易 */}
        {tab === 'bank' && (
          <div className="flex flex-col gap-3">
            <p className="text-xs text-ink-700/70">
              默认 4:1；若你占有港口，可选择对应港口以 3:1 或 2:1 比例交易。
            </p>

            {/* 港口选择 */}
            <div className="flex flex-wrap gap-1.5">
              <button
                className={cn(
                  'px-2 py-1 rounded text-[11px] font-display border-2',
                  selectedPort === 'default'
                    ? 'border-crimson bg-crimson/10 text-crimson'
                    : 'border-ink-700/30 bg-parchment-50 text-ink-700',
                )}
                onClick={() => setSelectedPort('default')}
              >
                银行 4:1
              </button>
              {myPorts.map((pid) => {
                const port = PORTS[pid]
                const selected = selectedPort === pid
                return (
                  <button
                    key={pid}
                    className={cn(
                      'px-2 py-1 rounded text-[11px] font-display border-2 flex items-center gap-1',
                      selected
                        ? 'border-crimson bg-crimson/10 text-crimson'
                        : 'border-ink-700/30 bg-parchment-50 text-ink-700',
                    )}
                    onClick={() => setSelectedPort(pid)}
                  >
                    <span>{RESOURCE_INFO[port.resource ?? 'wood'].icon}</span>
                    {port.tradeRatio}
                    {port.resource && (
                      <span className="text-[9px]">
                        ({RESOURCE_INFO[port.resource].name})
                      </span>
                    )}
                  </button>
                )
              })}
              {myPorts.length === 0 && (
                <span className="text-[10px] text-ink-700/50 italic">未占有任何港口</span>
              )}
            </div>

            {/* 给出资源 */}
            <div className="flex flex-col gap-1">
              <span className="text-xs font-display font-bold text-ink-700">
                给出（{tradeRatio}:1）
              </span>
              <div className="grid grid-cols-5 gap-2">
                {RESOURCE_ORDER.map((r) => {
                  const disabled =
                    currentPlayer.hand[r] < tradeRatio ||
                    (selectedPort !== null &&
                      selectedPort !== 'default' &&
                      PORTS[selectedPort as PortId].resource !== null &&
                      PORTS[selectedPort as PortId].resource !== r)
                  const selected = giveResource === r
                  return (
                    <button
                      key={r}
                      disabled={disabled}
                      onClick={() => setGiveResource(r)}
                      className={cn(
                        'flex flex-col items-center gap-0.5 p-2 rounded border-2',
                        selected
                          ? 'border-crimson bg-crimson/10'
                          : 'border-ink-700/30 bg-parchment-50',
                        disabled && 'opacity-40',
                      )}
                    >
                      <span className="text-xl">{RESOURCE_INFO[r].icon}</span>
                      <span className="text-[10px]">{currentPlayer.hand[r]}</span>
                    </button>
                  )
                })}
              </div>
            </div>

            {/* 接收资源 */}
            <div className="flex flex-col gap-1">
              <span className="text-xs font-display font-bold text-ink-700">接收（1）</span>
              <div className="grid grid-cols-5 gap-2">
                {RESOURCE_ORDER.map((r) => {
                  const disabled = snapshot.bank[r] <= 0
                  const selected = recvResource === r
                  return (
                    <button
                      key={r}
                      disabled={disabled}
                      onClick={() => setRecvResource(r)}
                      className={cn(
                        'flex flex-col items-center gap-0.5 p-2 rounded border-2',
                        selected
                          ? 'border-crimson bg-crimson/10'
                          : 'border-ink-700/30 bg-parchment-50',
                        disabled && 'opacity-40',
                      )}
                    >
                      <span className="text-xl">{RESOURCE_INFO[r].icon}</span>
                      <span className="text-[10px]">银{snapshot.bank[r]}</span>
                    </button>
                  )
                })}
              </div>
            </div>

            <div className="flex items-center justify-between pt-2 border-t border-ink-700/20">
              <div className="text-xs text-ink-700/80">
                {giveResource && recvResource ? (
                  <span>
                    {tradeRatio}×{RESOURCE_INFO[giveResource].name} → 1×{RESOURCE_INFO[recvResource].name}
                  </span>
                ) : (
                  <span>请选择资源</span>
                )}
              </div>
              <InkButton
                variant="primary"
                disabled={!bankTradeValid}
                onClick={handleBankTrade}
              >
                确认交易
              </InkButton>
            </div>
          </div>
        )}

        {/* 玩家交易 */}
        {tab === 'player' && (
          <div className="flex flex-col gap-3">
            <p className="text-xs text-ink-700/70">
              与其他玩家协商交易。本地模式不支持 AI 应答；该接口预留给联机版后端使用。
            </p>

            {/* 选择目标玩家 */}
            <div className="flex flex-col gap-1">
              <span className="text-xs font-display font-bold text-ink-700">目标玩家</span>
              <div className="flex gap-2">
                {snapshot.players
                  .filter((p) => p.id !== currentPlayer.id)
                  .map((p) => {
                    const c = PLAYER_COLOR_HEX[p.color]
                    const selected = targetPlayerId === p.id
                    return (
                      <button
                        key={p.id}
                        onClick={() => setTargetPlayerId(p.id)}
                        className={cn(
                          'flex items-center gap-1.5 px-3 py-1.5 rounded border-2',
                          selected ? 'border-crimson' : 'border-ink-700/30',
                        )}
                        style={{ backgroundColor: c.main, color: c.text }}
                      >
                        <span className="font-display text-xs font-bold">{p.name}</span>
                        <span className="text-[10px] opacity-80">资源 {handSize(p.hand)}</span>
                      </button>
                    )
                  })}
              </div>
            </div>

            {/* 给出资源 */}
            <div className="flex flex-col gap-1">
              <span className="text-xs font-display font-bold text-ink-700">
                你给出（合计 {giveTotal}）
              </span>
              <div className="grid grid-cols-5 gap-2">
                {RESOURCE_ORDER.map((r) => (
                  <div
                    key={r}
                    className="flex flex-col items-center gap-0.5 p-2 rounded border-2 border-ink-700/30 bg-parchment-50"
                  >
                    <span className="text-xl">{RESOURCE_INFO[r].icon}</span>
                    <span className="text-[10px]">你 {currentPlayer.hand[r]}</span>
                    <div className="flex items-center gap-1 mt-1">
                      <button
                        className="w-5 h-5 rounded text-xs font-bold bg-ink-700/10 hover:bg-ink-700/20"
                        onClick={() =>
                          setGiveSet({ ...giveSet, [r]: Math.max(0, giveSet[r] - 1) })
                        }
                      >
                        −
                      </button>
                      <span className="font-display font-bold text-sm w-4 text-center">
                        {giveSet[r]}
                      </span>
                      <button
                        className="w-5 h-5 rounded text-xs font-bold bg-ink-700/10 hover:bg-ink-700/20"
                        disabled={currentPlayer.hand[r] <= giveSet[r]}
                        onClick={() => setGiveSet({ ...giveSet, [r]: giveSet[r] + 1 })}
                      >
                        +
                      </button>
                    </div>
                  </div>
                ))}
              </div>
            </div>

            {/* 接收资源 */}
            <div className="flex flex-col gap-1">
              <span className="text-xs font-display font-bold text-ink-700">
                你接收（合计 {recvTotal}{target ? `，对方持有` : ''}）
              </span>
              <div className="grid grid-cols-5 gap-2">
                {RESOURCE_ORDER.map((r) => (
                  <div
                    key={r}
                    className="flex flex-col items-center gap-0.5 p-2 rounded border-2 border-ink-700/30 bg-parchment-50"
                  >
                    <span className="text-xl">{RESOURCE_INFO[r].icon}</span>
                    <span className="text-[10px]">
                      对{target ? target.hand[r] : '—'}
                    </span>
                    <div className="flex items-center gap-1 mt-1">
                      <button
                        className="w-5 h-5 rounded text-xs font-bold bg-ink-700/10 hover:bg-ink-700/20"
                        onClick={() =>
                          setRecvSet({ ...recvSet, [r]: Math.max(0, recvSet[r] - 1) })
                        }
                      >
                        −
                      </button>
                      <span className="font-display font-bold text-sm w-4 text-center">
                        {recvSet[r]}
                      </span>
                      <button
                        className="w-5 h-5 rounded text-xs font-bold bg-ink-700/10 hover:bg-ink-700/20"
                        disabled={!!target && target.hand[r] <= recvSet[r]}
                        onClick={() => setRecvSet({ ...recvSet, [r]: recvSet[r] + 1 })}
                      >
                        +
                      </button>
                    </div>
                  </div>
                ))}
              </div>
            </div>

            <div className="flex items-center justify-between pt-2 border-t border-ink-700/20">
              <div className="text-xs text-ink-700/80">
                {playerTradeValid
                  ? `用 ${giveTotal} 张换 ${recvTotal} 张`
                  : '请完成选择'}
              </div>
              <InkButton
                variant="primary"
                disabled={!playerTradeValid}
                onClick={handlePlayerTrade}
              >
                提交交易
              </InkButton>
            </div>
          </div>
        )}
      </div>
    </Modal>
  )
}
