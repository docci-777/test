import type { HexCoord } from '@/core/hexCoord'

// pointy-top 六边形像素坐标转换
export const HEX_SIZE = 60 // 六边形外接圆半径（像素）

// 六边形中心像素坐标
export function hexToPixel(coord: HexCoord, size: number = HEX_SIZE): { x: number; y: number } {
  const x = size * Math.sqrt(3) * (coord.q + coord.r / 2)
  const y = size * 1.5 * coord.r
  return { x, y }
}

// pointy-top 六边形的 6 个顶点（相对于中心）
export function hexCorners(
  cx: number,
  cy: number,
  size: number = HEX_SIZE,
): Array<{ x: number; y: number }> {
  const corners: Array<{ x: number; y: number }> = []
  for (let i = 0; i < 6; i++) {
    const angle = (Math.PI / 180) * (60 * i - 30) // pointy-top: -30°起始
    corners.push({
      x: cx + size * Math.cos(angle),
      y: cy + size * Math.sin(angle),
    })
  }
  return corners
}

// 顶点（六边形的角）的方向 0-5 对应方向：NE E SE SW W NW（与 Godot 版 _VERTEX_OFFSETS 一致）
export const VERTEX_DIRS: Array<{ dx: number; dy: number }> = [
  { dx: 1, dy: -1 }, // 0 NE
  { dx: 1, dy: 1 }, // 1 E
  { dx: 0, dy: 2 }, // 2 SE
  { dx: -1, dy: 1 }, // 3 SW
  { dx: -1, dy: -1 }, // 4 W
  { dx: 0, dy: -2 }, // 5 NW
]

// 将归一化的整数物理坐标转回像素坐标
// 顶点物理坐标 = (2q + r + dx, 3r + dy)
// 中心像素 x = size * sqrt(3) * (q + r/2)
// 中心物理坐标 = (2q + r, 3r)
// 像素 x = size * sqrt(3) / 2 * (physX) = size * sqrt(3) * (q + r/2)
// 像素 y = size * 0.5 * (physY) = size * 1.5 * r
export function vertexPhysToPixel(
  physX: number,
  physY: number,
  size: number = HEX_SIZE,
): { x: number; y: number } {
  return {
    x: (size * Math.sqrt(3) * physX) / 2,
    y: (size * physY) / 2,
  }
}

// 边的中点像素坐标
export function edgeMidpoint(
  v1: { x: number; y: number },
  v2: { x: number; y: number },
): { x: number; y: number; angle: number } {
  const x = (v1.x + v2.x) / 2
  const y = (v1.y + v2.y) / 2
  const angle = (Math.atan2(v2.y - v1.y, v2.x - v1.x) * 180) / Math.PI
  return { x, y, angle }
}
