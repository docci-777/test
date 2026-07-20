import { type ReactNode } from 'react'
import { cn } from '@/lib/utils'

interface ParchmentProps {
  children: ReactNode
  className?: string
  variant?: 'default' | 'dark'
}

export default function Parchment({ children, className, variant = 'default' }: ParchmentProps) {
  return (
    <div
      className={cn(
        'parchment-card rounded-lg relative',
        variant === 'dark' && 'bg-parchment-200',
        className,
      )}
    >
      {/* 角落装饰 */}
      <div className="absolute top-1 left-1 w-3 h-3 border-t-2 border-l-2 border-ink-700/60 rounded-tl" />
      <div className="absolute top-1 right-1 w-3 h-3 border-t-2 border-r-2 border-ink-700/60 rounded-tr" />
      <div className="absolute bottom-1 left-1 w-3 h-3 border-b-2 border-l-2 border-ink-700/60 rounded-bl" />
      <div className="absolute bottom-1 right-1 w-3 h-3 border-b-2 border-r-2 border-ink-700/60 rounded-br" />
      {children}
    </div>
  )
}
