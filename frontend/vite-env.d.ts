/// <reference types="vite/client" />

interface ImportMetaEnv {
  readonly VITE_OIDC_AUTHORITY: string
  readonly VITE_OIDC_CLIENT_ID: string
  readonly VITE_OIDC_CLIENT_SECRET: string
  readonly VITE_OIDC_REDIRECT_URI: string
  readonly VITE_OIDC_RESPONSE_TYPE: string
  readonly VITE_OIDC_SCOPE: string
  readonly VITE_OIDC_POST_LOGOUT_REDIRECT_URI: string
  readonly VITE_OIDC_SILENT_REDIRECT_URI: string
  readonly VITE_OIDC_AUTOMATIC_SILENT_RENEW: string
  readonly VITE_OIDC_LOAD_USER_INFO: string
  // Add other environment variables as needed
}

interface ImportMeta {
  readonly env: ImportMetaEnv
}