import type { DevCardDef, DevCardType } from './types'

// 移植自 project/data/dev_cards.json
export const DEV_CARDS: Record<DevCardType, DevCardDef> = {
  knight: {
    id: 'knight',
    name: '骑士',
    count: 14,
    victoryPoints: 0,
    usableSameTurn: false,
    effect: 'move_robber_and_steal',
    countsForLargestArmy: true,
  },
  victory_point: {
    id: 'victory_point',
    name: '胜利点',
    count: 5,
    victoryPoints: 1,
    usableSameTurn: true,
    effect: 'add_victory_point',
    hidden: true,
    countsForLargestArmy: false,
  },
  road_building: {
    id: 'road_building',
    name: '道路建设',
    count: 2,
    victoryPoints: 0,
    usableSameTurn: false,
    effect: 'build_two_roads',
    countsForLargestArmy: false,
  },
  year_of_plenty: {
    id: 'year_of_plenty',
    name: '发明',
    count: 2,
    victoryPoints: 0,
    usableSameTurn: false,
    effect: 'take_two_resources',
    countsForLargestArmy: false,
  },
  monopoly: {
    id: 'monopoly',
    name: '垄断',
    count: 2,
    victoryPoints: 0,
    usableSameTurn: false,
    effect: 'monopoly_resource',
    countsForLargestArmy: false,
  },
}

export const TOTAL_DEV_CARDS = 25
