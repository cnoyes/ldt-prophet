'use client'

import React from 'react'
import { SiteHeader, SiteHeaderProps } from './SiteHeader'
import { SiteFooter } from './SiteFooter'

export interface AppLayoutProps {
  /** Children components to render in the main content area */
  children: React.ReactNode
  /** Current active tool for header highlighting */
  currentTool?: SiteHeaderProps['currentTool']
  /** Optional custom className for main content */
  className?: string
  /** Optional: disable footer */
  noFooter?: boolean
  /** Optional: disable header */
  noHeader?: boolean
}

export function AppLayout({
  children,
  currentTool,
  className = '',
  noFooter = false,
  noHeader = false,
}: AppLayoutProps) {
  return (
    <div className="flex min-h-screen flex-col">
      {!noHeader && <SiteHeader currentTool={currentTool} />}

      <main className={`flex-1 ${className}`}>
        {children}
      </main>

      {!noFooter && <SiteFooter />}
    </div>
  )
}
