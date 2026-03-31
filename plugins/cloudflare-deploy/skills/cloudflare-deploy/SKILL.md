---
name: cloudflare-deploy
description: Set up and deploy Astro websites to Cloudflare Workers with custom domains. Use this skill when the user wants to deploy a site to Cloudflare, set up Cloudflare Pages/Workers, configure wrangler.toml, add a custom domain, fix deployment issues, troubleshoot DNS for a Cloudflare-hosted site, or verify a deployment is working. Also use when you see @astrojs/cloudflare, wrangler.toml, or .workers.dev in the project.
---

# Deploy Astro Site to Cloudflare Workers

Guide for setting up and deploying Astro sites to Cloudflare Workers with custom domains. This encodes tested patterns that avoid common pitfalls.

## Critical Rule

**Never run `wrangler deploy` or `wrangler pages deploy` locally.** Deployments happen by pushing to git. The CI/CD pipeline (Cloudflare dashboard connected to GitHub) handles the rest. Local deploys create version drift and bypass any CI checks.

The only local wrangler commands you should run are diagnostic/read-only ones like `wrangler whoami`, `wrangler deployments list`, and `wrangler dev` (local preview).

## Setup Checklist

Work through these steps in order. Each step has a verification check.

### 1. Install the Cloudflare Adapter

```bash
npm install @astrojs/cloudflare
```

Astro 6 also requires an explicit Vite 7 dependency to avoid build errors (`require_dist is not a function`):

```bash
npm install vite@^7
```

**Verify:** `package.json` has both `@astrojs/cloudflare` and `vite: "^7"` in dependencies.

### 2. Configure astro.config.mjs

The adapter should only activate for builds, not during local dev. Use this conditional pattern:

```js
import { defineConfig } from 'astro/config';
import tailwindcss from '@tailwindcss/vite';
import cloudflare from '@astrojs/cloudflare';

export default defineConfig({
  site: 'https://your-domain.example.com',
  adapter: process.argv.includes('dev') ? undefined : cloudflare(),
  vite: {
    plugins: [tailwindcss()],
  },
});
```

The `process.argv.includes('dev')` check means `astro dev` runs without the adapter (faster, no worker emulation), while `astro build` uses it.

**Verify:** Run `npm run dev` and confirm no Cloudflare-related warnings in the console.

### 3. Create wrangler.toml

```toml
name = "your-project-name"
compatibility_date = "2025-03-28"
compatibility_flags = ["nodejs_compat"]

[assets]
directory = "./dist"
```

Pick a `name` that matches your Cloudflare Workers project name. This is the identifier Cloudflare uses, not the display name.

**Verify:** File exists at project root alongside `package.json`.

### 4. Create .gitignore

Ensure these entries are present:

```
node_modules/
dist/
.astro/
.wrangler/
.gstack/
.env
.env.*
.dev.vars*
!.dev.vars.example
!.env.example
.DS_Store
```

The `.wrangler/` directory contains local build artifacts and deployment state that should never be committed.

### 5. Add Build Scripts

Ensure `package.json` has these scripts:

```json
{
  "scripts": {
    "dev": "astro dev",
    "build": "astro build",
    "preview": "npm run build && wrangler dev"
  }
}
```

The `preview` script builds and then runs the Cloudflare worker locally so you can test the production behavior before pushing.

### 6. Verify the Build

```bash
npm run build
```

A successful build will show:
- `[build] adapter: @astrojs/cloudflare`
- Prerendered routes listed
- `[build] Complete!`

Common build failures:
- **`require_dist is not a function`**: Missing `vite: "^7"` in dependencies. Install it.
- **`Cannot find module '@astrojs/cloudflare'`**: Adapter not installed. Run `npm install @astrojs/cloudflare`.
- **Hydration/SSR errors**: Check that components using browser APIs are wrapped in `client:only` directives.

### 7. Push to Deploy

```bash
git add -A
git commit -m "chore: configure Cloudflare Workers deployment"
git push
```

The Cloudflare dashboard should be connected to the GitHub repo with:
- **Build command:** `npm run build`
- **Build output directory:** `dist`
- **Branch:** `main`

## Custom Domains

### Adding a Custom Domain

Add a `routes` entry to `wrangler.toml`:

