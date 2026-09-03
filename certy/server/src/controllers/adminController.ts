import { Request, Response } from 'express';
import { pool } from '../config/db';

export const getUsers = async (req: Request, res: Response): Promise<void> => {
  try {
    const { page = 1, limit = 10, search } = req.query;

    // Check if user is admin
    const userId = (req as any).user?.userId;
    const userResult = await pool.query('SELECT role FROM users WHERE id = $1', [userId]);
    const userRole = userResult.rows[0]?.role;

    if (userRole !== 'admin') {
      res.status(403).json({ message: 'Admin access required' });
      return;
    }

    // Build query with optional search
    let query = 'SELECT id, email, name, role, created_at FROM users';
    let countQuery = 'SELECT COUNT(*) FROM users';
    const params: any[] = [];

    if (search) {
      query += ' WHERE email ILIKE $1 OR name ILIKE $1';
      countQuery += ' WHERE email ILIKE $1 OR name ILIKE $1';
      params.push(`%${search}%`);
    }

    query += ' ORDER BY created_at DESC LIMIT $' + (params.length + 1) + ' OFFSET $' + (params.length + 2);
    params.push(parseInt(limit as string), (parseInt(page as string) - 1) * parseInt(limit as string));

    const [usersResult, countResult] = await Promise.all([
      pool.query(query, params),
      pool.query(countQuery, search ? [params[0]] : [])
    ]);

    const total = parseInt(countResult.rows[0].count);
    const users = usersResult.rows;

    res.json({
      users,
      pagination: {
        page: parseInt(page as string),
        limit: parseInt(limit as string),
        total,
        pages: Math.ceil(total / parseInt(limit as string))
      }
    });
  } catch (error) {
    console.error('Get users error:', error);
    res.status(500).json({ message: 'Server error while fetching users' });
  }
};

export const getUser = async (req: Request, res: Response): Promise<void> => {
  try {
    const { id } = req.params;

    // Check if user is admin
    const userId = (req as any).user?.userId;
    const userResult = await pool.query('SELECT role FROM users WHERE id = $1', [userId]);
    const userRole = userResult.rows[0]?.role;

    if (userRole !== 'admin') {
      res.status(403).json({ message: 'Admin access required' });
      return;
    }

    const result = await pool.query(
      'SELECT id, email, name, role, created_at FROM users WHERE id = $1',
      [id]
    );

    if (result.rows.length === 0) {
      res.status(404).json({ message: 'User not found' });
      return;
    }

    res.json(result.rows[0]);
  } catch (error) {
    console.error('Get user error:', error);
    res.status(500).json({ message: 'Server error while fetching user' });
  }
};

export const updateUser = async (req: Request, res: Response): Promise<void> => {
  try {
    const { id } = req.params;
    const { email, name, role } = req.body;

    // Check if user is admin
    const userId = (req as any).user?.userId;
    const userResult = await pool.query('SELECT role FROM users WHERE id = $1', [userId]);
    const userRole = userResult.rows[0]?.role;

    if (userRole !== 'admin') {
      res.status(403).json({ message: 'Admin access required' });
      return;
    }

    if (role && !['user', 'admin'].includes(role)) {
      res.status(400).json({ message: 'Invalid role' });
      return;
    }

    const result = await pool.query(
      `UPDATE users
       SET email = COALESCE($1, email),
           name = COALESCE($2, name),
           role = COALESCE($3, role),
           updated_at = NOW()
       WHERE id = $4
       RETURNING *`,
      [email, name, role, id]
    );

    if (result.rows.length === 0) {
      res.status(404).json({ message: 'User not found' });
      return;
    }

    res.json(result.rows[0]);
  } catch (error) {
    console.error('Update user error:', error);
    res.status(500).json({ message: 'Server error while updating user' });
  }
};

export const deleteUser = async (req: Request, res: Response): Promise<void> => {
  try {
    const { id } = req.params;

    // Check if user is admin
    const userId = (req as any).user?.userId;
    const userResult = await pool.query('SELECT role FROM users WHERE id = $1', [userId]);
    const userRole = userResult.rows[0]?.role;

    if (userRole !== 'admin') {
      res.status(403).json({ message: 'Admin access required' });
      return;
    }

    // Delete user (cascading will handle related records if configured)
    const result = await pool.query('DELETE FROM users WHERE id = $1 RETURNING id', [id]);

    if (result.rows.length === 0) {
      res.status(404).json({ message: 'User not found' });
      return;
    }

    res.json({ message: 'User deleted successfully' });
  } catch (error) {
    console.error('Delete user error:', error);
    res.status(500).json({ message: 'Server error while deleting user' });
  }
};

export const getAdminStats = async (req: Request, res: Response): Promise<void> => {
  try {
    // Check if user is admin
    const userId = (req as any).user?.userId;
    const userResult = await pool.query('SELECT role FROM users WHERE id = $1', [userId]);
    const userRole = userResult.rows[0]?.role;

    if (userRole !== 'admin') {
      res.status(403).json({ message: 'Admin access required' });
      return;
    }

    // Get various statistics
    const [
      totalUsersResult,
      totalOrdersResult,
      totalRevenueResult,
      activeSubscriptionsResult,
      newUsersThisMonthResult,
      newOrdersThisMonthResult
    ] = await Promise.all([
      pool.query('SELECT COUNT(*) as count FROM users'),
      pool.query('SELECT COUNT(*) as count FROM orders'),
      pool.query('SELECT COALESCE(SUM(amount), 0) as total FROM orders WHERE status = \'paid\''),
      pool.query('SELECT COUNT(*) as count FROM subscriptions WHERE is_active = true AND end_date >= NOW()'),
      pool.query('SELECT COUNT(*) as count FROM users WHERE created_at >= date_trunc(\'month\', CURRENT_DATE)'),
      pool.query('SELECT COUNT(*) as count FROM orders WHERE created_at >= date_trunc(\'month\', CURRENT_DATE)')
    ]);

    res.json({
      totalUsers: parseInt(totalUsersResult.rows[0].count),
      totalOrders: parseInt(totalOrdersResult.rows[0].count),
      totalRevenue: parseFloat(totalRevenueResult.rows[0].total),
      activeSubscriptions: parseInt(activeSubscriptionsResult.rows[0].count),
      newUsersThisMonth: parseInt(newUsersThisMonthResult.rows[0].count),
      newOrdersThisMonth: parseInt(newOrdersThisMonthResult.rows[0].count)
    });
  } catch (error) {
    console.error('Get admin stats error:', error);
    res.status(500).json({ message: 'Server error while fetching admin stats' });
  }
};