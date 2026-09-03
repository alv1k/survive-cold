import { create } from 'zustand';

interface SubscriptionState {
  subscription: any;
  loading: boolean;
  error: string | null;
  fetchSubscription: () => Promise<void>;
  updateSubscription: (subscription: any) => void;
}

export const useSubscriptionStore = create<SubscriptionState>((set) => ({
  subscription: null,
  loading: false,
  error: null,
  fetchSubscription: async () => {
    set({ loading: true, error: null });
    try {
      // In a real app, this would fetch from API
      // const response = await subscriptionAPI.getSubscription();
      // set({ subscription: response.data, loading: false });
      
      // Mock implementation
      setTimeout(() => {
        set({ 
          subscription: {
            id: 'sub_123',
            planName: 'Basic Plan',
            startDate: new Date(),
            endDate: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000), // 30 days from now
            isActive: true,
            maxCertificates: 100
          }, 
          loading: false 
        });
      }, 500);
    } catch (error: any) {
      set({ error: error.message, loading: false });
    }
  },
  updateSubscription: (subscription) => set({ subscription })
}));