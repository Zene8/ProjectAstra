export default defineNuxtConfig({
  devtools: {
    enabled: true
  },
  modules: [
    '@nuxtjs/tailwindcss'
  ],
  tailwindcss: {
    cssPath: '~/assets/css/tailwind.css',
    configPath: 'tailwind.config.js',
    exposeConfig: false,
    injectPosition: 'first',
    viewer: true,
  },
  css: [
    '~/assets/css/main.css'
  ]
})