# Automated Deployment Instructions (GICF)

## 0) What “deployment” means for GICF

You’re provisioning and wiring up:

1. **SharePoint site** (home for compliance data and evidence)
2. **Microsoft Lists** (Controls, Framework Mappings, Evidence, POA&Ms)
3. **Document library structure** (evidence repository)
4. **Teams** (Ops channels + notifications)
5. **Power Automate flows** (reminders, evidence expiry, POA&M creation, ticket sync)
6. **Power BI workspace + dataset + reports**
7. **Integrations** (ServiceNow / Jira) via connectors or webhooks


# 1) Prerequisites

## 1.1 Tenant requirements

* Microsoft 365 tenant with:

  * SharePoint Online
  * Teams
  * Power Automate
  * Power BI (Pro or PPU depending on org)
* Permissions:

  * Global Admin (for initial consent and app registrations)
  * SharePoint Admin
  * Power Platform Admin (or Environment Maker + permission to import solutions)

## 1.2 Workstation / Runner requirements

Use a deployment runner (your laptop, a VM, or GitHub Actions runner) with:

* **PowerShell 7+**
* **PnP.PowerShell**
* **Microsoft.Graph PowerShell SDK**
* **Power Platform CLI (pac)**
* Optional: **Azure CLI** (if you store secrets in Key Vault)

### Install (PowerShell)

```powershell
# PowerShell modules
Install-Module PnP.PowerShell -Scope CurrentUser -Force
Install-Module Microsoft.Graph -Scope CurrentUser -Force

# Power Platform CLI (Windows)
winget install Microsoft.PowerPlatformCLI
```


# 2) Repo structure for automation

Add these folders to your repo:

```markdown
grc-integrated-control-framework/
├── deploy/
│   ├── config/
│   │   ├── dev.json
│   │   ├── test.json
│   │   └── prod.json
│   ├── scripts/
│   │   ├── 01-connect.ps1
│   │   ├── 02-sharepoint-site.ps1
│   │   ├── 03-lists.ps1
│   │   ├── 04-libraries.ps1
│   │   ├── 05-teams.ps1
│   │   ├── 06-powerplatform-import.ps1
│   │   ├── 07-powerbi-deploy.ps1
│   │   └── 08-integrations.ps1
│   └── pipelines/
│       └── github-actions.yml
```

Your `config/*.json` drives environment-specific values (site URL, workspace name, owners, etc).


# 3) Identity + Secrets model (do this once)

## 3.1 Create an Entra ID app registration for deployment

Create an app registration (or use a service principal) with certificate auth.

**Graph API permissions (application):**

* Sites.ReadWrite.All
* Group.ReadWrite.All (for Teams/Groups)
* Directory.ReadWrite.All (optional, only if you automate group owners and such)

**PnP/SharePoint:**

* Use certificate-based auth for unattended SharePoint provisioning.

> One-time manual step: Admin consent for the app permissions.

## 3.2 Store secrets

Store these as GitHub Actions secrets or in Key Vault:

* `TENANT_ID`
* `CLIENT_ID`
* `CERT_THUMBPRINT` or base64 PFX
* `CERT_PASSWORD` (if using PFX)
* `ADMIN_UPN` (optional for interactive runs)


# 4) Automated provisioning steps (what your scripts do)

## Step 1: Connect (01-connect.ps1)

* Connect to Graph using service principal
* Connect to SharePoint using PnP certificate auth

**Outcome:** authenticated session for all subsequent steps.


## Step 2: Create the SharePoint site (02-sharepoint-site.ps1)

Provision a site like:

* `https://<tenant>.sharepoint.com/sites/GICF`
* Set owners group (Compliance Owners)
* Enable versioning + retention defaults (as needed)

**Automation options**

* Graph can create sites, but **PnP.PowerShell is easier** for repeatable provisioning.


## Step 3: Provision Microsoft Lists as SharePoint lists (03-lists.ps1)

Create lists + fields from your schemas:

* `Controls`
* `FrameworkMappings`
* `EvidenceRegister`
* `POAM`

**Tip:** Store list schemas in JSON and have a script:

* Create list if missing
* Add columns if missing
* Apply content types (optional)
* Apply list formatting JSON (optional)


## Step 4: Create Evidence libraries + folders (04-libraries.ps1)

Create doc libraries, for example:

* `Evidence`

  * `/Evidence/<Framework>/<ControlID>/...`

Enable:

* Required metadata columns (ControlID, Framework, EvidenceType, ExpirationDate)
* Versioning
* Sensitivity label defaults (if org uses Purview)


## Step 5: Provision Teams (05-teams.ps1)

Create (or bind to) a Microsoft 365 Group + Team:

* `GICF - Compliance Operations`
  Channels:
* `#announcements`
* `#controls`
* `#poam`
* `#audits`
* `#vendors`

Automate:

* Owners/members assignment
* Add SharePoint tab links
* Add Power BI dashboard tab link (later)


# 5) Deploy Power Automate + Power Platform assets

This is the cleanest approach:

## 5.1 Package flows into a Power Platform Solution

Instead of importing raw flow JSONs manually, convert your flows into:

