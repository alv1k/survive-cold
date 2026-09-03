import api from './index';

export const orderAPI = {
  getOrders: () => 
    api.get('/orders'),
    
  getOrder: (id: string) => 
    api.get(`/orders/${id}`),
    
  createOrder: (orderData: any) => 
    api.post('/orders', orderData),
    
  updateOrder: (id: string, orderData: any) => 
    api.put(`/orders/${id}`, orderData),
    
  deleteOrder: (id: string) => 
    api.delete(`/orders/${id}`),
};