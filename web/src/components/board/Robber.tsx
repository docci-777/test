interface RobberProps {
  cx: number
  cy: number
}

// 强盗：黑色小人偶
export default function Robber({ cx, cy }: RobberProps) {
  return (
    <g pointerEvents="none" className="animate-fadeIn" style={{ transition: 'transform 0.3s' }}>
      {/* 阴影 */}
      <ellipse cx={cx} cy={cy + 14} rx="12" ry="3" fill="rgba(0,0,0,0.45)" />
      {/* 身体（披风） */}
      <path
        d={`M ${cx - 9} ${cy + 12} L ${cx - 7} ${cy - 6} Q ${cx} ${cy - 14} ${cx + 7} ${cy - 6} L ${cx + 9} ${cy + 12} Z`}
        fill="#0f0a06"
        stroke="#000"
        strokeWidth="1.2"
        strokeLinejoin="round"
      />
      {/* 头部兜帽 */}
      <path
        d={`M ${cx - 6} ${cy - 4} Q ${cx} ${cy - 14} ${cx + 6} ${cy - 4} Q ${cx + 4} ${cy - 8} ${cx} ${cy - 9} Q ${cx - 4} ${cy - 8} ${cx - 6} ${cy - 4} Z`}
        fill="#1a0e08"
        stroke="#000"
        strokeWidth="0.8"
      />
      {/* 双眼 */}
      <circle cx={cx - 2.2} cy={cy - 5} r="0.9" fill="#e6b840" />
      <circle cx={cx + 2.2} cy={cy - 5} r="0.9" fill="#e6b840" />
    </g>
  )
}
