import { HEX_SIZE, hexCorners } from '@/utils/hexMath'
import { TERRAIN_INFO } from '@/utils/colors'
import type { TerrainId } from '@/core/data/types'
import NumberToken from './NumberToken'

interface HexTileProps {
  cx: number
  cy: number
  terrainId: string
  numberToken?: number
  size?: number
  onClick?: () => void
  selectable?: boolean
  dimmed?: boolean
  showToken?: boolean
  highlighted?: boolean
}

// 地形纹理 pattern id
function terrainPatternId(terrainId: string): string | null {
  switch (terrainId) {
    case 'forest':
    case 'pasture':
    case 'fields':
    case 'hills':
    case 'mountains':
    case 'desert':
    case 'gold':
    case 'shallow_water':
    case 'deep_water':
      return `pat-${terrainId}`
    default:
      return null
  }
}

export default function HexTile({
  cx,
  cy,
  terrainId,
  numberToken,
  size = HEX_SIZE,
  onClick,
  selectable,
  dimmed,
  showToken = true,
  highlighted,
}: HexTileProps) {
  const corners = hexCorners(cx, cy, size)
  const points = corners.map((p) => `${p.x},${p.y}`).join(' ')
  const info = TERRAIN_INFO[terrainId as TerrainId]
  const baseFill = info?.color ?? '#cccccc'
  const patId = terrainPatternId(terrainId)
  const fill = patId ? `url(#${patId})` : baseFill

  return (
    <g
      className={selectable ? 'hex-selectable' : ''}
      onClick={selectable && onClick ? onClick : undefined}
      style={{ cursor: selectable ? 'pointer' : 'default' }}
    >
      <polygon
        points={points}
        fill={fill}
        stroke="#2b1810"
        strokeWidth="1.5"
        opacity={dimmed ? 0.45 : 1}
      />
      {/* 内阴影描边（手工风） */}
      <polygon
        points={points}
        fill="none"
        stroke="rgba(43,24,16,0.25)"
        strokeWidth="3"
        pointerEvents="none"
      />
      {highlighted && (
        <polygon
          points={points}
          fill="none"
          stroke="#e6b840"
          strokeWidth="3"
          pointerEvents="none"
          className="animate-glow"
        />
      )}
      {showToken && numberToken && numberToken > 0 && (
        <NumberToken cx={cx} cy={cy} number={numberToken} />
      )}
    </g>
  )
}
