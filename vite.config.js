import { defineConfig } from 'vite';

/* Сборка киоска: один минимизированный бандл js/dist/app.js.
   JSX компилируется на сборке (автоматический рантайм, babel в браузере не нужен). */
export default defineConfig({
  esbuild: {
    jsx: 'automatic',
  },
  build: {
    outDir: 'js/dist',
    emptyOutDir: true,
    target: 'es2018',
    rollupOptions: {
      input: 'js/app.jsx',
      output: {
        entryFileNames: 'app.js',
        inlineDynamicImports: true,
      },
    },
  },
});
