import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'

export default defineConfig({
  plugins: [vue()],
  server: {
    fs: {
      strict: false
    },
    historyApiFallback: true,
    proxy: {
      '/interview': 'http://localhost:5000'
    }
  }
})
