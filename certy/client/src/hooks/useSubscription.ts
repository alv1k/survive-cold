import { useState, useEffect } from 'react';

export const useSubscription = () => {
  const [subscription, setSubscription] = useState<any>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  // Mock function for now - would connect to API
  const fetchSubscription = async () => {
    try {
      setLoading(true);
      // In real implementation, this would call API to get subscription details
      // const response = await subscriptionAPI.getSubscription();
      // setSubscription(response.data);
      
      // For now, using mock data
      setSubscription({
        id: 'sub_123',
        planName: 'Basic Plan',
        startDate: new Date(),
        endDate: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000), // 30 days from now
        isActive: true,
        maxCertificates: 100
      });
    } catch (err: any) {
      setError(err.response?.data?.message || 'Failed to fetch subscription');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchSubscription();
  }, []);

  return { subscription, loading, error, refetch: fetchSubscription };
};