import tailwindcss from '@tailwindcss/vite';
import { sveltekit } from '@sveltejs/kit/vite';
import { defineConfig } from 'vite';

const dev = process.env.NODE_ENV === 'development';

export default defineConfig({
	plugins: [tailwindcss(), sveltekit()],
	base: dev ? '/' : '/BloomeeTunes/',
	server: {
		host: '0.0.0.0',
		port: 5174,
	},
	build: {
		outDir: 'build',
	},
});
