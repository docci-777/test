// 轴向坐标系（pointy-top）
export class HexCoord {
  constructor(public q: number, public r: number) {}

  static get key(): string {
    return '' // 不使用
  }

  toKey(): string {
    return `${this.q},${this.r}`
  }

  equals(other: HexCoord): boolean {
    return this.q === other.q && this.r === other.r
  }

  static fromKey(key: string): HexCoord {
    const [q, r] = key.split(',').map((n) => parseInt(n, 10))
    return new HexCoord(q, r)
  }

  // 6 个方向的邻居
  static DIRECTIONS: HexCoord[] = [
    new HexCoord(1, 0),
    new HexCoord(1, -1),
    new HexCoord(0, -1),
    new HexCoord(-1, 0),
    new HexCoord(-1, 1),
    new HexCoord(0, 1),
  ]

  neighbor(dir: number): HexCoord {
    const d = HexCoord.DIRECTIONS[dir]
    return new HexCoord(this.q + d.q, this.r + d.r)
  }

  neighbors(): HexCoord[] {
    return HexCoord.DIRECTIONS.map((d) => new HexCoord(this.q + d.q, this.r + d.r))
  }
}
