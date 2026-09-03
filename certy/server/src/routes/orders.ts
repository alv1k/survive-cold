import { Router } from 'express';
import { 
  getOrders, 
  getOrder, 
  createOrder, 
  updateOrder, 
  deleteOrder 
} from '../controllers/orderController';
import { authenticateToken } from '../middleware/authMiddleware';

const router = Router();

router.get('/', authenticateToken, getOrders);
router.get('/:id', authenticateToken, getOrder);
router.post('/', authenticateToken, createOrder);
router.put('/:id', authenticateToken, updateOrder);
router.delete('/:id', authenticateToken, deleteOrder);

export default router;