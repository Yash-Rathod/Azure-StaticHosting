# Azure Static Portfolio Hosting â€” Implementation Plan (Pivoted to SWA)

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Host a real portfolio website on Azure Static Web Apps (SWA) for free global CDN delivery and automatic SSL.

**Architecture:** Azure Static Web Apps (Free SKU). Everything provisioned via Azure CLI and SWA CLI.

**Tech Stack:** Azure CLI, Azure Static Web Apps, SWA CLI, PowerShell, HTML/CSS (no JS, no build step)

---

## File Map

| File | Purpose |
|------|---------|
| `site/index.html` | Portfolio page â€” navbar, hero, about, projects |
| `site/styles.css` | Dark theme styles, monospace accents |
| `site/404.html` | Custom error page for static website |
| `site/assets/profile-placeholder.svg` | SVG avatar placeholder |
| `scripts/deploy.ps1` | (Optional) Parameterized full-provision script |

---

## Task 1: Initialize Project Structure
(Completed)

## Task 2: Portfolio HTML
(Completed)

## Task 3: Portfolio CSS
(Completed)

## Task 4: Assets and 404 Page
(Completed)

## Task 5: (Skipped CDN Cache Policy)

## Task 6: (Deployment Script needs update for SWA - skipped for manual steps)

---

## Task 7: Phase 1 â€” Resource Group and Suffix
(Completed: RG 'rg-static-hosting' created, Suffix 'yr8421' chosen)

---

## Task 8: Phase 2 â€” Storage Account (Optional/Cleanup)
(Completed: Storage account created and files uploaded, but we are pivoting to SWA)

---

## Task 9: Phase 3 â€” Azure Static Web App (SWA) Resource

- [ ] **Step 1: Create Static Web App resource**

```powershell
az staticwebapp create `
    --name "swa-portfolio" `
    --resource-group rg-static-hosting `
    --location eastus2 `
    --sku Free
```

Expected: JSON with `"provisioningState": "Succeeded"`. Note: SWA is available in `eastus2`.

- [ ] **Step 2: Get deployment token**

```powershell
$token = az staticwebapp secrets list `
    --name "swa-portfolio" `
    --resource-group rg-static-hosting `
    --query "properties.apiKey" -o tsv
```

- [ ] **Step 3: Verify token retrieved**

```powershell
Write-Host $token
```

---

## Task 10: Phase 4 â€” Deploy Site to SWA

**Prerequisite:** SWA CLI installed (`npm install -g @azure/static-web-apps-cli`).

- [ ] **Step 1: Deploy using SWA CLI**

```powershell
powershell.exe -ExecutionPolicy Bypass -Command "swa deploy 'c:\Users\yashr\AzureProjects\StaticHosting\site' --deployment-token $token --env production"
```

Expected: output showing "Deploying to environment: production" and finally a project URL.

- [ ] **Step 2: Get the SWA URL**

```powershell
az staticwebapp show `
    --name "swa-portfolio" `
    --resource-group rg-static-hosting `
    --query "defaultHostname" -o tsv
```

Expected: `white-stone-0a1b2c3d.azurestaticapps.net`

---

## Task 11: Phase 5 â€” Verify SWA Delivery and Headers

- [ ] **Step 1: Verify in browser**

Open the SWA URL from Task 10 Step 2. Portfolio page should render with full styling.

- [ ] **Step 2: Verify headers**

```powershell
curl.exe -I "https://$(az staticwebapp show --name swa-portfolio --resource-group rg-static-hosting --query defaultHostname -o tsv)"
```

Expected: HTTP 200. SWA automatically provides a global CDN.

---

## Task 12: Update Live Link and Site Text in index.html

**Files:**
- Modify: `site/index.html`

- [ ] **Step 1: Update the live link href and footer text**

In `site/index.html`:
1. Update `id="live-link"` href with the SWA URL.
2. Update footer text to "Hosted on Azure Static Web Apps".
3. Update project description if necessary.

- [ ] **Step 2: Re-deploy**

```powershell
powershell.exe -ExecutionPolicy Bypass -Command "swa deploy 'c:\Users\yashr\AzureProjects\StaticHosting\site' --deployment-token $token --env production"
```

---

## Success Checklist

- [ ] SWA URL loads portfolio page
- [ ] Styles and assets load correctly
- [ ] Project 1 card links to the live SWA URL
- [ ] Deployment succeeded via SWA CLI

---

## Teardown (when done learning)

```powershell
az group delete --name rg-static-hosting --yes --no-wait  
```
