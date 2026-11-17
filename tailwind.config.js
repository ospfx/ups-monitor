/** @type {import('tailwindcss').Config} */
export default {
  content: [
    "./index.html",
    "./src/**/*.{vue,js,ts,jsx,tsx}",
  ],
  theme: {
    extend: {
      colors: {
        dark: {
          bg: '#0B0E14',
          surface: '#1E293B',
          border: '#334155',
          text: '#F8FAFC'
        },
        accent: {
          blue: '#38BDF8',
          cyan: '#22D3EE',
          orange: '#F97316'
        }
      }
    },
  },
  plugins: [],
}