* A **Power Platform Solution** (managed or unmanaged)
* With environment variables for:

  * SharePoint Site URL
  * List names
  * Teams IDs
  * ServiceNow/Jira endpoints
  * Severity mapping

## 5.2 Automate import with PAC CLI (06-powerplatform-import.ps1)

* Authenticate to Power Platform
* Create/select environment (Dev/Test/Prod)
* Import solution
* Set environment variables
* Turn flows on

> One-time manual step (sometimes): Approve connector connections for ServiceNow/Jira if your org requires interactive consent.


# 6) Power BI automated deployment

## Recommended approach

Use **Power BI Deployment Pipelines**:
* Dev → Test → Prod
* Automate dataset parameter updates per environment
* Use service principal for publish (requires Power BI admin enabling SP APIs)

## What you automate (07-powerbi-deploy.ps1)

* Create workspace (or verify)
* Publish PBIX to Dev workspace (service principal)
* Bind dataset parameters:
  * SharePoint Site URL
  * List endpoints
* Promote through pipeline

> One-time manual step: Workspace permission model + pipeline creation may require admin action depending on tenant settings.


# 7) Ticketing integration automation

## ServiceNow options

1. **Power Automate ServiceNow connector** (fastest)
2. **Webhook to ServiceNow Scripted REST API** (most controllable)
3. **Graph + Azure Function middle layer** (if you want more robust transforms)

## Jira options

1. Power Automate Jira connector
2. Jira webhooks + REST API

**What your integration flow does**

* POA&M item created/updated in `POAM` list
* Create or update ticket in ServiceNow/Jira
* Store back:

  * Ticket ID
  * Ticket URL
  * Ticket Status


# 8) CI/CD pipeline (GitHub Actions pattern)

You’ll have a pipeline that does:

1. Run PowerShell scripts in order
2. Import Power Platform solution
3. Deploy Power BI

Minimal example flow:

* Trigger: `push` to `main`
* Environment: dev/test/prod with approvals

Key idea:
* **Everything is idempotent** (safe to re-run)


# 9) Operator verification checklist (post-deploy)

After automation runs, verify:
* SharePoint site exists + correct permissions
* Lists exist + columns created + sample row insert works
* Evidence library has metadata + folder structure
* Teams exists + channels + tabs
* Flows are enabled and firing:
  * evidence expiry reminder
  * POA&M creation
  * SLA reminders
  * ticket sync
* Power BI dashboard loads and shows list-backed data
* Ticket sync writes back ticket URL/status


# 10) The “minimum manual” items you should expect

Even with automation, these are usually one-time manual:

* Admin consent for app registration permissions
* Creating/authorizing connector connections (ServiceNow/Jira) if governed
* Power BI tenant setting allowing service principals
* Sensitivity label / Purview policies if enforced org-wide

---

# Phase 2: Zero-to-Hero Deployment (Validation Guide)

## 0) Goal
Go from "No Access" to a "Fully Deployed GICF Environment" for validation purposes.

## 1) Get a Tenant (Free)
1.  **Join the Microsoft 365 Developer Program**:
    *   Go to [developer.microsoft.com/microsoft-365/dev-program](https://developer.microsoft.com/en-us/microsoft-365/dev-program).
    *   Sign in with a personal Microsoft account.
    *   Select "Set up E5 subscription".
    *   This gives you a free, renewable tenant with 25 licenses (e.g., `admin@yourdevtenant.onmicrosoft.com`).

## 2) Prepare Your Local Environment
1.  **Install PowerShell 7**:
    *   Windows: `winget install --id Microsoft.PowerShell --source winget`
2.  **Install Configured Modules**:
    ```powershell
    Install-Module PnP.PowerShell -Force
    Install-Module Microsoft.Graph -Force
    ```
3.  **Install Power Platform CLI**:
    *   `winget install Microsoft.PowerPlatformCLI`

## 3) Configure Deployment
1.  Open `deploy/config/dev.json`.
2.  Update `tenantId` (From Azure Portal > Overview).
3.  Update `sharePoint.siteUrl` to match your new tenant (e.g., `https://<yourdevtenant>.sharepoint.com/sites/GICF`).
4.  Update `ownerEmail` to your dev admin email.

## 4) Execute Deployment (The "One-Click" Experience)
Run the following in PowerShell 7:

```powershell
cd deploy/scripts

# 1. Connect
./01-connect.ps1 -ConfigPath "../config/dev.json"

# 2. Deploy Infrastructure
./02-sharepoint-site.ps1
./03-lists.ps1
./04-libraries.ps1
./05-teams.ps1

# 3. Simulate Platform Deploy (Since we are in Dev Mode)
./06-powerplatform-import.ps1
./07-powerbi-deploy.ps1
```

## 5) Verify Result (Evidence)
1.  **SharePoint**: Navigate to `https://<yourdevtenant>.sharepoint.com/sites/GICF`.
    *   Verify "Evidence" library exists.
    *   Verify Lists (Controls, POAM) exist.
2.  **Teams**: Check for "GICF - Compliance Operations" team.
3.  **Visual Verification**:
    *   Open `preview/dashboard.html` in your browser to see the simulated populated state of the dashboards.

