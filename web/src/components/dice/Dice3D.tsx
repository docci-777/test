import { useEffect, useState } from 'react'
import { cn } from '@/lib/utils'

interface Dice3DProps {
  value: number | null
  rolling?: boolean
  size?: number
}

// 骰子点数布局（3x3 网格中哪些位置点亮）
const PIP_LAYOUT: Record<number, number[]> = {
  1: [4],
  2: [0, 8],
  3: [0, 4, 8],
  4: [0, 2, 6, 8],
  5: [0, 2, 4, 6, 8],
  6: [0, 2, 3, 5, 6, 8],
}

export default function Dice3D({ value, rolling = false, size = 48 }: Dice3DProps) {
  const [displayValue, setDisplayValue] = useState(value ?? 1)

  useEffect(() => {
    if (rolling) {
      // 滚动时随机闪烁
      const interval = setInterval(() => {
        setDisplayValue(Math.floor(Math.random() * 6) + 1)
      }, 80)
      return () => clearInterval(interval)
    } else if (value !== null) {
      setDisplayValue(value)
    }
  }, [rolling, value])

  const pips = PIP_LAYOUT[displayValue] ?? []

  return (
    <div
      className={cn('dice-3d', rolling && 'animate-roll')}
      style={{ width: size, height: size, padding: size * 0.12, gap: size * 0.04 }}
    >
      {Array.from({ length: 9 }).map((_, i) => (
        <div
          key={i}
          className="grid place-items-center"
          style={{
            width: size * 0.18,
            height: size * 0.18,
          }}
        >
          {pips.includes(i) && (
            <div
              className="dice-pip"
              style={{
                width: size * 0.14,
                height: size * 0.14,
              }}
            />
          )}
        </div>
      ))}
    </div>
  )
}
