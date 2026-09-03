import { Request, Response } from 'express';
import { pool } from '../config/db';

export const getAnalytics = async (req: Request, res: Response): Promise<void> => {
  try {
    // Check if user is admin
    const userId = (req as any).user?.userId;
    const userResult = await pool.query('SELECT role FROM users WHERE id = $1', [userId]);
    const userRole = userResult.rows[0]?.role;

    if (userRole !== 'admin') {
      res.status(403).json({ message: 'Admin access required' });
      return;
    }

    // Get various analytics data
    const [
      revenueData,
      userGrowthData,
      orderStatusData,
      popularPlansData,
      monthlyRevenueData
    ] = await Promise.all([
      // Revenue data
      pool.query(`
        SELECT
          DATE_TRUNC('day', created_at) as date,
          SUM(amount) as total_revenue
        FROM orders
        WHERE status = 'paid'
        AND created_at >= NOW() - INTERVAL '30 days'
        GROUP BY DATE_TRUNC('day', created_at)
        ORDER BY date
      `),
      // User growth data
      pool.query(`
        SELECT
          DATE_TRUNC('day', created_at) as date,
          COUNT(*) as new_users
        FROM users
        WHERE created_at >= NOW() - INTERVAL '30 days'
        GROUP BY DATE_TRUNC('day', created_at)
        ORDER BY date
      `),
      // Order status data
      pool.query(`
        SELECT
          status,
          COUNT(*) as count
        FROM orders
        GROUP BY status
      `),
      // Popular subscription plans
      pool.query(`
        SELECT
          sp.name as plan_name,
          COUNT(s.id) as subscription_count
        FROM subscriptions s
        JOIN subscription_plans sp ON s.plan_id = sp.id
        WHERE s.start_date >= NOW() - INTERVAL '30 days'
        GROUP BY sp.name
        ORDER BY subscription_count DESC
      `),
      // Monthly revenue
      pool.query(`
        SELECT
          DATE_TRUNC('month', created_at) as month,
          SUM(amount) as total_revenue
        FROM orders
        WHERE status = 'paid'
        AND created_at >= NOW() - INTERVAL '12 months'
        GROUP BY DATE_TRUNC('month', created_at)
        ORDER BY month
      `)
    ]);

    res.json({
      revenueData: revenueData.rows,
      userGrowthData: userGrowthData.rows,
      orderStatusData: orderStatusData.rows,
      popularPlansData: popularPlansData.rows,
      monthlyRevenueData: monthlyRevenueData.rows
    });
  } catch (error) {
    console.error('Get analytics error:', error);
    res.status(500).json({ message: 'Server error while fetching analytics' });
  }
};

export const getRevenueReport = async (req: Request, res: Response): Promise<void> => {
  try {
    // Check if user is admin
    const userId = (req as any).user?.userId;
    const userResult = await pool.query('SELECT role FROM users WHERE id = $1', [userId]);
    const userRole = userResult.rows[0]?.role;

    if (userRole !== 'admin') {
      res.status(403).json({ message: 'Admin access required' });
      return;
    }

    const { period = 'month' } = req.query;

    let dateTrunc: string;
    switch (period) {
      case 'day':
        dateTrunc = 'day';
        break;
      case 'week':
        dateTrunc = 'week';
        break;
      case 'month':
        dateTrunc = 'month';
        break;
      case 'year':
        dateTrunc = 'year';
        break;
      default:
        res.status(400).json({ message: 'Invalid period. Use day, week, month, or year.' });
        return;
    }

    const result = await pool.query(`
      SELECT
        DATE_TRUNC($1, created_at) as period,
        COUNT(*) as total_orders,
        SUM(amount) as total_revenue,
        AVG(amount) as average_order_value
      FROM orders
      WHERE status = 'paid'
      GROUP BY DATE_TRUNC($1, created_at)
      ORDER BY period DESC
    `, [dateTrunc]);

    res.json(result.rows);
  } catch (error) {
    console.error('Get revenue report error:', error);
    res.status(500).json({ message: 'Server error while fetching revenue report' });
  }
};

export const getCouponAnalytics = async (req: Request, res: Response): Promise<void> => {
  try {
    // Check if user is admin
    const userId = (req as any).user?.userId;
    const userResult = await pool.query('SELECT role FROM users WHERE id = $1', [userId]);
    const userRole = userResult.rows[0]?.role;

    if (userRole !== 'admin') {
      res.status(403).json({ message: 'Admin access required' });
      return;
    }

    // Get coupon usage analytics
    const result = await pool.query(`
      SELECT
        c.code,
        c.discount_percent,
        c.discount_fixed,
        c.used_count,
        c.max_uses,
        COUNT(uc.id) as usage_count,
        SUM(o.amount) as total_discounted_amount
      FROM coupons c
      LEFT JOIN user_coupons uc ON c.id = uc.coupon_id
      LEFT JOIN orders o ON uc.order_id = o.id
      GROUP BY c.id, c.code, c.discount_percent, c.discount_fixed, c.used_count, c.max_uses
      ORDER BY usage_count DESC
    `);

    res.json(result.rows);
  } catch (error) {
    console.error('Get coupon analytics error:', error);
    res.status(500).json({ message: 'Server error while fetching coupon analytics' });
  }
};

export const trackEvent = async (req: Request, res: Response): Promise<void> => {
  try {
    const { event, properties } = req.body;
    const userId = (req as any).user?.userId || null; // Optional for anonymous events

    if (!event) {
      res.status(400).json({ message: 'Event name is required' });
      return;
    }

    // Store event in analytics table
    await pool.query(`
      INSERT INTO analytics_events (user_id, event, properties, ip_address, user_agent)
      VALUES ($1, $2, $3, $4, $5)
    `, [
      userId,
      event,
      JSON.stringify(properties || {}),
      req.ip,
      req.get('User-Agent') || ''
    ]);

    res.json({ message: 'Event tracked successfully' });
  } catch (error) {
    console.error('Track event error:', error);
    res.status(500).json({ message: 'Server error while tracking event' });
  }
};