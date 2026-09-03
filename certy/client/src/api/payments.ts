import api from './index';

export const paymentAPI = {
  createPayment: (paymentData: any) => 
    api.post('/payment/create', paymentData),
    
  getPaymentStatus: (paymentId: string) => 
    api.get(`/payment/status/${paymentId}`),
    
  refundPayment: (paymentId: string, amount?: number) => 
    api.post(`/payment/refund`, { paymentId, amount }),
    
  applyCoupon: (couponCode: string) => 
    api.post('/coupon/apply', { couponCode }),
};