import { Router } from 'express';
import { 
  getSubscriptions,
  getUserSubscription,
  createSubscription,
  cancelSubscription,
  getSubscriptionPlans
} from '../controllers/subscriptionController';
import { authenticateToken } from '../middleware/authMiddleware';

const router = Router();

router.get('/', authenticateToken, getSubscriptions);
router.get('/my', authenticateToken, getUserSubscription);
router.get('/plans', getSubscriptionPlans); // This one is public
router.post('/', authenticateToken, createSubscription);
router.delete('/cancel', authenticateToken, cancelSubscription);

export default router;