// auth-error-handler.ts
export enum AuthErrorType {
    LOGIN_REQUIRED = 'login_required',
    INVALID_TOKEN = 'invalid_token',
    EXPIRED_TOKEN = 'expired_token',
    NETWORK_ERROR = 'network_error',
    UNKNOWN = 'unknown',
  }
  
  export class AuthError extends Error {
    type: AuthErrorType;
    
    constructor(message: string, type: AuthErrorType = AuthErrorType.UNKNOWN) {
      super(message);
      this.type = type;
      this.name = 'AuthError';
    }
  }
  
  export function handleAuthError(error: any): void {
    console.error('Authentication error:', error);
    
    // Determine error type
    let errorType = AuthErrorType.UNKNOWN;
    if (error.error === 'login_required') {
      errorType = AuthErrorType.LOGIN_REQUIRED;
    } else if (error.error === 'invalid_token') {
      errorType = AuthErrorType.INVALID_TOKEN;
    } else if (error.error === 'expired_token') {
      errorType = AuthErrorType.EXPIRED_TOKEN;
    } else if (error.message && error.message.includes('Network Error')) {
      errorType = AuthErrorType.NETWORK_ERROR;
    }
    
    // Handle based on error type
    switch (errorType) {
      case AuthErrorType.LOGIN_REQUIRED:
      case AuthErrorType.INVALID_TOKEN:
      case AuthErrorType.EXPIRED_TOKEN:
        // Redirect to login
        window.location.href = '/login';
        break;
      case AuthErrorType.NETWORK_ERROR:
        // Show network error message
        showErrorNotification('Network error. Please check your connection and try again.');
        break;
      default:
        // General error handling
        showErrorNotification('Authentication error. Please try again or contact support.');
    }
  }
  
  function showErrorNotification(message: string): void {
    // Implement your notification UI
    const errorDiv = document.createElement('div');
    errorDiv.className = 'error-notification';
    errorDiv.textContent = message;
    document.body.appendChild(errorDiv);
    
    // Auto-remove after 5 seconds
    setTimeout(() => {
      errorDiv.remove();
    }, 5000);
  }