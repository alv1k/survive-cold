import { Router } from 'express';
import { 
  getCoupons,
  createCoupon,
  updateCoupon,
  deleteCoupon,
  validateCoupon
} from '../controllers/couponController';
import { authenticateToken, authorizeAdmin } from '../middleware/authMiddleware';

const router = Router();

router.get('/', authenticateToken, getCoupons);
router.post('/create', authenticateToken, authorizeAdmin, createCoupon);
router.put('/:id', authenticateToken, authorizeAdmin, updateCoupon);
router.delete('/:id', authenticateToken, authorizeAdmin, deleteCoupon);
router.post('/validate', authenticateToken, validateCoupon);

export default router;