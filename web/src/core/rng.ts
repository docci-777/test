// 种子随机数：Mulberry32 算法
export class Rng {
  private state: number

  constructor(seed: number) {
    this.state = seed >>> 0
    if (this.state === 0) this.state = 1
  }

  next(): number {
    // Mulberry32
    let t = (this.state += 0x6d2b79f5)
    t = Math.imul(t ^ (t >>> 15), t | 1)
    t ^= t + Math.imul(t ^ (t >>> 7), t | 61)
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296
  }

  // 整数 [min, max]
  nextInt(min: number, max: number): number {
    return Math.floor(this.next() * (max - min + 1)) + min
  }

  // 从数组中随机取一个
  pick<T>(arr: T[]): T {
    return arr[Math.floor(this.next() * arr.length)]
  }

  // Fisher–Yates 原地洗牌
  shuffle<T>(arr: T[]): T[] {
    const result = arr.slice()
    for (let i = result.length - 1; i > 0; i--) {
      const j = Math.floor(this.next() * (i + 1))
      ;[result[i], result[j]] = [result[j], result[i]]
    }
    return result
  }

  // 取一个 [0, n) 的随机排列
  permutation(n: number): number[] {
    const arr = Array.from({ length: n }, (_, i) => i)
    return this.shuffle(arr)
  }
}

export function seedFromString(s: string): number {
  if (/^\d+$/.test(s.trim())) {
    return parseInt(s.trim(), 10)
  }
  let h = 2166136261
  for (let i = 0; i < s.length; i++) {
    h ^= s.charCodeAt(i)
    h = Math.imul(h, 16777619)
  }
  return h >>> 0
}
