import { Request, Response } from 'express';
import { yookassaConfig } from '../config/yookassaConfig';
import axios, { AxiosInstance } from 'axios';
import { pool } from '../config/db';

// Initialize YooKassa client
let yookassaAxios: AxiosInstance | null = null;

if (yookassaConfig.shopId && yookassaConfig.secretKey) {
  yookassaAxios = axios.create({
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

export const createPayment = async (req: Request, res: Response): Promise<void> => {
  try {
    // Check if YooKassa is configured
    if (!yookassaAxios) {
      res.status(503).json({ message: 'Payment processing is temporarily unavailable' });
      return;
    }

    const { amount, currency, paymentMethodData, description, receipt, couponCode } = req.body;
    const userId = (req as any).user?.userId; // From auth middleware

    if (!userId) {
      res.status(401).json({ message: 'User not authenticated' });
      return;
    }

    // Apply coupon if provided
    let finalAmount = amount;
    if (couponCode) {
      const couponResult = await pool.query(
        'SELECT discount_percent, discount_fixed, is_active FROM coupons WHERE code = $1 AND is_active = true',
        [couponCode]
      );

      const coupon = couponResult.rows[0];
      if (!coupon) {
        res.status(400).json({ message: 'Invalid or inactive coupon code' });
        return;
      }

      if (coupon.discount_percent) {
        finalAmount = amount * (1 - coupon.discount_percent / 100);
      } else if (coupon.discount_fixed) {
        finalAmount = Math.max(0, amount - coupon.discount_fixed);
      }
    }

    // Create payment in YooKassa
    const paymentData = {
      amount: {
        value: finalAmount.toFixed(2),
        currency: currency || 'RUB',
      },
      confirmation: {
        type: 'redirect',
        return_url: `${process.env.CLIENT_URL || 'http://localhost:3000'}/payment-success`,
      },
      capture: true,
      description: description || `Payment for certificates by user ${userId}`,
      metadata: {
        user_id: userId,
        coupon_code: couponCode || '',
      },
      ...(receipt && { receipt }),
    };

    if (paymentMethodData) {
      (paymentData as any).payment_method_data = paymentMethodData;
    }

    const response = await yookassaAxios.post('/payments', paymentData);

    // Save payment record to our database
    await pool.query(
      `INSERT INTO payments (yookassa_id, user_id, amount, currency, status, order_id, coupon_code)
       VALUES ($1, $2, $3, $4, $5, $6, $7)`,
      [
        response.data.id,
        userId,
        finalAmount,
        currency || 'RUB',
        response.data.status,
        req.body.orderId || null,
        couponCode || null
      ]
    );

    res.json(response.data);
  } catch (error: any) {
    console.error('Create payment error:', error);
    res.status(500).json({
      message: 'Error creating payment',
      error: error.response?.data || error.message
    });
  }
};

export const getPaymentStatus = async (req: Request, res: Response): Promise<void> => {
  try {
    // Check if YooKassa is configured
    if (!yookassaAxios) {
      res.status(503).json({ message: 'Payment processing is temporarily unavailable' });
      return;
    }

    const { paymentId } = req.params;

    // First check our database
    const paymentResult = await pool.query(
      'SELECT * FROM payments WHERE yookassa_id = $1 OR id = $1',
      [paymentId]
    );

    if (paymentResult.rows.length === 0) {
      res.status(404).json({ message: 'Payment not found' });
      return;
    }

    const payment = paymentResult.rows[0];

    // If we have the status in our DB and it's final, return it
    if (['succeeded', 'canceled'].includes(payment.status)) {
      res.json({ id: payment.yookassa_id, status: payment.status });
      return;
    }

    // Otherwise, check YooKassa for updated status
    try {
      const response = await yookassaAxios.get(`/payments/${payment.yookassa_id}`);
      const status = response.data.status;

      // Update our database with the new status
      await pool.query(
        'UPDATE payments SET status = $1 WHERE yookassa_id = $2',
        [status, payment.yookassa_id]
      );

      res.json(response.data);
    } catch (yookassaError) {
      console.error('Error fetching payment status from YooKassa:', yookassaError);
      res.json({ id: payment.yookassa_id, status: payment.status });
    }
  } catch (error) {
    console.error('Get payment status error:', error);
    res.status(500).json({ message: 'Server error while fetching payment status' });
  }
};

export const refundPayment = async (req: Request, res: Response): Promise<void> => {
  try {
    // Check if YooKassa is configured
    if (!yookassaAxios) {
      res.status(503).json({ message: 'Payment processing is temporarily unavailable' });
      return;
    }

    const { paymentId } = req.params;
    const { amount } = req.body;
    const userId = (req as any).user?.userId; // From auth middleware

    if (!userId) {
      res.status(401).json({ message: 'User not authenticated' });
      return;
    }

    // Verify this user owns the payment or is admin
    const paymentResult = await pool.query(
      'SELECT p.*, u.role FROM payments p JOIN users u ON u.id = p.user_id WHERE p.yookassa_id = $1 OR p.id = $1',
      [paymentId]
    );

    if (paymentResult.rows.length === 0) {
      res.status(404).json({ message: 'Payment not found' });
      return;
    }

    const payment = paymentResult.rows[0];
    const userRole = paymentResult.rows[0].role;

    if (userRole !== 'admin' && payment.user_id !== userId) {
      res.status(403).json({ message: 'Not authorized to refund this payment' });
      return;
    }

    // Prepare refund data
    const refundData: any = {
      payment_id: payment.yookassa_id,
    };

    if (amount) {
      refundData.amount = {
        value: amount.toFixed(2),
        currency: payment.currency,
      };
    }

    // Create refund in YooKassa
    const response = await yookassaAxios.post('/refunds', refundData);

    // Save refund record to our database
    await pool.query(
      `INSERT INTO refunds (yookassa_refund_id, payment_id, user_id, amount, status)
       VALUES ($1, $2, $3, $4, $5)`,
      [
        response.data.id,
        payment.yookassa_id,
        userId,
        amount || payment.amount,
        response.data.status
      ]
    );

    res.json(response.data);
  } catch (error: any) {
    console.error('Refund payment error:', error);
    res.status(500).json({
      message: 'Error processing refund',
      error: error.response?.data || error.message
    });
  }
};

export const applyCoupon = async (req: Request, res: Response): Promise<void> => {
  try {
    const { couponCode } = req.body;
    const userId = (req as any).user?.userId; // From auth middleware

    if (!userId) {
      res.status(401).json({ message: 'User not authenticated' });
      return;
    }

    if (!couponCode) {
      res.status(400).json({ message: 'Coupon code is required' });
      return;
    }

    // Check if coupon exists and is active
    const couponResult = await pool.query(
      `SELECT id, code, discount_percent, discount_fixed, is_active,
              valid_from, valid_to, max_uses, used_count
       FROM coupons
       WHERE code = $1 AND is_active = true
       AND (valid_from IS NULL OR valid_from <= NOW())
       AND (valid_to IS NULL OR valid_to >= NOW())
       AND (max_uses IS NULL OR used_count < max_uses)`,
      [couponCode]
    );

    if (couponResult.rows.length === 0) {
      res.status(400).json({ message: 'Invalid or inactive coupon code' });
      return;
    }

    const coupon = couponResult.rows[0];

    // Check if user has already used this coupon (optional)
    const userCouponResult = await pool.query(
      'SELECT id FROM user_coupons WHERE user_id = $1 AND coupon_id = $2',
      [userId, coupon.id]
    );

    if (userCouponResult.rows.length > 0) {
      res.status(400).json({ message: 'Coupon already used by this user' });
      return;
    }

    // Coupon is valid
    res.json({
      message: 'Coupon applied successfully',
      coupon: {
        id: coupon.id,
        code: coupon.code,
        discount_percent: coupon.discount_percent,
        discount_fixed: coupon.discount_fixed,
      }
    });
  } catch (error) {
    console.error('Apply coupon error:', error);
    res.status(500).json({ message: 'Server error while applying coupon' });
  }
};