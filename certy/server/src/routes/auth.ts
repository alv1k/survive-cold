import { Router } from 'express';
import { register, login, getCurrentUser } from '../controllers/authController';
import { authRateLimit } from '../middleware/rateLimit';

const router = Router();

router.post('/register', authRateLimit, register);
router.post('/login', authRateLimit, login);
router.get('/me', getCurrentUser); // This route should be protected by auth middleware in the main server file

export default router;