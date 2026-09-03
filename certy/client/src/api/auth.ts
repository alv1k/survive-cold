import api from './index';

export const authAPI = {
  login: (email: string, password: string) => 
    api.post('/auth/login', { email, password }),
    
  register: (email: string, password: string, name: string) => 
    api.post('/auth/register', { email, password, name }),
    
  logout: () => 
    api.post('/auth/logout'),
    
  getCurrentUser: () => 
    api.get('/auth/me'),
    
  refreshToken: () => 
    api.post('/auth/refresh'),
};