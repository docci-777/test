import { type ButtonHTMLAttributes, type ReactNode } from 'react'
import { cn } from '@/lib/utils'

interface InkButtonProps extends ButtonHTMLAttributes<HTMLButtonElement> {
  variant?: 'default' | 'primary' | 'ghost'
  size?: 'sm' | 'md' | 'lg'
  children: ReactNode
}

export default function InkButton({
  children,
  className,
  variant = 'default',
  size = 'md',
  disabled,
  ...rest
}: InkButtonProps) {
  return (
    <button
      className={cn(
        'ink-button rounded-md font-display',
        variant === 'primary' && 'ink-button--primary',
        variant === 'ghost' && '!bg-transparent !border-transparent !shadow-none hover:!bg-ink-700/10',
        size === 'sm' && 'px-3 py-1 text-xs',
        size === 'md' && 'px-4 py-2 text-sm',
        size === 'lg' && 'px-6 py-3 text-base',
        className,
      )}
      disabled={disabled}
      {...rest}
    >
      {children}
    </button>
  )
}
