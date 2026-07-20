import { HexCoord } from './hexCoord'

// 顶点归一化：与 Godot 版 _VERTEX_OFFSETS 一致
// 物理坐标整数化：(2q+r+dx, 3r+dy)
const VERTEX_OFFSETS: Array<{ dx: number; dy: number }> = [
  { dx: 1, dy: -1 }, // 0 NE
  { dx: 1, dy: 1 }, // 1 E
  { dx: 0, dy: 2 }, // 2 SE
  { dx: -1, dy: 1 }, // 3 SW
  { dx: -1, dy: -1 }, // 4 W
  { dx: 0, dy: -2 }, // 5 NW
]

export interface HexCell {
  id: number
  coord: HexCoord
  terrainId: string
  numberToken: number
  hidden?: boolean
}

export interface VertexData {
  id: number
  canonicalKey: string
  physX: number
  physY: number
}

export interface EdgeData {
  id: number
  canonicalKey: string
  v1: number
  v2: number
}

export class Board {
  private hexes: Map<string, HexCell> = new Map()
  private hexesById: Map<number, HexCell> = new Map()
  private vertices: Map<string, VertexData> = new Map()
  private verticesById: Map<number, VertexData> = new Map()
  private edges: Map<string, EdgeData> = new Map()
  private edgesById: Map<number, EdgeData> = new Map()
  private _vertexEdges: Map<number, number[]> = new Map()
  private _edgeVertices: Map<number, [number, number]> = new Map()
  private _vertexHexes: Map<number, HexCoord[]> = new Map()
  private _edgeHexes: Map<number, HexCoord[]> = new Map()
  private _vertexAdjacency: Map<number, number[]> = new Map()
  private _ports: Map<number, string> = new Map() // vertexId -> portId

  addHex(coord: HexCoord, terrainId: string = '', numberToken: number = 0): HexCell {
    const key = coord.toKey()
    if (this.hexes.has(key)) return this.hexes.get(key)!
    const id = this.hexes.size
    const cell: HexCell = { id, coord, terrainId, numberToken }
    this.hexes.set(key, cell)
    this.hexesById.set(id, cell)
    return cell
  }

  setHexTerrain(coord: HexCoord, terrainId: string, numberToken: number = 0) {
    const key = coord.toKey()
    const cell = this.hexes.get(key)
    if (cell) {
      cell.terrainId = terrainId
      cell.numberToken = numberToken
    }
  }

  buildTopology() {
    // 清空旧拓扑
    this.vertices.clear()
    this.verticesById.clear()
    this.edges.clear()
    this.edgesById.clear()
    this._vertexEdges.clear()
    this._edgeVertices.clear()
    this._vertexHexes.clear()
    this._edgeHexes.clear()
    this._vertexAdjacency.clear()

    for (const cell of this.hexes.values()) {
      this.buildHexTopology(cell)
    }

    // 反向索引
    for (const v of this.vertices.values()) {
      this.verticesById.set(v.id, v)
    }
    for (const e of this.edges.values()) {
      this.edgesById.set(e.id, e)
    }

    // 构建顶点邻接
    for (const [eid, verts] of this._edgeVertices) {
      const [v1, v2] = verts
      this.addEdgeToVertex(v1, eid)
      this.addEdgeToVertex(v2, eid)
      this.addVertexAdjacency(v1, v2)
      this.addVertexAdjacency(v2, v1)
    }
  }

  private buildHexTopology(cell: HexCell) {
    const coord = cell.coord
    const coordKey = coord.toKey()
    const hexVertexIds: number[] = []

    for (let i = 0; i < 6; i++) {
      const vid = this.canonicalVertexId(coord, i)
      hexVertexIds.push(vid)
      let arr = this._vertexHexes.get(vid)
      if (!arr) {
        arr = []
        this._vertexHexes.set(vid, arr)
      }
      if (!arr.some((h) => h.toKey() === coordKey)) {
        arr.push(coord)
      }
    }

    for (let i = 0; i < 6; i++) {
      const v1 = hexVertexIds[i]
      const v2 = hexVertexIds[(i + 1) % 6]
      const eid = this.canonicalEdgeId(v1, v2)
      if (!this._edgeVertices.has(eid)) {
        this._edgeVertices.set(eid, [v1, v2])
      }
      let arr = this._edgeHexes.get(eid)
      if (!arr) {
        arr = []
        this._edgeHexes.set(eid, arr)
      }
      if (!arr.some((h) => h.toKey() === coordKey)) {
        arr.push(coord)
      }
    }
  }

  private canonicalVertexId(coord: HexCoord, dir: number): number {
    const cx = 2 * coord.q + coord.r
    const cy = 3 * coord.r
    const off = VERTEX_OFFSETS[dir]
    const vx = cx + off.dx
    const vy = cy + off.dy
    const key = `${vx},${vy}`
    let v = this.vertices.get(key)
    if (!v) {
      const id = this.vertices.size
      v = { id, canonicalKey: key, physX: vx, physY: vy }
      this.vertices.set(key, v)
    }
    return v.id
  }

