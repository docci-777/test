import type { PortDef, PortId } from './types'

// 移植自 project/data/ports.json
export const PORTS: Record<PortId, PortDef> = {
  generic_3to1: {
    id: 'generic_3to1',
    name: '通用港口',
    tradeRatio: '3:1',
    giveCount: 3,
    receiveCount: 1,
    resource: null,
    countBase: 4,
  },
  wood_2to1: {
    id: 'wood_2to1',
    name: '木材港口',
    tradeRatio: '2:1',
    giveCount: 2,
    receiveCount: 1,
    resource: 'wood',
    countBase: 1,
  },
  brick_2to1: {
    id: 'brick_2to1',
    name: '砖块港口',
    tradeRatio: '2:1',
    giveCount: 2,
    receiveCount: 1,
    resource: 'brick',
    countBase: 1,
  },
  sheep_2to1: {
    id: 'sheep_2to1',
    name: '羊毛港口',
    tradeRatio: '2:1',
    giveCount: 2,
    receiveCount: 1,
    resource: 'sheep',
    countBase: 1,
  },
  wheat_2to1: {
    id: 'wheat_2to1',
    name: '麦子港口',
    tradeRatio: '2:1',
    giveCount: 2,
    receiveCount: 1,
    resource: 'wheat',
    countBase: 1,
  },
  ore_2to1: {
    id: 'ore_2to1',
    name: '矿石港口',
    tradeRatio: '2:1',
    giveCount: 2,
    receiveCount: 1,
    resource: 'ore',
    countBase: 1,
  },
}

export const TOTAL_PORTS = 9

// 9 个港口的固定配比
export const PORT_DECK: PortId[] = [
  'generic_3to1',
  'generic_3to1',
  'generic_3to1',
  'generic_3to1',
  'wood_2to1',
  'brick_2to1',
  'sheep_2to1',
  'wheat_2to1',
  'ore_2to1',
]
