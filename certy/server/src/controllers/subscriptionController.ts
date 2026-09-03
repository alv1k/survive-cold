import { Request, Response } from 'express';
import { pool } from '../config/db';

export const getSubscriptions = async (req: Request, res: Response): Promise<void> => {
  try {
    const userId = (req as any).user?.userId; // From auth middleware

    if (!userId) {
      res.status(401).json({ message: 'User not authenticated' });
      return;
    }

    // Check if user is admin to see all subscriptions
    const userResult = await pool.query('SELECT role FROM users WHERE id = $1', [userId]);
    const userRole = userResult.rows[0]?.role;

    let query;
    let queryParams;

    if (userRole === 'admin') {
      // Admin can see all subscriptions
      query = `
        SELECT s.*, u.name as user_name, u.email as user_email
        FROM subscriptions s
        JOIN users u ON s.user_id = u.id
        ORDER BY s.created_at DESC
      `;
      queryParams = [];
    } else {
      // Regular user can see only their subscriptions
      query = 'SELECT * FROM subscriptions WHERE user_id = $1 ORDER BY created_at DESC';
      queryParams = [userId];
    }

    const result = await pool.query(query, queryParams);
    res.json(result.rows);
  } catch (error) {
    console.error('Get subscriptions error:', error);
    res.status(500).json({ message: 'Server error while fetching subscriptions' });
  }
};

export const getUserSubscription = async (req: Request, res: Response): Promise<void> => {
  try {
    const userId = (req as any).user?.userId; // From auth middleware

    if (!userId) {
      res.status(401).json({ message: 'User not authenticated' });
      return;
    }

    // Get the active subscription for the user
    const result = await pool.query(
      `SELECT s.*, sp.name as plan_name, sp.max_certificates
       FROM subscriptions s
       JOIN subscription_plans sp ON s.plan_id = sp.id
       WHERE s.user_id = $1 AND s.is_active = true
       AND (s.end_date IS NULL OR s.end_date >= NOW())
       ORDER BY s.created_at DESC LIMIT 1`,
      [userId]
    );

    if (result.rows.length === 0) {
      res.status(404).json({ message: 'No active subscription found' });
      return;
    }

    res.json(result.rows[0]);
  } catch (error) {
    console.error('Get user subscription error:', error);
    res.status(500).json({ message: 'Server error while fetching user subscription' });
  }
};

export const createSubscription = async (req: Request, res: Response): Promise<void> => {
  try {
    const userId = (req as any).user?.userId; // From auth middleware
    const { planId, paymentId } = req.body;

    if (!userId || !planId) {
      res.status(400).json({ message: 'User ID and plan ID are required' });
      return;
    }

    // Get plan details
    const planResult = await pool.query(
      'SELECT id, name, price, duration_days, max_certificates FROM subscription_plans WHERE id = $1 AND is_active = true',
      [planId]
    );

    if (planResult.rows.length === 0) {
      res.status(404).json({ message: 'Invalid or inactive subscription plan' });
      return;
    }

    const plan = planResult.rows[0];
    const startDate = new Date();
    const endDate = new Date(startDate);
    endDate.setDate(endDate.getDate() + plan.duration_days);

    // Check if user already has an active subscription
    const existingResult = await pool.query(
      'SELECT id FROM subscriptions WHERE user_id = $1 AND is_active = true AND end_date >= NOW()',
      [userId]
    );

    if (existingResult.rows.length > 0) {
      res.status(409).json({ message: 'User already has an active subscription' });
      return;
    }

    // Create subscription
    const result = await pool.query(
      `INSERT INTO subscriptions (user_id, plan_id, plan_name, start_date, end_date, is_active, max_certificates)
       VALUES ($1, $2, $3, $4, $5, $6, $7)
       RETURNING *`,
      [userId, planId, plan.name, startDate, endDate, true, plan.max_certificates]
    );

    res.status(201).json(result.rows[0]);
  } catch (error) {
    console.error('Create subscription error:', error);
    res.status(500).json({ message: 'Server error while creating subscription' });
  }
};

export const cancelSubscription = async (req: Request, res: Response): Promise<void> => {
  try {
    const userId = (req as any).user?.userId; // From auth middleware

    if (!userId) {
      res.status(401).json({ message: 'User not authenticated' });
      return;
    }

    // Get the active subscription for the user
    const subscriptionResult = await pool.query(
      'SELECT id FROM subscriptions WHERE user_id = $1 AND is_active = true AND end_date >= NOW()',
      [userId]
    );

    if (subscriptionResult.rows.length === 0) {
      res.status(404).json({ message: 'No active subscription found' });
      return;
    }

    const subscriptionId = subscriptionResult.rows[0].id;

    // Update subscription to be inactive
    const result = await pool.query(
      `UPDATE subscriptions
       SET is_active = false, canceled_at = NOW()
       WHERE id = $1
       RETURNING *`,
      [subscriptionId]
    );

    res.json(result.rows[0]);
  } catch (error) {
    console.error('Cancel subscription error:', error);
    res.status(500).json({ message: 'Server error while canceling subscription' });
  }
};

export const getSubscriptionPlans = async (req: Request, res: Response): Promise<void> => {
  try {
    // Get all active subscription plans
    const result = await pool.query(
      'SELECT id, name, price, duration_days, max_certificates, features FROM subscription_plans WHERE is_active = true ORDER BY price ASC'
    );

    res.json(result.rows);
  } catch (error) {
    console.error('Get subscription plans error:', error);
    res.status(500).json({ message: 'Server error while fetching subscription plans' });
  }
};