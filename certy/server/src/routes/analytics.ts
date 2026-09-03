import { Router } from 'express';
import { 
  getAnalytics,
  getRevenueReport,
  getCouponAnalytics,
  trackEvent
} from '../controllers/analyticsController';
import { authenticateToken, authorizeAdmin } from '../middleware/authMiddleware';

const router = Router();

// Analytics dashboard (admin only)
router.get('/', authenticateToken, authorizeAdmin, getAnalytics);

// Revenue reports (admin only)
router.get('/revenue', authenticateToken, authorizeAdmin, getRevenueReport);

// Coupon analytics (admin only)
router.get('/coupons', authenticateToken, authorizeAdmin, getCouponAnalytics);

// Track events (available to authenticated users)
router.post('/track', authenticateToken, trackEvent);

export default router;