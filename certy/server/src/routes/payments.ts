import { Router } from 'express';
import { 
  createPayment, 
  getPaymentStatus, 
  refundPayment,
  applyCoupon
} from '../controllers/paymentController';
import { authenticateToken } from '../middleware/authMiddleware';

const router = Router();

router.post('/create', authenticateToken, createPayment);
router.get('/status/:paymentId', authenticateToken, getPaymentStatus);
router.post('/refund/:paymentId', authenticateToken, refundPayment);
router.post('/coupon/apply', authenticateToken, applyCoupon);

export default router;