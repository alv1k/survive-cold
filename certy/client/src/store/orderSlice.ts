import { create } from 'zustand';

interface OrderState {
  orders: any[];
  loading: boolean;
  error: string | null;
  fetchOrders: () => Promise<void>;
  addOrder: (order: any) => void;
  updateOrder: (id: string, order: any) => void;
}

export const useOrderStore = create<OrderState>((set, get) => ({
  orders: [],
  loading: false,
  error: null,
  fetchOrders: async () => {
    set({ loading: true, error: null });
    try {
      // In a real app, this would fetch from API
      // const response = await orderAPI.getOrders();
      // set({ orders: response.data, loading: false });
      
      // Mock implementation
      setTimeout(() => {
        set({ 
          orders: [
            { id: '1', amount: 100, status: 'paid', createdAt: new Date() },
            { id: '2', amount: 200, status: 'pending', createdAt: new Date() }
          ], 
          loading: false 
        });
      }, 500);
    } catch (error: any) {
      set({ error: error.message, loading: false });
    }
  },
  addOrder: (order) => set((state) => ({ orders: [...state.orders, order] })),
  updateOrder: (id, order) => set((state) => ({
    orders: state.orders.map((o) => (o.id === id ? order : o))
  }))
}));