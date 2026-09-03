import axios, { AxiosInstance } from 'axios';
import { yookassaConfig } from '../config/yookassaConfig';

// This is a simple utility to create a YooKassa payment
// It's being replaced by the logic in the paymentController

export class YooKassaService {
  private axiosInstance: AxiosInstance;

  constructor() {
    this.axiosInstance = axios.create({
      baseURL: yookassaConfig.apiBaseUrl,
      headers: {
        'Content-Type': 'application/json',
        'Idempotence-Key': Math.random().toString(36).substring(2, 15),
      },
      auth: {
        username: yookassaConfig.shopId,
        password: yookassaConfig.secretKey,
      },
    });
  }

  async createPayment(paymentData: any) {
    try {
      const response = await this.axiosInstance.post('/payments', paymentData);
      return response.data;
    } catch (error) {
      console.error('YooKassa API error:', error);
      throw error;
    }
  }

  async getPaymentStatus(paymentId: string) {
    try {
      const response = await this.axiosInstance.get(`/payments/${paymentId}`);
      return response.data;
    } catch (error) {
      console.error('YooKassa API error:', error);
      throw error;
    }
  }

  async createRefund(refundData: any) {
    try {
      const response = await this.axiosInstance.post('/refunds', refundData);
      return response.data;
    } catch (error) {
      console.error('YooKassa API error:', error);
      throw error;
    }
  }
}