// 当前对外暴露 mock API
// 未来联机时切换到 httpGameApi 即可
export { mockGameApi as gameApi } from './mock/mockGameApi'
export type { GameApi, ApiResponse, SessionCreated, Unsubscribe } from './types'
