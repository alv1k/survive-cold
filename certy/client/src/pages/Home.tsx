import React from 'react';
import { Container, Typography, Button, Grid, Paper } from '@mui/material';
import { Link } from 'react-router-dom';
import Header from '../components/common/Header';
import Footer from '../components/common/Footer';

const Home = () => {
  return (
    <>
      <Header />
      <Container maxWidth="lg" sx={{ mt: 4, mb: 4 }}>
        <Typography variant="h2" align="center" gutterBottom>
          Certy - Certificate Generator
        </Typography>
        <Typography variant="h5" align="center" color="text.secondary" paragraph>
          Generate and print professional certificates for your events with ease.
        </Typography>
        
        <Grid container spacing={4} sx={{ mt: 4 }}>
          <Grid item xs={12} md={4}>
            <Paper sx={{ p: 2, textAlign: 'center' }}>
              <Typography variant="h6" gutterBottom>
                Easy to Use
              </Typography>
              <Typography>
                Upload a list of participants and generate certificates in minutes.
              </Typography>
            </Paper>
          </Grid>
          <Grid item xs={12} md={4}>
            <Paper sx={{ p: 2, textAlign: 'center' }}>
              <Typography variant="h6" gutterBottom>
                Professional Templates
              </Typography>
              <Typography>
                Choose from our collection of professional certificate templates.
              </Typography>
            </Paper>
          </Grid>
          <Grid item xs={12} md={4}>
            <Paper sx={{ p: 2, textAlign: 'center' }}>
              <Typography variant="h6" gutterBottom>
                Print Ready
              </Typography>
              <Typography>
                Download or print certificates directly from the application.
              </Typography>
            </Paper>
          </Grid>
        </Grid>
        
        <Box sx={{ textAlign: 'center', mt: 4 }}>
          <Button 
            variant="contained" 
            size="large" 
            component={Link} 
            to="/certificates"
            sx={{ mr: 2 }}
          >
            Get Started
          </Button>
          <Button 
            variant="outlined" 
            size="large" 
            component={Link} 
            to="/pricing"
          >
            View Pricing
          </Button>
        </Box>
      </Container>
      <Footer />
    </>
  );
};

export default Home;