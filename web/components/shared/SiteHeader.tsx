'use client'

import React from 'react'

export interface SiteHeaderProps {
  /** Current active tool (for highlighting) */
  currentTool?: 'prophet' | 'temples' | 'conference' | 'home'
  /** Optional custom className */
  className?: string
}

const navItems = [
  { href: 'https://latterdaytools.io', label: 'Home', tool: 'home' },
  { href: 'https://prophet.latterdaytools.io', label: 'Prophet Calculator', tool: 'prophet' },
  { href: 'https://temples.latterdaytools.io', label: 'Temple Tracker', tool: 'temples' },
  { href: 'https://conference.latterdaytools.io', label: 'Conference Analytics', tool: 'conference', comingSoon: true },
]

export function SiteHeader({ currentTool, className = '' }: SiteHeaderProps) {
  return (
    <header className={`border-b bg-white ${className}`}>
      <div className="container mx-auto px-4 py-4">
        <div className="flex items-center justify-between">
          {/* Logo */}
          <a href="https://latterdaytools.io" className="flex items-center space-x-2">
            <div className="flex h-10 w-10 items-center justify-center rounded-lg bg-gradient-to-br from-blue-600 to-blue-800 text-white font-bold text-xl">
              LDT
            </div>
            <div className="hidden sm:block">
              <div className="text-lg font-bold text-gray-900">LatterDay Tools</div>
              <div className="text-xs text-gray-500">Data-driven insights</div>
            </div>
          </a>

          {/* Navigation */}
          <nav className="hidden md:flex items-center space-x-6">
            {navItems.map((item) => (
              <a
                key={item.tool}
                href={item.href}
                className={`text-sm font-medium transition-colors hover:text-blue-600 ${
                  currentTool === item.tool
                    ? 'text-blue-600'
                    : 'text-gray-600'
                } ${item.comingSoon ? 'opacity-50 cursor-not-allowed' : ''}`}
                {...(item.comingSoon && { 'aria-disabled': 'true' })}
              >
                {item.label}
                {item.comingSoon && (
                  <span className="ml-1 text-xs bg-gray-200 px-1.5 py-0.5 rounded">Soon</span>
                )}
              </a>
            ))}
          </nav>

          {/* Mobile menu button */}
          <button className="md:hidden p-2 rounded-lg hover:bg-gray-100">
            <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4 6h16M4 12h16M4 18h16" />
            </svg>
          </button>
        </div>
      </div>
    </header>
  )
}
