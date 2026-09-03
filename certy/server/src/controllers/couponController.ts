import { Request, Response } from 'express';
import { pool } from '../config/db';

export const getCoupons = async (req: Request, res: Response): Promise<void> => {
  try {
    const userId = (req as any).user?.userId; // From auth middleware

    if (!userId) {
      res.status(401).json({ message: 'User not authenticated' });
      return;
    }

    // Check if user is admin to see all coupons
    const userResult = await pool.query('SELECT role FROM users WHERE id = $1', [userId]);
    const userRole = userResult.rows[0]?.role;

    let query;
    let queryParams;

    if (userRole === 'admin') {
      // Admin can see all coupons
      query = 'SELECT * FROM coupons ORDER BY created_at DESC';
      queryParams = [];
    } else {
      // Regular user sees message that they don't have permissions
      res.status(403).json({ message: 'Only admins can view all coupons' });
      return;
    }

    const result = await pool.query(query, queryParams);
    res.json(result.rows);
  } catch (error) {
    console.error('Get coupons error:', error);
    res.status(500).json({ message: 'Server error while fetching coupons' });
  }
};

export const createCoupon = async (req: Request, res: Response): Promise<void> => {
  try {
    const userId = (req as any).user?.userId; // From auth middleware
    const { code, discountPercent, discountFixed, validFrom, validTo, maxUses } = req.body;

    if (!userId) {
      res.status(401).json({ message: 'User not authenticated' });
      return;
    }

    // Check if user is admin
    const userResult = await pool.query('SELECT role FROM users WHERE id = $1', [userId]);
    const userRole = userResult.rows[0]?.role;

    if (userRole !== 'admin') {
      res.status(403).json({ message: 'Only admins can create coupons' });
      return;
    }

    if (!code) {
      res.status(400).json({ message: 'Coupon code is required' });
      return;
    }

    if ((discountPercent === undefined || discountPercent === null) &&
        (discountFixed === undefined || discountFixed === null)) {
      res.status(400).json({ message: 'Either discount percent or discount fixed amount is required' });
      return;
    }

    if (discountPercent !== undefined && discountPercent !== null && (discountPercent <= 0 || discountPercent > 100)) {
      res.status(400).json({ message: 'Discount percent must be between 1 and 100' });
      return;
    }

    if (discountFixed !== undefined && discountFixed !== null && discountFixed <= 0) {
      res.status(400).json({ message: 'Discount fixed amount must be greater than 0' });
      return;
    }

    // Check if coupon code already exists
    const existingResult = await pool.query('SELECT id FROM coupons WHERE code = $1', [code]);
    if (existingResult.rows.length > 0) {
      res.status(409).json({ message: 'A coupon with this code already exists' });
      return;
    }

    // Create coupon
    const result = await pool.query(
      `INSERT INTO coupons (code, discount_percent, discount_fixed, valid_from, valid_to, max_uses, is_active)
       VALUES ($1, $2, $3, $4, $5, $6, $7)
       RETURNING *`,
      [code, discountPercent || null, discountFixed || null, validFrom || null, validTo || null, maxUses || null, true]
    );

    res.status(201).json(result.rows[0]);
  } catch (error) {
    console.error('Create coupon error:', error);
    res.status(500).json({ message: 'Server error while creating coupon' });
  }
};

export const updateCoupon = async (req: Request, res: Response): Promise<void> => {
  try {
    const { id } = req.params;
    const userId = (req as any).user?.userId; // From auth middleware
    const { discountPercent, discountFixed, validFrom, validTo, maxUses, isActive } = req.body;

    if (!userId) {
      res.status(401).json({ message: 'User not authenticated' });
      return;
    }

    // Check if user is admin
    const userResult = await pool.query('SELECT role FROM users WHERE id = $1', [userId]);
    const userRole = userResult.rows[0]?.role;

    if (userRole !== 'admin') {
      res.status(403).json({ message: 'Only admins can update coupons' });
      return;
    }

    // Update coupon
    const result = await pool.query(
      `UPDATE coupons
       SET discount_percent = COALESCE($1, discount_percent),
           discount_fixed = COALESCE($2, discount_fixed),
           valid_from = COALESCE($3, valid_from),
           valid_to = COALESCE($4, valid_to),
           max_uses = COALESCE($5, max_uses),
           is_active = COALESCE($6, is_active),
           updated_at = NOW()
       WHERE id = $7
       RETURNING *`,
      [discountPercent, discountFixed, validFrom, validTo, maxUses, isActive, id]
    );

    if (result.rows.length === 0) {
      res.status(404).json({ message: 'Coupon not found' });
      return;
    }

    res.json(result.rows[0]);
  } catch (error) {
    console.error('Update coupon error:', error);
    res.status(500).json({ message: 'Server error while updating coupon' });
  }
};

export const deleteCoupon = async (req: Request, res: Response): Promise<void> => {
  try {
    const { id } = req.params;
    const userId = (req as any).user?.userId; // From auth middleware

    if (!userId) {
      res.status(401).json({ message: 'User not authenticated' });
      return;
    }

    // Check if user is admin
    const userResult = await pool.query('SELECT role FROM users WHERE id = $1', [userId]);
    const userRole = userResult.rows[0]?.role;

    if (userRole !== 'admin') {
      res.status(403).json({ message: 'Only admins can delete coupons' });
      return;
    }

    await pool.query('DELETE FROM user_coupons WHERE coupon_id = $1', [id]);
    const result = await pool.query('DELETE FROM coupons WHERE id = $1 RETURNING id', [id]);

    if (result.rows.length === 0) {
      res.status(404).json({ message: 'Coupon not found' });
      return;
    }

    res.json({ message: 'Coupon deleted successfully' });
  } catch (error) {
    console.error('Delete coupon error:', error);
    res.status(500).json({ message: 'Server error while deleting coupon' });
  }
};

export const validateCoupon = async (req: Request, res: Response): Promise<void> => {
  try {
    const { code } = req.body;

    if (!code) {
      res.status(400).json({ message: 'Coupon code is required' });
      return;
    }

    // Check if coupon exists and is active
    const result = await pool.query(
      `SELECT id, code, discount_percent, discount_fixed, is_active,
              valid_from, valid_to, max_uses, used_count
       FROM coupons
       WHERE code = $1 AND is_active = true
       AND (valid_from IS NULL OR valid_from <= NOW())
       AND (valid_to IS NULL OR valid_to >= NOW())
       AND (max_uses IS NULL OR used_count < max_uses)`,
      [code]
    );

    if (result.rows.length === 0) {
      res.status(404).json({ message: 'Invalid or inactive coupon code' });
      return;
    }

    res.json({
      valid: true,
      coupon: result.rows[0]
    });
  } catch (error) {
    console.error('Validate coupon error:', error);
    res.status(500).json({ message: 'Server error while validating coupon' });
  }
};