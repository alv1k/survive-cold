import React from 'react';
import { Container, Typography, Grid, Paper, Box } from '@mui/material';
import { useAuth } from '../contexts/AuthContext';
import { useSubscription } from '../hooks/useSubscription';
import Header from '../components/common/Header';
import Footer from '../components/common/Footer';

const Dashboard = () => {
  const { user } = useAuth();
  const { subscription, loading: subLoading } = useSubscription();

  return (
    <>
      <Header />
      <Container maxWidth="lg" sx={{ mt: 4, mb: 4 }}>
        <Typography variant="h4" gutterBottom>
          Dashboard
        </Typography>
        
        <Grid container spacing={3}>
          <Grid item xs={12} md={8}>
            <Paper sx={{ p: 2, display: 'flex', flexDirection: 'column' }}>
              <Typography variant="h6" gutterBottom>
                Welcome back, {user?.name}!
              </Typography>
              <Typography variant="body1">
                Manage your certificates, view order history, and track your subscription.
              </Typography>
            </Paper>
          </Grid>
          <Grid item xs={12} md={4}>
            <Paper sx={{ p: 2, display: 'flex', flexDirection: 'column' }}>
              <Typography variant="h6" gutterBottom>
                Subscription
              </Typography>
              {subLoading ? (
                <Typography>Loading...</Typography>
              ) : subscription ? (
                <>
                  <Typography>Plan: {subscription.planName}</Typography>
                  <Typography>Expires: {new Date(subscription.endDate).toLocaleDateString()}</Typography>
                  <Typography>Certificates left: {subscription.maxCertificates}</Typography>
                </>
              ) : (
                <Typography>No subscription found</Typography>
              )}
            </Paper>
          </Grid>
        </Grid>
      </Container>
      <Footer />
    </>
  );
};

export default Dashboard;