```toml
routes = [
  { pattern = "subdomain.yourdomain.com", custom_domain = true }
]
```

Then commit and push. Cloudflare will automatically create the DNS record if the domain's zone is managed by Cloudflare.

### Multiple Domains

```toml
routes = [
  { pattern = "www.yourdomain.com", custom_domain = true },
  { pattern = "yourdomain.com", custom_domain = true }
]
```

## Verification and Debugging

After pushing a deployment, verify everything is working. Use the wrangler CLI and standard tools to diagnose issues without deploying locally.

### Verify Deployment Status

Check that the latest deployment went through:

```bash
npx wrangler deployments list --name your-project-name
```

This shows all deployments with timestamps, authors, and version IDs. The most recent entry should match your latest push.

### Verify the Workers Dev URL

Every worker gets a `*.workers.dev` URL automatically. Test it:

```bash
curl -sI https://your-project-name.<account>.workers.dev
```

You should get a 200 response. If this works but the custom domain doesn't, the issue is DNS, not the deployment.

### DNS Debugging

If the custom domain doesn't resolve:

**Step 1: Check DNS resolution**

```bash
dig subdomain.yourdomain.com +short
```

If empty, there's no DNS record yet.

**Step 2: Check if Cloudflare created the record**

When using `custom_domain = true` in routes, Cloudflare should auto-create a DNS record in the zone. Check via the API:

```bash
# List DNS records for the zone
npx wrangler dns list yourdomain.com
```

Or check the Cloudflare dashboard: DNS > Records for the domain zone. Look for a CNAME or A record for the subdomain.

**Step 3: Create the record manually if needed**

If no record was auto-created, add a CNAME manually in the Cloudflare DNS dashboard:

- **Type:** CNAME
- **Name:** `subdomain` (just the subdomain part, not the full domain)
- **Target:** `your-project-name.<account>.workers.dev`
- **Proxy status:** Proxied (orange cloud)

**Step 4: Wait and re-check**

DNS propagation can take a few minutes even within Cloudflare. Re-check:

```bash
dig subdomain.yourdomain.com +short
curl -sI https://subdomain.yourdomain.com
```

**Step 5: SSL issues**

Cloudflare handles SSL automatically for proxied records. If you see certificate errors:

- Make sure the CNAME is proxied (orange cloud, not grey)
- Check that the domain zone has "Full" or "Full (strict)" SSL mode
- Wait a few minutes for the edge certificate to provision

### Verify the Live Site

Once DNS resolves, do a full check:

```bash
# Check HTTP response and headers
curl -sI https://subdomain.yourdomain.com

# Verify correct content is served
curl -s https://subdomain.yourdomain.com | head -20

# Check a subpage works
curl -sI https://subdomain.yourdomain.com/some-page
```

Look for:
- `HTTP/2 200` status
- `cf-ray` header (confirms Cloudflare is serving)
- `server: cloudflare` header
- Correct HTML content in the body

### Common Issues

| Symptom | Cause | Fix |
|---------|-------|-----|
| `Could not resolve host` | No DNS record | Add CNAME in Cloudflare DNS |
| Workers.dev works, custom domain 404s | Route not configured | Add `routes` to `wrangler.toml`, push |
| 522 Connection timed out | Worker crash or timeout | Check `wrangler tail` for errors |
| 1101 Worker threw exception | Runtime error in worker | Check `wrangler tail --name your-project-name` |
| ERR_SSL_VERSION_OR_CIPHER_MISMATCH | DNS record not proxied | Enable proxy (orange cloud) in DNS |
| Old content after push | Cache or deploy not triggered | Check `wrangler deployments list`, purge cache in dashboard |

### Tailing Logs

To see real-time errors from the deployed worker:

```bash
npx wrangler tail --name your-project-name
```

This streams logs from the production worker. Useful for debugging 500 errors, missing routes, or runtime exceptions.

## Environment Variables

For secrets (API keys, tokens), use the Cloudflare dashboard or:

```bash
npx wrangler secret put MY_SECRET --name your-project-name
```

For non-secret config, add to `wrangler.toml`:

```toml
[vars]
PUBLIC_SITE_URL = "https://yourdomain.com"
```

## Disabling the Workers Dev URL

After confirming the custom domain works, you can disable the `.workers.dev` URL:

```toml
workers_dev = false
```

Commit and push.
