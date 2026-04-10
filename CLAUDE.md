# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```bash
npm install          # Install dependencies
npm run dev          # Dev server → http://localhost:4321
npm run build        # Build to dist/
npm run preview      # Serve dist/ locally
npm run check        # Astro + TypeScript type check

docker build -t ravenhost-web .
docker compose up -d --build
```

## Asset Setup

Brand assets live in the repo root `assets/` directory and must be copied to `public/assets/` before building:

```bash
cp -r assets/* public/assets/    # macOS/Linux
xcopy /s assets public\assets\   # Windows
```

Required: `background.png`, `logo-dark-theme.png`, `logo-light-theme.png`, `dashboard.png`, `dashboard-admin.png`

## Architecture

**Stack:** Astro 4 (static output) · Tailwind CSS 3 · Three.js (lazy-loaded) · nginx Docker image

All pages are statically generated (`output: 'static'`). There is no backend or API route.

### Key files

| File | Role |
|---|---|
| `src/layouts/BaseLayout.astro` | HTML shell — SEO/OG meta, scroll-reveal IntersectionObserver |
| `src/pages/index.astro` | Composes all section components |
| `src/styles/global.css` | Tailwind base layer + shared Tailwind `@layer components` (`.btn-primary`, `.card`, `.card-hover`, `.glow-text`, `.section-label`, `.reveal`) |
| `tailwind.config.mjs` | Extends Tailwind with `brand.*` colour scale (primary: `#1a6fff`) and custom animations |
| `nginx.conf` | Production nginx config — security headers (CSP, X-Frame-Options, etc.), asset caching, gzip |
| `Dockerfile` | Multi-stage: Node 22 build → nginx 1.27 serve |

### Component structure

Each homepage section is a standalone Astro component in `src/components/`. Sections in order:
`Header` → `Hero` → `Services` → `WhyChoose` → `PanelSection` → `Features` → `Pricing` → `FAQ` → `ContactCTA` → `Footer`

### Three.js hero

`Hero.astro` contains an inline `<script>` that dynamically imports `three` (code-split by Vite into its own chunk). It:
1. Checks `prefers-reduced-motion` and WebGL availability before loading
2. Renders a rotating icosahedron core + orbiting satellite nodes + particle dust
3. Adds mouse-parallax camera movement

### Scroll animations

`BaseLayout.astro` registers a single `IntersectionObserver` that adds `.visible` to any `.reveal` element when it scrolls into view. The CSS transition is defined in `global.css`.

### Colours

All brand colours use the custom `brand.*` Tailwind scale. Use `text-brand-400` / `bg-brand-500` for accents. Backgrounds use Tailwind's built-in `slate-950` / `slate-900` / `slate-800`.

### Panel URL

All links to the client panel point to `https://panel.ravenhost.org`. The panel runs FeatherPanel v1.3.3 (MythicalSystems). The panel's REST API (`assets/openapi.json`) is not currently used by this site.

## Content locations

| Content | File | Location |
|---|---|---|
| Pricing plans | `src/components/Pricing.astro` | `plans` array |
| Service cards | `src/components/Services.astro` | `services` array |
| Feature grid | `src/components/Features.astro` | `features` array |
| FAQ entries | `src/components/FAQ.astro` | `faqs` array |
| Nav links | `src/components/Header.astro` | `navLinks` array |
| Footer links | `src/components/Footer.astro` | `links` object |
