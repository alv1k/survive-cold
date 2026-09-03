import React, { useState } from 'react';
import { Container, Typography, Button, Box, Paper, Stepper, Step, StepLabel, TextField, FormControl, InputLabel, Select, MenuItem, Grid } from '@mui/material';
import { paymentAPI } from '../api/payments';
import Header from '../components/common/Header';
import Footer from '../components/common/Footer';

const Payment = () => {
  const [activeStep, setActiveStep] = useState(0);
  const [amount, setAmount] = useState<number>(0);
  const [paymentMethod, setPaymentMethod] = useState<string>('');
  const [couponCode, setCouponCode] = useState<string>('');
  const [discount, setDiscount] = useState<number>(0);
  const [paymentProcessing, setPaymentProcessing] = useState<boolean>(false);

  const steps = ['Select Plan', 'Apply Coupon', 'Payment Method', 'Confirm Payment'];

  const plans = [
    { id: 'basic', name: 'Basic Plan', price: 990, certificates: 50 },
    { id: 'pro', name: 'Pro Plan', price: 1990, certificates: 200 },
    { id: 'premium', name: 'Premium Plan', price: 2990, certificates: 500 },
  ];

  const handleApplyCoupon = async () => {
    if (!couponCode) return;
    
    try {
      const response = await paymentAPI.applyCoupon(couponCode);
      // Calculate discount based on the response
      // This would be calculated based on the actual API response
      setDiscount(10); // Example: 10% discount
      alert(`Coupon applied! You get ${discount}% discount.`);
    } catch (error) {
      alert('Invalid coupon code');
    }
  };

  const handlePayment = async () => {
    setPaymentProcessing(true);
    try {
      // In a real app, this would create a payment via YooKassa
      const response = await paymentAPI.createPayment({
        amount: amount,
        currency: 'RUB',
        paymentMethod,
        couponCode
      });
      
      // Redirect to payment confirmation page
      alert('Payment initiated. Redirecting to payment page...');
      // window.location.href = response.data.confirmation.confirmation_url;
    } catch (error) {
      alert('Payment failed. Please try again.');
    } finally {
      setPaymentProcessing(false);
    }
  };

  const getStepContent = (step: number) => {
    switch (step) {
      case 0:
        return (
          <Grid container spacing={2}>
            {plans.map((plan) => (
              <Grid item xs={12} sm={4} key={plan.id}>
                <Paper 
                  sx={{ 
                    p: 2, 
                    textAlign: 'center', 
                    cursor: 'pointer',
                    border: amount === plan.price ? '2px solid #1976d2' : '1px solid #ccc',
                    '&:hover': { backgroundColor: '#f5f5f5' }
                  }}
                  onClick={() => setAmount(plan.price)}
                >
                  <Typography variant="h6">{plan.name}</Typography>
                  <Typography variant="h4">{plan.price} ₽</Typography>
                  <Typography>{plan.certificates} certificates</Typography>
                </Paper>
              </Grid>
            ))}
          </Grid>
        );
      case 1:
        return (
          <Box>
            <TextField
              label="Coupon Code"
              value={couponCode}
              onChange={(e) => setCouponCode(e.target.value)}
              fullWidth
              margin="normal"
            />
            <Button 
              variant="outlined" 
              onClick={handleApplyCoupon}
              disabled={!couponCode}
              sx={{ mt: 1 }}
            >
              Apply Coupon
            </Button>
            {discount > 0 && (
              <Typography sx={{ mt: 2, color: 'green' }}>
                Discount applied: {discount}%
              </Typography>
            )}
          </Box>
        );
      case 2:
        return (
          <FormControl fullWidth margin="normal">
            <InputLabel>Payment Method</InputLabel>
            <Select
              value={paymentMethod}
              label="Payment Method"
              onChange={(e) => setPaymentMethod(e.target.value)}
            >
              <MenuItem value="bank_card">Bank Card</MenuItem>
              <MenuItem value="sberbank">Sberbank Online</MenuItem>
              <MenuItem value="yoo_money">YooMoney</MenuItem>
              <MenuItem value="qiwi">Qiwi Wallet</MenuItem>
              <MenuItem value="sbc">Система Быстрых Платежей</MenuItem>
            </Select>
          </FormControl>
        );
      case 3:
        return (
          <Box>
            <Typography variant="h6">Order Summary</Typography>
            <Typography>Total Amount: {amount - (amount * discount / 100)} ₽</Typography>
            <Typography>Discount: {discount}%</Typography>
            <Button 
              variant="contained" 
              size="large" 
              onClick={handlePayment}
              disabled={paymentProcessing || !paymentMethod}
              sx={{ mt: 2 }}
            >
              {paymentProcessing ? 'Processing...' : 'Complete Payment'}
            </Button>
          </Box>
        );
      default:
        return 'Unknown step';
    }
  };

  const handleNext = () => {
    setActiveStep((prevActiveStep) => prevActiveStep + 1);
  };

  const handleBack = () => {
    setActiveStep((prevActiveStep) => prevActiveStep - 1);
  };

  return (
    <>
      <Header />
      <Container maxWidth="lg" sx={{ mt: 4, mb: 4 }}>
        <Typography variant="h4" gutterBottom>
          Payment
        </Typography>
        
        <Stepper activeStep={activeStep} alternativeLabel>
          {steps.map((label) => (
            <Step key={label}>
              <StepLabel>{label}</StepLabel>
            </Step>
          ))}
        </Stepper>
        
        <Box sx={{ mt: 3 }}>
          {getStepContent(activeStep)}
        </Box>
        
        <Box sx={{ display: 'flex', justifyContent: 'space-between', mt: 3 }}>
          <Button 
            disabled={activeStep === 0} 
            onClick={handleBack}
          >
            Back
          </Button>
          <Button
            variant="contained"
            disabled={activeStep === steps.length - 1 && (!paymentMethod || paymentProcessing)}
            onClick={activeStep === steps.length - 1 ? handlePayment : handleNext}
          >
            {activeStep === steps.length - 1 ? 'Pay Now' : 'Next'}
          </Button>
        </Box>
      </Container>
      <Footer />
    </>
  );
};

export default Payment;