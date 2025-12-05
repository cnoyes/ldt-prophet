'use client'

import React from 'react'

export interface SiteFooterProps {
  /** Optional custom className */
  className?: string
}

export function SiteFooter({ className = '' }: SiteFooterProps) {
  const currentYear = new Date().getFullYear()

  return (
    <footer className={`border-t bg-gray-50 ${className}`}>
      <div className="container mx-auto px-4 py-8">
        <div className="grid grid-cols-1 md:grid-cols-4 gap-8">
          {/* About */}
          <div className="md:col-span-2">
            <div className="flex items-center space-x-2 mb-3">
              <div className="flex h-8 w-8 items-center justify-center rounded bg-gradient-to-br from-blue-600 to-blue-800 text-white font-bold text-sm">
                LDT
              </div>
              <span className="font-bold text-gray-900">LatterDay Tools</span>
            </div>
            <p className="text-sm text-gray-600 max-w-md">
              Data-driven insights and analytics for members of The Church of Jesus Christ of Latter-day Saints.
              Statistical analysis, visualizations, and tools built with modern technology.
            </p>
          </div>

          {/* Tools */}
          <div>
            <h3 className="font-semibold text-gray-900 mb-3">Tools</h3>
            <ul className="space-y-2 text-sm">
              <li>
                <a href="https://prophet.latterdaytools.io" className="text-gray-600 hover:text-blue-600 transition-colors">
                  Prophet Calculator
                </a>
              </li>
              <li>
                <a href="https://temples.latterdaytools.io" className="text-gray-600 hover:text-blue-600 transition-colors">
                  Temple Tracker
                </a>
              </li>
              <li>
                <span className="text-gray-400">Conference Analytics (Coming Soon)</span>
              </li>
            </ul>
          </div>

          {/* Resources */}
          <div>
            <h3 className="font-semibold text-gray-900 mb-3">Resources</h3>
            <ul className="space-y-2 text-sm">
              <li>
                <a href="https://github.com/cnoyes/ldt-prophet" className="text-gray-600 hover:text-blue-600 transition-colors">
                  GitHub
                </a>
              </li>
              <li>
                <a href="https://latterdaytools.io/about" className="text-gray-600 hover:text-blue-600 transition-colors">
                  About
                </a>
              </li>
              <li>
                <a href="https://latterdaytools.io/faq" className="text-gray-600 hover:text-blue-600 transition-colors">
                  FAQ
                </a>
              </li>
            </ul>
          </div>
        </div>

        {/* Bottom bar */}
        <div className="mt-8 pt-6 border-t border-gray-200">
          <div className="flex flex-col md:flex-row justify-between items-center space-y-2 md:space-y-0">
            <p className="text-xs text-gray-500">
              © {currentYear} LatterDay Tools. Not affiliated with The Church of Jesus Christ of Latter-day Saints.
            </p>
            <div className="flex space-x-6 text-xs text-gray-500">
              <a href="https://latterdaytools.io/privacy" className="hover:text-gray-700">
                Privacy
              </a>
              <a href="https://latterdaytools.io/terms" className="hover:text-gray-700">
                Terms
              </a>
            </div>
          </div>
        </div>
      </div>
    </footer>
  )
}
