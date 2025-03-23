import { UserManager, WebStorageStateStore, User } from 'oidc-client-ts';

// Helper function to get environment variables with fallback values
const getEnvVar = (key: string, defaultValue: string = ''): string => {
  // In Vite, environment variables must be prefixed with VITE_
  const fullKey = key.startsWith('VITE_') ? key : `VITE_${key}`;
  
  // Access through import.meta.env
  const value = import.meta.env[fullKey as keyof ImportMetaEnv];
  
  if (import.meta.env.DEV && value === undefined) {
    console.warn(`Environment variable ${fullKey} not found, using default value`);
  }
  
  return value !== undefined ? String(value) : defaultValue;
};

// Build the complete URL for redirects
const buildUrl = (path: string): string => {
  return `${window.location.origin}${path}`;
};

// Configure the OIDC client
export const userManager = new UserManager({
  authority: getEnvVar('OIDC_AUTHORITY', 'https://sso.garri.ovh/'),
  client_id: getEnvVar('OIDC_CLIENT_ID', '312365402212597763'),
  client_secret: getEnvVar('OIDC_CLIENT_SECRET', ''),
  redirect_uri: buildUrl(getEnvVar('OIDC_REDIRECT_URI', '/callback')),
  response_type: getEnvVar('OIDC_RESPONSE_TYPE', 'code'),
  scope: getEnvVar('OIDC_SCOPE', 'openid profile email'),
  post_logout_redirect_uri: buildUrl(getEnvVar('OIDC_POST_LOGOUT_REDIRECT_URI', '/')),
  silent_redirect_uri: buildUrl(getEnvVar('OIDC_SILENT_REDIRECT_URI', '/silent-renew.html')),
  automaticSilentRenew: getEnvVar('OIDC_AUTOMATIC_SILENT_RENEW', 'true') === 'true',
  loadUserInfo: getEnvVar('OIDC_LOAD_USER_INFO', 'true') === 'true',
  userStore: new WebStorageStateStore({ store: window.localStorage }),
});

// Add development environment logging
if (import.meta.env.DEV) {
  console.log('OIDC Configuration:', {
    authority: userManager.settings.authority,
    client_id: userManager.settings.client_id,
    redirect_uri: userManager.settings.redirect_uri,
    response_type: userManager.settings.response_type,
    scope: userManager.settings.scope,
  });
}

// Export authentication functions
export const login = () => {
  console.log('Initiating login redirect...');
  return userManager.signinRedirect().catch(err => {
    console.error('SigninRedirect error:', err);
    throw err;
  });
};

export const logout = () => userManager.signoutRedirect();
export const getUser = () => userManager.getUser();
export const isAuthenticated = async () => {
  const user = await userManager.getUser();
  return !!user && !user.expired;
};
export const handleCallback = () => userManager.signinRedirectCallback();
export const silentRenew = () => userManager.signinSilentCallback();