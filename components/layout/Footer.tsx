export function Footer() {
  return (
    <footer className="bg-gray-50 border-t border-gray-200 print:hidden">
      <div className="max-w-7xl mx-auto py-12 px-4 sm:px-6 lg:px-8">
        <div className="grid grid-cols-1 md:grid-cols-3 gap-8">
          <div>
            <h3 className="text-sm font-semibold text-gray-900 tracking-wider uppercase">
              MNHire
            </h3>
            <p className="mt-4 text-base text-gray-500">
              Minnesota Hiring Simplified — connecting great schools with great talent.
            </p>
          </div>
          <div>
            <h3 className="text-sm font-semibold text-gray-900 tracking-wider uppercase">
              Resources
            </h3>
            <ul className="mt-4 space-y-4">
              <li>
                <a href="/careers" className="text-base text-gray-500 hover:text-gray-900">
                  View Open Positions
                </a>
              </li>
              <li>
                <a href="/my-applications" className="text-base text-gray-500 hover:text-gray-900">
                  My Applications
                </a>
              </li>
            </ul>
          </div>
          <div>
            <h3 className="text-sm font-semibold text-gray-900 tracking-wider uppercase">
              Contact
            </h3>
            <p className="mt-4 text-base text-gray-500">
              For questions about applications or demo access, contact us at{' '}
              <a href="mailto:demo@mnhire.org" className="text-primary-600 hover:underline">
                demo@mnhire.org
              </a>
            </p>
          </div>
        </div>
        <div className="mt-8 border-t border-gray-200 pt-8">
          <div className="text-center space-y-2">
            <p className="text-sm text-gray-500">
              App designed and implemented by <span className="font-semibold text-gray-700">Dr. Askar</span> — Business Automation LLC
            </p>
            <p className="text-xs text-gray-400">
              All rights reserved © MNHire {new Date().getFullYear()}
            </p>
          </div>
        </div>
      </div>
    </footer>
  )
}
