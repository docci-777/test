// Result 类型：成功/失败 + 数据/错误
export interface Ok<T> {
  ok: true
  value: T
}

export interface Err {
  ok: false
  error: { code: string; message: string }
}

export type Result<T> = Ok<T> | Err

export function ok<T>(value: T): Ok<T> {
  return { ok: true, value }
}

export function err(code: string, message: string): Err {
  return { ok: false, error: { code, message } }
}

export function isOk<T>(r: Result<T>): r is Ok<T> {
  return r.ok
}

export function isErr<T>(r: Result<T>): r is Err {
  return !r.ok
}
