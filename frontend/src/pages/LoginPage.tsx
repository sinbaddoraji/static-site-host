import React from 'react';
import { Box, Button, Container, Typography, Paper } from '@mui/material';
import { useAuth } from '../contexts/AuthContext';

const LoginPage: React.FC = () => {
  const { login } = useAuth();
  
  // Handle login with explicit event prevention
  const handleLogin = (e: React.MouseEvent) => {
    e.preventDefault();
    e.stopPropagation();
    // Use a small timeout to ensure event handling is complete
    setTimeout(() => {
      login();
    }, 10);
  };

  return (
    <Box sx={{ display: 'flex', minHeight: '100vh', alignItems: 'center', justifyContent: 'center', width: '100%' }}>
      <Container component="main" maxWidth="xs">
        <Paper elevation={3} sx={{ p: 4, display: 'flex', flexDirection: 'column', alignItems: 'center' }}>
          <Typography component="h1" variant="h5">
            Static Site Generator
          </Typography>
          <Box sx={{ mt: 2, width: '100%' }}>
            <Button 
              fullWidth 
              variant="contained" 
              color="primary"
              onClick={handleLogin}
            >
              Sign In
            </Button>
          </Box>
        </Paper>
      </Container>
    </Box>
  );
};

export default LoginPage;