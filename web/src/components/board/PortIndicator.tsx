import { PORTS } from '@/core/data/ports'
import { PORT_ICON } from '@/utils/colors'
import type { PortId, ResourceType } from '@/core/data/types'

interface PortIndicatorProps {
  cx: number
  cy: number
  portId: string
  angle?: number
}

const PORT_RESOURCE_LETTER: Partial<Record<ResourceType, string>> = {
  wood: '木',
  brick: '砖',
  sheep: '羊',
  wheat: '麦',
  ore: '矿',
}

// 港口标志：木牌 + 图标 + 比例
export default function PortIndicator({ cx, cy, portId, angle = 0 }: PortIndicatorProps) {
  const port = PORTS[portId as PortId]
  if (!port) return null
  const icon = PORT_ICON[portId] ?? '⚓'
  const letter = port.resource ? PORT_RESOURCE_LETTER[port.resource] : '通'
  return (
    <g
      pointerEvents="none"
      transform={`translate(${cx} ${cy}) rotate(${angle})`}
      className="animate-fadeIn"
    >
      {/* 外框 */}
      <ellipse cx="0" cy="0" rx="15" ry="11" fill="#634a26" stroke="#2b1810" strokeWidth="1.5" />
      <ellipse cx="0" cy="0" rx="12" ry="8.5" fill="#dcc896" stroke="#2b1810" strokeWidth="0.6" />
      {/* 大图标 */}
      <text
        x="0"
        y="-1"
        textAnchor="middle"
        dominantBaseline="middle"
        fontSize="12"
      >
        {icon}
      </text>
      {/* 比例/字母 */}
      <text
        x="0"
        y="9"
        textAnchor="middle"
        dominantBaseline="middle"
        fontSize="6"
        fontFamily="'Cinzel', serif"
        fontWeight="700"
        fill="#2b1810"
      >
        {port.giveCount}:{port.receiveCount}
      </text>
      {/* 角字母（标识资源类型） */}
      <text
        x="0"
        y="-12"
        textAnchor="middle"
        dominantBaseline="middle"
        fontSize="6"
        fontFamily="'Cinzel', serif"
        fontWeight="700"
        fill="#c4421f"
      >
        {letter}
      </text>
    </g>
  )
}
