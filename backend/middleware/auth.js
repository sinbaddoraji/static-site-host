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
  if (process.env.NODE_ENV === 'development' && process.env.SKIP_AUTH === 'true') {
    return next();
  }
  return auth(req, res, next);
};

module.exports = {
  auth: conditionalAuth
};