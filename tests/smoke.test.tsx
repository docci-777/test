import { act, StrictMode } from 'react'
import { createRoot, type Root } from 'react-dom/client'
import { describe, expect, it } from 'vitest'
import App from '../src/App'

// React 19 在测试环境中需要显式开启 act 环境，避免同步渲染告警。
;(globalThis as { IS_REACT_ACT_ENVIRONMENT?: boolean }).IS_REACT_ACT_ENVIRONMENT = true

function mountApp(host: HTMLElement): Root {
  const root = createRoot(host)
  act(() => {
    root.render(
      <StrictMode>
        <App />
      </StrictMode>,
    )
  })
  return root
}

describe('App smoke test', () => {
  // 正常：启动页面渲染出标题与状态说明。
  it('renders the scaffold landing page', () => {
    const host = document.createElement('div')
    document.body.appendChild(host)

    const root = mountApp(host)

    expect(host.textContent).toContain('Hex Settlers')
    expect(host.textContent).toContain('M0 工程初始化')

    act(() => {
      root.unmount()
    })
    host.remove()
  })

  // 边界：卸载后可以在同一容器上重新挂载。
  it('remounts after unmount in the same container', () => {
    const host = document.createElement('div')
    document.body.appendChild(host)

    const first = mountApp(host)
    act(() => {
      first.unmount()
    })
    expect(host.textContent).toBe('')

    const second = mountApp(host)
    expect(host.textContent).toContain('Hex Settlers')

    act(() => {
      second.unmount()
    })
    host.remove()
  })

  // 边界：挂载到尚未插入 document 的游离节点也能正常渲染。
  it('renders into a detached container', () => {
    const host = document.createElement('div')

    const root = mountApp(host)

    expect(host.textContent).toContain('Hex Settlers')

    act(() => {
      root.unmount()
    })
  })
})
