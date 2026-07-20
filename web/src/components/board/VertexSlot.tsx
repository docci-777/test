interface VertexSlotProps {
  cx: number
  cy: number
  active: boolean
  onClick?: () => void
  color?: string
  size?: number
  selected?: boolean
}

// 顶点放置槽（定居点/城市/初始定居点选择）
export default function VertexSlot({
  cx,
  cy,
  active,
  onClick,
  color = '#e6b840',
  size = 11,
  selected = false,
}: VertexSlotProps) {
  if (!active) return null
  return (
    <g className="vertex-slot" onClick={onClick} style={{ cursor: 'pointer' }}>
      {/* 大命中区 */}
      <circle cx={cx} cy={cy} r={size * 2.2} fill="transparent" className="hit-area" />
      {/* 外环 */}
      <circle
        cx={cx}
        cy={cy}
        r={size}
        fill={selected ? color : `${color}aa`}
        fillOpacity={selected ? 0.9 : 0.55}
        stroke="#2b1810"
        strokeWidth="1.5"
      />
      {/* 内点 */}
      <circle cx={cx} cy={cy} r={size * 0.35} fill="#2b1810" />
      {selected && (
        <circle
          cx={cx}
          cy={cy}
          r={size + 4}
          fill="none"
          stroke={color}
          strokeWidth="2"
          className="animate-glow"
        />
      )}
    </g>
  )
}
