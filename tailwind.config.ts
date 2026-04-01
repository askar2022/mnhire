import type { Config } from 'tailwindcss'

const config: Config = {
  content: [
    './pages/**/*.{js,ts,jsx,tsx,mdx}',
    './components/**/*.{js,ts,jsx,tsx,mdx}',
    './app/**/*.{js,ts,jsx,tsx,mdx}',
  ],
  theme: {
    extend: {
      colors: {
        primary: {
          50: '#f0effe',
          100: '#e2ddfd',
          200: '#c5bbfb',
          300: '#a899f8',
          400: '#8b77f5',
          500: '#6b63a8',
          600: '#524b8a',
          700: '#3d3870',
          800: '#2a2650',
          900: '#1a1733',
        },
      },
    },
  },
  plugins: [],
}
export default config
