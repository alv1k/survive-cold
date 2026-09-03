import dotenv from 'dotenv';

dotenv.config();

export const yookassaConfig = {
  shopId: process.env.YOOKASSA_SHOP_ID || '',
  secretKey: process.env.YOOKASSA_SECRET_KEY || '',
  apiBaseUrl: process.env.YOOKASSA_API_BASE_URL || 'https://api.yookassa.ru/v3',
};

// Only show warning if the variables are missing, don't prevent the server from starting
if (!yookassaConfig.shopId || !yookassaConfig.secretKey) {
  console.warn('YooKassa configuration is missing. Payment functionality will be unavailable. Please set YOOKASSA_SHOP_ID and YOOKASSA_SECRET_KEY in your environment variables to enable payments.');
}