import { Router } from 'express';
import { 
  getUsers,
  getUser,
  updateUser,
  deleteUser,
  getAdminStats
} from '../controllers/adminController';
import { authenticateToken, authorizeAdmin } from '../middleware/authMiddleware';

const router = Router();

// User management routes
router.get('/users', authenticateToken, authorizeAdmin, getUsers);
router.get('/users/:id', authenticateToken, authorizeAdmin, getUser);
router.put('/users/:id', authenticateToken, authorizeAdmin, updateUser);
router.delete('/users/:id', authenticateToken, authorizeAdmin, deleteUser);

// Admin stats
router.get('/stats', authenticateToken, authorizeAdmin, getAdminStats);

export default router;