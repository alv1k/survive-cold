import React from 'react';
import { Box, Container, Typography, Link } from '@mui/material';

const Footer = () => {
  return (
    <Box component="footer" sx={{ py: 6, backgroundColor: 'background.paper', mt: 'auto' }}>
      <Container maxWidth="lg">
        <Typography variant="body2" color="text.secondary" align="center">
          {'Copyright © '}
          <Link color="inherit" href="https://certy.ru/">
            Certy
          </Link>{' '}
          {new Date().getFullYear()}
          {'.'}
        </Typography>
        <Typography variant="subtitle1" align="center" color="text.secondary" component="p" sx={{ mt: 2 }}>
          Certificate Generation and Printing Service
        </Typography>
      </Container>
    </Box>
  );
};

export default Footer;