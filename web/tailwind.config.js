/** @type {import('tailwindcss').Config} */

export default {
  darkMode: 'class',
  content: ['./index.html', './src/**/*.{js,ts,jsx,tsx}'],
  theme: {
    container: {
      center: true,
    },
    extend: {
      colors: {
        parchment: {
          50: '#faf2dc',
          100: '#f0e2c1',
          200: '#e8d8b0',
          300: '#dcc896',
          400: '#c9ad75',
          500: '#b08f54',
          600: '#8c6f3e',
          700: '#634a26',
          800: '#3a2b15',
          900: '#1d1408',
        },
        ink: {
          50: '#f5f1ea',
          100: '#e6dccb',
          200: '#c8b594',
          300: '#9a8163',
          400: '#5a4632',
          500: '#3a2a1c',
          600: '#2b1810',
          700: '#1f1109',
          800: '#150b06',
          900: '#0a0503',
        },
        sea: {
          50: '#dbeafe',
          100: '#a3c5e6',
          200: '#5a8ab8',
          300: '#2b6cb0',
          400: '#1e4a7d',
          500: '#1e3a5f',
          600: '#16304f',
          700: '#0f2438',
          800: '#081827',
          900: '#040d18',
        },
        terrain: {
          mountains: '#8a8d8f',
          hills: '#b86b3a',
          forest: '#2d5a3d',
          fields: '#d4a23a',
          pasture: '#8fbf5e',
          desert: '#e6c878',
          gold: '#e6b840',
          shallow: '#3a6a8f',
          deep: '#1e3a5f',
        },
        player: {
          red: '#c4421f',
          blue: '#2b6cb0',
          white: '#e8e2d5',
          orange: '#dd7e2c',
          redDark: '#7a2810',
          blueDark: '#173f6b',
          whiteDark: '#a8a08a',
          orangeDark: '#8e4a10',
        },
        gold: '#e6b840',
        crimson: '#c4421f',
      },
      fontFamily: {
        display: ['Cinzel', 'serif'],
        serif: ['"Crimson Text"', 'Georgia', 'serif'],
        mono: ['"Fira Code"', 'monospace'],
      },
      boxShadow: {
        parchment: '0 4px 18px rgba(43, 24, 16, 0.35), inset 0 0 60px rgba(110, 76, 36, 0.18)',
        ink: '0 0 0 1px #2b1810, 0 4px 12px rgba(43, 24, 16, 0.5)',
        'inner-ink': 'inset 0 0 0 1px rgba(43, 24, 16, 0.4)',
      },
      backgroundImage: {
        'parchment-texture':
          "radial-gradient(at 20% 10%, rgba(255,240,200,0.4) 0px, transparent 50%), radial-gradient(at 80% 0%, rgba(220,180,120,0.35) 0px, transparent 50%), radial-gradient(at 0% 50%, rgba(200,150,90,0.3) 0px, transparent 50%), radial-gradient(at 80% 80%, rgba(180,130,70,0.4) 0px, transparent 50%)",
        'ocean-texture':
          "radial-gradient(at 20% 20%, rgba(60,100,140,0.4) 0px, transparent 60%), radial-gradient(at 80% 0%, rgba(30,60,100,0.5) 0px, transparent 60%), radial-gradient(at 0% 100%, rgba(20,40,80,0.6) 0px, transparent 60%)",
        'paper-grain':
          "repeating-linear-gradient(0deg, rgba(43,24,16,0.02) 0 1px, transparent 1px 3px), repeating-linear-gradient(90deg, rgba(43,24,16,0.02) 0 1px, transparent 1px 3px)",
      },
      keyframes: {
        roll: {
          '0%': { transform: 'rotateX(0) rotateY(0)' },
          '100%': { transform: 'rotateX(360deg) rotateY(720deg)' },
        },
        fadeIn: {
          from: { opacity: '0', transform: 'translateY(8px)' },
          to: { opacity: '1', transform: 'translateY(0)' },
        },
        slideIn: {
          from: { opacity: '0', transform: 'translateX(-12px)' },
          to: { opacity: '1', transform: 'translateX(0)' },
        },
        glow: {
          '0%, 100%': { boxShadow: '0 0 12px 2px rgba(230, 184, 64, 0.4)' },
          '50%': { boxShadow: '0 0 24px 8px rgba(230, 184, 64, 0.7)' },
        },
        float: {
          '0%, 100%': { transform: 'translateY(0)' },
          '50%': { transform: 'translateY(-4px)' },
        },
      },
      animation: {
        roll: 'roll 1.2s ease-in-out',
        fadeIn: 'fadeIn 0.3s ease-out',
        slideIn: 'slideIn 0.3s ease-out',
        glow: 'glow 2s ease-in-out infinite',
        float: 'float 3s ease-in-out infinite',
      },
    },
  },
  plugins: [],
}
