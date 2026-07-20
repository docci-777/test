import { type ReactNode, useEffect } from 'react'
import { X } from 'lucide-react'
import Parchment from './Parchment'
import { cn } from '@/lib/utils'

interface ModalProps {
  open: boolean
  onClose?: () => void
  title?: string
  children: ReactNode
  className?: string
  size?: 'sm' | 'md' | 'lg'
  closable?: boolean
}

export default function Modal({
  open,
  onClose,
  title,
  children,
  className,
  size = 'md',
  closable = true,
}: ModalProps) {
  useEffect(() => {
    if (!open) return
    const handler = (e: KeyboardEvent) => {
      if (e.key === 'Escape' && closable) onClose?.()
    }
    window.addEventListener('keydown', handler)
    return () => window.removeEventListener('keydown', handler)
  }, [open, closable, onClose])

  if (!open) return null

  return (
    <div
      className="modal-backdrop fixed inset-0 z-50 flex items-center justify-center p-4 animate-fadeIn"
      onClick={() => closable && onClose?.()}
    >
      <Parchment
        className={cn(
          'relative max-h-[90vh] overflow-auto',
          size === 'sm' && 'w-full max-w-md p-4',
          size === 'md' && 'w-full max-w-2xl p-6',
          size === 'lg' && 'w-full max-w-5xl p-8',
          className,
        )}
      >
        {/* onClick 阻止冒泡 */}
        <div onClick={(e) => e.stopPropagation()}>
          {title && (
            <div className="flex items-center justify-between mb-4 pb-3 border-b border-ink-700/30">
              <h2 className="font-display text-2xl font-bold text-ink-700 tracking-wide">{title}</h2>
              {closable && (
                <button
                  onClick={onClose}
                  className="text-ink-700/60 hover:text-ink-700 transition-colors"
                  aria-label="关闭"
                >
                  <X size={20} />
                </button>
              )}
            </div>
          )}
          {children}
        </div>
      </Parchment>
    </div>
  )
}
