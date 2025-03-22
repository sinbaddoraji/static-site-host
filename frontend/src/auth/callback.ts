// callback.ts
import { userManager } from './oidc-config';
import { handleAuthError } from './auth-error-handler';

async function handleCallback() {
  try {
    await userManager.signinRedirectCallback();
    window.location.href = '/'; // Redirect to your app's main page
  } catch (error) {
    handleAuthError(error);
  }
}

handleCallback();