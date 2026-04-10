# RavenHost Website

Marketing homepage for [ravenhost.org](https://ravenhost.org).

**Stack:** Astro 4 · Tailwind CSS 3 · Three.js · nginx · Docker

---

## Quick Start

### Prerequisites
- Node.js 20+ and npm

### 1 — Copy brand assets into `public/`

The brand assets in the repo root `assets/` directory need to be available at `public/assets/`:

```bash
# From the project root
cp -r assets/* public/assets/
# or on Windows:
xcopy /s assets public\assets\
```

The following files must exist in `public/assets/`:
- `background.png`
- `logo-dark-theme.png`
- `logo-light-theme.png`
- `dashboard.png`
- `dashboard-admin.png`

### 2 — Install dependencies

```bash
npm install
```

### 3 — Run the dev server

```bash
npm run dev
# → http://localhost:4321
```

### 4 — Type-check

```bash
npm run check
```

---

## Production Build

```bash
npm run build
# Output: dist/
```

Preview the production build locally:

```bash
npm run preview
# → http://localhost:4321
```

---

## Docker

### Build and run

```bash
docker build -t ravenhost-web .
docker run --rm -p 3000:80 ravenhost-web
# → http://localhost:3000
```

### Using Docker Compose

```bash
docker compose up -d
```

The container listens on `127.0.0.1:3000` by default — put nginx or Traefik in front.

### Rebuilding after changes

```bash
docker compose up -d --build
```

---

## Deployment

### Behind nginx (reverse proxy)

Add a virtual host config on the host:

```nginx
server {
    listen 443 ssl http2;
    server_name ravenhost.org www.ravenhost.org;

    ssl_certificate     /etc/ssl/ravenhost.org/fullchain.pem;
    ssl_certificate_key /etc/ssl/ravenhost.org/privkey.pem;

    location / {
        proxy_pass       http://127.0.0.1:3000;
        proxy_set_header Host              $host;
        proxy_set_header X-Real-IP         $remote_addr;
        proxy_set_header X-Forwarded-For   $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
# Redirect HTTP → HTTPS
server {
    listen 80;
    server_name ravenhost.org www.ravenhost.org;
    return 301 https://$host$request_uri;
}
```

### Behind Traefik

The `docker-compose.yml` includes Traefik labels — uncomment the `networks` block and
update the `Host()` rule to match your domain.

---

## Security Checklist

- [ ] Enable HTTPS and uncomment the HSTS header in `nginx.conf`
- [ ] Set `server_name` to the real domain in `nginx.conf`
- [ ] Review the CSP header in `nginx.conf` before going live
- [ ] Confirm no `.env` or secret files are copied into the Docker image (`.dockerignore` covers this)
- [ ] Run `docker scout` or `trivy image ravenhost-web` to check for CVEs in the nginx base image
- [ ] Add a sitemap (`public/sitemap.xml`) and submit to Google Search Console

---

## Project Structure

```
src/
  components/       # One file per homepage section
    Header.astro
    Hero.astro       # Three.js 3D scene (lazy-loaded)
    Services.astro
    WhyChoose.astro
    PanelSection.astro
    Features.astro
    Pricing.astro
    FAQ.astro
    ContactCTA.astro
    Footer.astro
  layouts/
    BaseLayout.astro # HTML shell: SEO, OG tags, scroll-reveal observer
  pages/
    index.astro      # Composes all sections
  styles/
    global.css       # Tailwind base + shared component classes

public/
  assets/           # Static brand images (copy from repo root assets/)
  favicon.svg
  robots.txt

Dockerfile           # Multi-stage: Node build → nginx serve
docker-compose.yml
nginx.conf           # Production nginx config with security headers
```

---

## Customising Content

| What to change | Where |
|---|---|
| Pricing plans | `src/components/Pricing.astro` — `plans` array |
| Service cards | `src/components/Services.astro` — `services` array |
| Feature grid | `src/components/Features.astro` — `features` array |
| FAQ entries | `src/components/FAQ.astro` — `faqs` array |
| SEO title / description | `src/layouts/BaseLayout.astro` defaults or `index.astro` props |
| Panel URL | Search for `panel.ravenhost.org` — used in Header, Hero, PanelSection, Footer |
| Contact email | `src/components/ContactCTA.astro` |
| Brand colours | `tailwind.config.mjs` → `theme.extend.colors.brand` |
| 3D scene | `src/components/Hero.astro` `<script>` block |
