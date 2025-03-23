const { expressjwt: jwt } = require('express-jwt');
const jwksRsa = require('jwks-rsa');

// Authentication middleware
const auth = jwt({
  secret: jwksRsa.expressJwtSecret({
    cache: true,
    rateLimit: true,
    jwksRequestsPerMinute: 5,
    jwksUri: `${process.env.AUTH_ISSUER}/.well-known/jwks.json`
  }),
  audience: process.env.AUTH_AUDIENCE,
  issuer: process.env.AUTH_ISSUER,
  algorithms: ['RS256']
});

// Add a conditional auth middleware for development
const conditionalAuth = (req, res, next) => {
  // Force skip auth in development mode - added console log for debugging
  console.log("Auth middleware check - NODE_ENV:", process.env.NODE_ENV, "SKIP_AUTH:", process.env.SKIP_AUTH);
  
  if (process.env.NODE_ENV === 'development' && process.env.SKIP_AUTH === 'true') {
    console.log("Auth middleware bypassed in development mode");
    return next();
  }
  
  console.log("Auth middleware active - JWT will be validated");
  return auth(req, res, next);
};

module.exports = {
  auth: conditionalAuth
};