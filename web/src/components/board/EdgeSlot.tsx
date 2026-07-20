interface EdgeSlotProps {
  x1: number
  y1: number
  x2: number
  y2: number
  active: boolean
  onClick?: () => void
  color?: string
  selected?: boolean
}

// 边放置槽（道路/船只）
export default function EdgeSlot({
  x1,
  y1,
  x2,
  y2,
  active,
  onClick,
  color = '#e6b840',
  selected = false,
}: EdgeSlotProps) {
  if (!active) return null
  const mx = (x1 + x2) / 2
  const my = (y1 + y2) / 2
  const angle = (Math.atan2(y2 - y1, x2 - x1) * 180) / Math.PI
  return (
    <g
      className="edge-slot"
      onClick={onClick}
      transform={`translate(${mx} ${my}) rotate(${angle})`}
      style={{ cursor: 'pointer' }}
    >
      {/* 命中区 */}
      <rect x="-32" y="-12" width="64" height="24" fill="transparent" className="hit-area" />
      <rect
        x="-24"
        y="-5"
        width="48"
        height="10"
        fill={selected ? color : `${color}aa`}
        fillOpacity={selected ? 0.9 : 0.55}
        stroke="#2b1810"
        strokeWidth="1.5"
        rx="2"
      />
      {/* 中央条纹 */}
      <line
        x1="-18"
        y1="0"
        x2="18"
        y2="0"
        stroke="#2b1810"
        strokeWidth="0.8"
        strokeDasharray="3,3"
      />
      {selected && (
        <rect
          x="-28"
          y="-9"
          width="56"
          height="18"
          fill="none"
          stroke={color}
          strokeWidth="2"
          rx="3"
          className="animate-glow"
        />
      )}
    </g>
  )
}