  private canonicalEdgeId(v1: number, v2: number): number {
    const minV = Math.min(v1, v2)
    const maxV = Math.max(v1, v2)
    const key = `${minV}-${maxV}`
    let e = this.edges.get(key)
    if (!e) {
      const id = this.edges.size
      e = { id, canonicalKey: key, v1: minV, v2: maxV }
      this.edges.set(key, e)
    }
    return e.id
  }

  private addEdgeToVertex(v: number, e: number) {
    let arr = this._vertexEdges.get(v)
    if (!arr) {
      arr = []
      this._vertexEdges.set(v, arr)
    }
    if (!arr.includes(e)) arr.push(e)
  }

  private addVertexAdjacency(v1: number, v2: number) {
    let arr = this._vertexAdjacency.get(v1)
    if (!arr) {
      arr = []
      this._vertexAdjacency.set(v1, arr)
    }
    if (!arr.includes(v2)) arr.push(v2)
  }

  // ---- 查询接口 ----

  hexCount(): number {
    return this.hexes.size
  }
  hasHex(coord: HexCoord): boolean {
    return this.hexes.has(coord.toKey())
  }
  getHex(coord: HexCoord): HexCell | undefined {
    return this.hexes.get(coord.toKey())
  }
  getHexById(id: number): HexCell | undefined {
    return this.hexesById.get(id)
  }
  allHexes(): HexCell[] {
    return Array.from(this.hexes.values())
  }
  vertexCount(): number {
    return this.vertices.size
  }
  edgeCount(): number {
    return this.edges.size
  }
  allVertices(): VertexData[] {
    return Array.from(this.vertices.values())
  }
  allEdges(): EdgeData[] {
    return Array.from(this.edges.values())
  }
  getVertex(id: number): VertexData | undefined {
    return this.verticesById.get(id)
  }
  getEdge(id: number): EdgeData | undefined {
    return this.edgesById.get(id)
  }
  hexNeighbors(coord: HexCoord): HexCoord[] {
    return coord.neighbors().filter((n) => this.hasHex(n))
  }
  vertexEdges(vId: number): number[] {
    return this._vertexEdges.get(vId) ?? []
  }
  edgeVertices(eId: number): [number, number] {
    return this._edgeVertices.get(eId) ?? [-1, -1]
  }
  adjacentVertices(vId: number): number[] {
    return this._vertexAdjacency.get(vId) ?? []
  }
  vertexHexes(vId: number): HexCoord[] {
    return this._vertexHexes.get(vId) ?? []
  }
  // 查询某六边形相邻的所有顶点 ID
  vertexHexesByHex(hex: HexCoord): number[] {
    const result: number[] = []
    for (const v of this.vertices.values()) {
      const vHexes = this._vertexHexes.get(v.id) ?? []
      if (vHexes.some((c) => c.equals(hex))) result.push(v.id)
    }
    return result
  }
  edgeHexes(eId: number): HexCoord[] {
    return this._edgeHexes.get(eId) ?? []
  }

  // 边界顶点：相邻六边形数 < 3
  boundaryVertices(): number[] {
    const result: number[] = []
    for (const [vid, hexes] of this._vertexHexes) {
      if (hexes.length < 3) result.push(vid)
    }
    return result
  }

  // ---- 港口管理 ----
  setPort(vertexId: number, portId: string) {
    this._ports.set(vertexId, portId)
  }
  getPort(vertexId: number): string | undefined {
    return this._ports.get(vertexId)
  }
  allPortVertices(): number[] {
    return Array.from(this._ports.keys())
  }
  portCount(): number {
    return this._ports.size
  }

  // BFS 顶点距离
  vertexDistance(v1: number, v2: number): number {
    if (v1 === v2) return 0
    const visited = new Map<number, number>([[v1, 0]])
    const queue: number[] = [v1]
    while (queue.length > 0) {
      const current = queue.shift()!
      const dist = visited.get(current)!
      for (const nb of this._vertexAdjacency.get(current) ?? []) {
        if (nb === v2) return dist + 1
        if (!visited.has(nb)) {
          visited.set(nb, dist + 1)
          queue.push(nb)
        }
      }
    }
    return -1
  }

  // 序列化
  toJSON(): unknown {
    return {
      hexes: this.allHexes().map((h) => ({
        q: h.coord.q,
        r: h.coord.r,
        terrainId: h.terrainId,
        numberToken: h.numberToken,
        hidden: h.hidden,
      })),
      ports: Array.from(this._ports.entries()).map(([vid, pid]) => ({ vertexId: vid, portId: pid })),
    }
  }
}
