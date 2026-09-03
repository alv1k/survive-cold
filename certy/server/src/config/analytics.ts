import dotenv from 'dotenv';

dotenv.config();

export const analyticsConfig = {
  googleAnalyticsId: process.env.GA_MEASUREMENT_ID || '',
  enableAnalytics: process.env.ENABLE_ANALYTICS === 'true',
};

if (analyticsConfig.enableAnalytics && !analyticsConfig.googleAnalyticsId) {
  console.warn('Analytics is enabled but Google Analytics ID is not set. Please set GA_MEASUREMENT_ID in your environment variables.');
}