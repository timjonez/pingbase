const plugin = require('tailwindcss/plugin')
const fs = require('fs')
const path = require('path')

module.exports = {
  darkMode: 'media',
  content: [
    './js/**/*.js',
    '../lib/pingbase_web.ex',
    '../lib/pingbase_web/**/*.*ex'
  ],
  theme: {
    extend: {
      colors: {
        brand: '#6366f1',
      }
    },
  },
  plugins: [
    require('daisyui'),
    plugin(({addVariant}) => addVariant('phx-no-loading', ['.phx-no-loading&', '.phx-no-loading &'])),
    plugin(({addVariant}) => addVariant('phx-click-loading', ['.phx-click-loading&', '.phx-click-loading &'])),
    plugin(({addVariant}) => addVariant('phx-submit-loading', ['.phx-submit-loading&', '.phx-submit-loading &'])),
    plugin(({addVariant}) => addVariant('phx-change-loading', ['.phx-change-loading&', '.phx-change-loading &']))
  ],
  daisyui: {
    themes: ['light', 'dark'],
    darkTheme: 'dark',
  }
}
