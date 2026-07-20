import { PLAYER_COLOR_HEX } from '@/utils/colors'
import type { PlayerColor } from '@/core/data/types'

interface BuildingSvgProps {
  color: PlayerColor
  size?: number
}

// 定居点：小屋形状
export function SettlementSvg({ color, size = 24 }: BuildingSvgProps) {
  const c = PLAYER_COLOR_HEX[color]
  return (
    <svg width={size} height={size} viewBox="-12 -12 24 24" overflow="visible">
      {/* 阴影 */}
      <ellipse cx="0" cy="9" rx="9" ry="2" fill="rgba(0,0,0,0.3)" />
      {/* 房身 */}
      <rect x="-7" y="-2" width="14" height="10" fill={c.main} stroke="#2b1810" strokeWidth="1.5" />
      {/* 屋顶 */}
      <polygon points="-9,-2 0,-10 9,-2" fill={c.dark} stroke="#2b1810" strokeWidth="1.5" strokeLinejoin="round" />
      {/* 烟囱 */}
      <rect x="3" y="-8" width="2.5" height="4" fill={c.dark} stroke="#2b1810" strokeWidth="1" />
      {/* 门 */}
      <rect x="-1.5" y="3" width="3" height="5" fill="#2b1810" />
    </svg>
  )
}

// 城市：双塔教堂
export function CitySvg({ color, size = 28 }: BuildingSvgProps) {
  const c = PLAYER_COLOR_HEX[color]
  return (
    <svg width={size} height={size} viewBox="-14 -14 28 28" overflow="visible">
      <ellipse cx="0" cy="11" rx="11" ry="2.5" fill="rgba(0,0,0,0.3)" />
      {/* 主体 */}
      <rect x="-9" y="-2" width="18" height="11" fill={c.main} stroke="#2b1810" strokeWidth="1.5" />
      {/* 左塔 */}
      <rect x="-10" y="-8" width="6" height="17" fill={c.dark} stroke="#2b1810" strokeWidth="1.5" />
      <polygon points="-11,-8 -7,-8 -7,-13 -9,-13" fill={c.dark} stroke="#2b1810" strokeWidth="1.5" strokeLinejoin="round" />
      {/* 右塔 */}
      <rect x="4" y="-8" width="6" height="17" fill={c.dark} stroke="#2b1810" strokeWidth="1.5" />
      <polygon points="3,-8 7,-8 7,-13 5,-13" fill={c.dark} stroke="#2b1810" strokeWidth="1.5" strokeLinejoin="round" />
      {/* 中央屋顶 */}
      <polygon points="-4,-2 4,-2 0,-9" fill={c.dark} stroke="#2b1810" strokeWidth="1.5" strokeLinejoin="round" />
      {/* 窗 */}
      <rect x="-1.5" y="2" width="3" height="4" fill="#2b1810" />
      <rect x="-7.5" y="2" width="2" height="3" fill="#2b1810" />
      <rect x="5.5" y="2" width="2" height="3" fill="#2b1810" />
    </svg>
  )
}

// 道路：木桥板
export function RoadSvg({ color, size = 1 }: { color: PlayerColor; size?: number }) {
  const c = PLAYER_COLOR_HEX[color]
  return (
    <g>
      <rect x="-26" y="-3" width="52" height="6" fill={c.main} stroke="#2b1810" strokeWidth="1.5" rx="1" transform={`scale(${size})`} />
      <line x1="-20" y1="0" x2="20" y2="0" stroke={c.dark} strokeWidth="1" strokeDasharray="3,3" transform={`scale(${size})`} />
    </g>
  )
}

// 船只：小帆船
export function ShipSvg({ color, size = 22 }: BuildingSvgProps) {
  const c = PLAYER_COLOR_HEX[color]
  return (
    <svg width={size} height={size} viewBox="-14 -14 28 28" overflow="visible">
      <ellipse cx="0" cy="9" rx="11" ry="2.5" fill="rgba(0,0,0,0.3)" />
      {/* 船身 */}
      <path d="M -10 2 L 10 2 L 8 8 L -8 8 Z" fill={c.main} stroke="#2b1810" strokeWidth="1.5" strokeLinejoin="round" />
      {/* 桅杆 */}
      <line x1="0" y1="2" x2="0" y2="-9" stroke="#2b1810" strokeWidth="1.5" />
      {/* 帆 */}
      <path d="M 0 -8 L 0 -1 L 7 -3 Z" fill={c.dark} stroke="#2b1810" strokeWidth="1.2" strokeLinejoin="round" />
      <path d="M 0 -8 L 0 -1 L -6 -3 Z" fill={c.dark} stroke="#2b1810" strokeWidth="1.2" strokeLinejoin="round" />
      {/* 旗 */}
      <line x1="0" y1="-9" x2="3" y2="-9" stroke={c.main} strokeWidth="1.5" />
    </svg>
  )
}
