# OIDC Setup (Google) for Expertiza Backend

This guide explains how to configure `Google Cloud Console` so this Rails app can authenticate with OIDC and access a user's `email`.

> Note:
> 
> Current provider config is in `config/oidc_providers.yml` under `providers.google-ncsu`.

---

## 1: Prerequisites

- Google account with access to [Google Cloud Console](https://console.cloud.google.com/)
- The full stack to be running
  - Vite/React Frontend
  - Ruby on Rails API (This project)
  - MySQL database
  - Redis (currently used for caching, though not specifically for offloading temporary OIDC tokens)
- The redirect URI that matches the app config exactly
    - Local example: `http://localhost:3000/auth/callback`
    - This value should come from `GOOG_REDIRECT_URI`

---

## 2: Create or select a Google Cloud project

1. Open [Google Cloud Console](https://console.cloud.google.com/).
2. Create a [new project](https://console.cloud.google.com/projectcreate) (or select an existing one).
3. Make sure the selected project is the one you want for OIDC.
    - If you create a new project but had existing projects, you may need to select your new project.
    - Google will sometimes select the previous project you used rather than the newly created project.

---

## 3) Configure OAuth consent screen

1. Go to Explore and Enable APIs: [APIs Dashboard](https://console.cloud.google.com/apis/dashboard)
2. Click the **OAuth consent screen** in the side navigation.
3. Click "Get Started" and fill in the required app details
    - App name
        - ex: NCSU SSO
    - Support email
        - For local dev use your email
    - Developer contact email
        - For local dev use your email
4. Choose **External** (unless you've been instructed otherwise for test/production).
5. Agree to the API terms and create

### Configure Scopes
1. Select `Data Access` in the left navigation
2. Click Add/Remove **Scopes**
    - At a minimum we need to add:
        - `openid`
        - `email`, displays as `.../auth/userinfo.email`
        - `profile`, displays as `.../auth/userinfo.profile`

#### Why not `email scope only`

For OIDC login, Google should receive `openid email`.

- `email` gives access to the email claim.
- `openid` is required for an OIDC ID token.

If you send only `email` without `openid`, OIDC token validation will fail.

---

## 4) Add test users (if app is in Testing mode)
- Click `Audience`, in the side navigation
- Go to the `Test Users` Section
- Click `Add users`
- Enter your ncsu email, press enter and save

---

## 5) Create OAuth client credentials

1. Select `Clients` from the side navigation
2. Click `Create Client` button at the top of the screen
3. Application type: **Web application**
4. Name it as Expertiza SSO
    - append Dev or Test to the name if necessary
5. Add **Authorized redirect URI**:
    - Enter the frontend auth callback url
        - Local Dev should have the redirect URI from Step 1
6. Click Save

> _**Important!**_ This is the only time you will see the secret
>
> The window with the credentials gives the option to download the id and secret as JSON
>
> If this is for production, Download the JSON and Save it to a KeyVault for future use/reference

7. Copy:
	- **Client ID**
	- **Client Secret**

---

## 6) Configure app environment variables

Set these environment variables for the Rails application:

- `GOOG_CLIENT_ID`
- `GOOG_CLIENT_SECRET`
- `GOOG_REDIRECT_URI`

Examples:

- powershell
    ```powershell
    $env:GOOG_CLIENT_ID="<app_client_id>"
    $env:GOOG_CLIENT_SECRET="<app_client_secret>"
    $env:GOOG_REDIRECT_URI="<http_frontend_baseurl>/auth/callback"
    ```

- bash/wsl
    ```bash
    export GOOG_CLIENT_ID="<app_client_id>"
    export GOOG_CLIENT_SECRET="<app_client_secret>"
    export GOOG_REDIRECT_URI="<http_frontend_baseurl>/auth/callback"
    ```

If you use Docker Compose:

- You can either add the env settings to the environment settings or
  - If you use this option DO NOT commit Compose file
- You can create a .env file and have docker compose reference it.  Then put the OIDC info in your env file and redeploy with Docker Compose.

Docker .env example

```env
GOOG_CLIENT_ID='xxxxxxx.apps.googleusercontent.com'
GOOG_CLIENT_SECRET='XXXXXX-xxxxxxxxxxxxxxxxxxxxxxxxx'
GOOG_REDIRECT_URI='http://localhost:3000/auth/callback'
```
---

## 7) Verify provider config

`config/oidc_providers.yml` should match:

- `issuer: https://accounts.google.com`
- `client_id: <%= ENV['GOOG_CLIENT_ID'] %>`
- `client_secret: <%= ENV['GOOG_CLIENT_SECRET'] %>`
- `redirect_uri: <%= ENV['GOOG_REDIRECT_URI'] %>`

`scopes` is currently optional in this repo.

If omitted, `OidcConfig.scopes_for` defaults to:

- `openid email profile`

If you want to restrict to email-focused login:

- Keep `openid email`
- Remove `profile` from the actual scope source:
    - If the provider defines `scopes` in `config/oidc_providers.yml`, set it to `openid email`
    - If `scopes` is omitted, the fallback comes from `OidcConfig.scopes_for`, so update that default if you want repo-wide behavior without `profile`

---

## 8) Quick runtime validation

1. Start the backend.
2. Call provider list endpoint:

```text
GET /auth/providers
```

Expected result: includes `google-ncsu`.

If you get an empty array, confirm env vars are present in the running process.

---

## 9) Common issues

### Empty `/auth/providers`

- Usually means one or more required provider fields are blank after ERB eval.
- Most often `GOOG_CLIENT_ID`, `GOOG_CLIENT_SECRET`, or `GOOG_REDIRECT_URI` is missing.
- Error reporting can be found in the Rails logs.

### Redirect URI mismatch

- Google and app must match **exactly** (scheme, host, port, path).

### `invalid_client`

- Wrong client ID/secret pair, or credentials from a different project.

### Consent screen/test user errors

- Add your account as test user if app is in Testing mode.

---

## 10) Production notes

- Use production redirect URI (HTTPS).
- Store secrets in a secure secret manager or deployment environment.
- **Do not commit credentials to git**
