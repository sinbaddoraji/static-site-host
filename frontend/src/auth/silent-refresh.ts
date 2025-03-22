import { userManager } from './oidc-config';

userManager.signinSilentCallback()
  .catch(error => {
    console.error('Silent refresh error:', error);
  });