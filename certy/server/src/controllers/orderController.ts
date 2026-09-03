import { Request, Response } from 'express';
import { pool } from '../config/db';

export const getOrders = async (req: Request, res: Response): Promise<void> => {
  try {
    const userId = (req as any).user?.userId; // From auth middleware

    if (!userId) {
      res.status(401).json({ message: 'User not authenticated' });
      return;
    }

    // Check if user is admin to see all orders
    const userResult = await pool.query('SELECT role FROM users WHERE id = $1', [userId]);
    const userRole = userResult.rows[0]?.role;

    let query;
    let queryParams;

    if (userRole === 'admin') {
      // Admin can see all orders
      query = `
        SELECT o.*, u.name as user_name, u.email as user_email
        FROM orders o
        JOIN users u ON o.user_id = u.id
        ORDER BY o.created_at DESC
      `;
      queryParams = [];
    } else {
      // Regular user can see only their orders
      query = 'SELECT * FROM orders WHERE user_id = $1 ORDER BY created_at DESC';
      queryParams = [userId];
    }

    const result = await pool.query(query, queryParams);
    res.json(result.rows);
  } catch (error) {
    console.error('Get orders error:', error);
    res.status(500).json({ message: 'Server error while fetching orders' });
  }
};

export const getOrder = async (req: Request, res: Response): Promise<void> => {
  try {
    const { id } = req.params;
    const userId = (req as any).user?.userId; // From auth middleware

    if (!userId) {
      res.status(401).json({ message: 'User not authenticated' });
      return;
    }

    // Check if user is admin or owner of the order
    const userResult = await pool.query('SELECT role FROM users WHERE id = $1', [userId]);
    const userRole = userResult.rows[0]?.role;

    let query;
    if (userRole === 'admin') {
      query = 'SELECT * FROM orders WHERE id = $1';
    } else {
      query = 'SELECT * FROM orders WHERE id = $1 AND user_id = $2';
    }

    const result = await pool.query(query, userRole === 'admin' ? [id] : [id, userId]);

    if (result.rows.length === 0) {
      res.status(404).json({ message: 'Order not found' });
      return;
    }

    res.json(result.rows[0]);
  } catch (error) {
    console.error('Get order error:', error);
    res.status(500).json({ message: 'Server error while fetching order' });
  }
};

export const createOrder = async (req: Request, res: Response): Promise<void> => {
  try {
    const userId = (req as any).user?.userId; // From auth middleware
    const { amount, currency, items, status } = req.body;

    if (!userId || !amount || !items || !Array.isArray(items) || items.length === 0) {
      res.status(400).json({ message: 'User ID, amount and items are required' });
      return;
    }

    // Default values
    const orderStatus = status || 'pending';
    const orderCurrency = currency || 'RUB';

    // Insert order
    const orderResult = await pool.query(
      `INSERT INTO orders (user_id, amount, currency, status)
       VALUES ($1, $2, $3, $4)
       RETURNING id, created_at`,
      [userId, amount, orderCurrency, orderStatus]
    );

    const orderId = orderResult.rows[0].id;
    const createdAt = orderResult.rows[0].created_at;

    // Insert order items
    for (const item of items) {
      await pool.query(
        `INSERT INTO order_items (order_id, type, name, quantity, unit_price, total_price)
         VALUES ($1, $2, $3, $4, $5, $6)`,
        [orderId, item.type, item.name, item.quantity, item.unitPrice, item.totalPrice]
      );
    }

    // Fetch the complete order with items
    const completeOrderResult = await pool.query(
      `SELECT o.*, json_agg(oi.*) as items
       FROM orders o
       LEFT JOIN order_items oi ON o.id = oi.order_id
       WHERE o.id = $1
       GROUP BY o.id`,
      [orderId]
    );

    res.status(201).json(completeOrderResult.rows[0]);
  } catch (error) {
    console.error('Create order error:', error);
    res.status(500).json({ message: 'Server error while creating order' });
  }
};

export const updateOrder = async (req: Request, res: Response): Promise<void> => {
  try {
    const { id } = req.params;
    const { amount, currency, status } = req.body;
    const userId = (req as any).user?.userId; // From auth middleware

    if (!userId) {
      res.status(401).json({ message: 'User not authenticated' });
      return;
    }

    // Check if user is admin or owner of the order
    const orderResult = await pool.query('SELECT user_id FROM orders WHERE id = $1', [id]);
    const order = orderResult.rows[0];

    if (!order) {
      res.status(404).json({ message: 'Order not found' });
      return;
    }

    const userResult = await pool.query('SELECT role FROM users WHERE id = $1', [userId]);
    const userRole = userResult.rows[0]?.role;

    if (userRole !== 'admin' && order.user_id !== userId) {
      res.status(403).json({ message: 'Not authorized to update this order' });
      return;
    }

    // Update order
    const result = await pool.query(
      `UPDATE orders
       SET amount = COALESCE($1, amount),
           currency = COALESCE($2, currency),
           status = COALESCE($3, status),
           updated_at = NOW()
       WHERE id = $4
       RETURNING *`,
      [amount, currency, status, id]
    );

    res.json(result.rows[0]);
  } catch (error) {
    console.error('Update order error:', error);
    res.status(500).json({ message: 'Server error while updating order' });
  }
};

export const deleteOrder = async (req: Request, res: Response): Promise<void> => {
  try {
    const { id } = req.params;
    const userId = (req as any).user?.userId; // From auth middleware

    if (!userId) {
      res.status(401).json({ message: 'User not authenticated' });
      return;
    }

    // Check if user is admin or owner of the order
    const orderResult = await pool.query('SELECT user_id FROM orders WHERE id = $1', [id]);
    const order = orderResult.rows[0];

    if (!order) {
      res.status(404).json({ message: 'Order not found' });
      return;
    }

    const userResult = await pool.query('SELECT role FROM users WHERE id = $1', [userId]);
    const userRole = userResult.rows[0]?.role;

    if (userRole !== 'admin' && order.user_id !== userId) {
      res.status(403).json({ message: 'Not authorized to delete this order' });
      return;
    }

    await pool.query('DELETE FROM order_items WHERE order_id = $1', [id]);
    await pool.query('DELETE FROM orders WHERE id = $1', [id]);

    res.json({ message: 'Order deleted successfully' });
  } catch (error) {
    console.error('Delete order error:', error);
    res.status(500).json({ message: 'Server error while deleting order' });
  }
};