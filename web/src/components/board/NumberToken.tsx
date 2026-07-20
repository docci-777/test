import { NUMBER_DOTS, isRedNumber } from '@/utils/colors'

interface NumberTokenProps {
  cx: number
  cy: number
  number: number
  size?: number
}

// 数字牌：羊皮纸圆盘 + 数字 + 概率点
export default function NumberToken({ cx, cy, number, size = 22 }: NumberTokenProps) {
  const red = isRedNumber(number)
  const dots = NUMBER_DOTS[number] ?? 0
  const dotSpacing = 2.4
  const dotStartX = cx - ((dots - 1) * dotSpacing) / 2
  return (
    <g pointerEvents="none">
      <circle
        cx={cx}
        cy={cy}
        r={size}
        fill="#faf2dc"
        stroke="#2b1810"
        strokeWidth="1.5"
      />
      {/* 内圈 */}
      <circle
        cx={cx}
        cy={cy}
        r={size - 3}
        fill="none"
        stroke="rgba(43,24,16,0.25)"
        strokeWidth="0.8"
      />
      <text
        x={cx}
        y={cy + 1}
        textAnchor="middle"
        dominantBaseline="middle"
        fontSize={size * 0.95}
        fontFamily="'Cinzel', serif"
        fontWeight="700"
        fill={red ? '#c4421f' : '#2b1810'}
      >
        {number}
      </text>
      {/* 概率点 */}
      <g>
        {Array.from({ length: dots }).map((_, i) => (
          <circle
            key={i}
            cx={dotStartX + i * dotSpacing}
            cy={cy + size * 0.72}
            r="1.1"
            fill={red ? '#c4421f' : '#2b1810'}
          />
        ))}
      </g>
    </g>
  )
}
