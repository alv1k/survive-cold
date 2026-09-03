// General analytics utilities that combine different analytics providers

import { trackGAEvent, trackPageView, trackPurchase, trackSignUp, trackCertificateGeneration } from './ga';
import { trackEvent as trackSupabaseEvent } from './supabase';

// Combined track event that sends to multiple analytics providers
export const trackEvent = async (
  eventType: string, 
  properties: Record<string, any>, 
  userId?: string
) => {
  // Track in Google Analytics
  trackGAEvent(
    eventType,
    properties.category || 'engagement',
    properties.label || '',
    properties.value
  );
  
  // Track in Supabase
  await trackSupabaseEvent(eventType, properties, userId);
  
  // Log locally for debugging in development
  if (process.env.NODE_ENV === 'development') {
    console.log('Analytics event:', { eventType, properties, userId });
  }
};

// Combined page view tracking
export const trackPage = (pagePath: string, pageTitle?: string) => {
  trackPageView(pagePath, pageTitle);
};

// Combined purchase tracking
export const trackPurchaseEvent = (transactionId: string, value: number, currency: string = 'RUB', items: any[] = []) => {
  trackPurchase(transactionId, value, currency, items);
  
  // Also track in Supabase
  trackSupabaseEvent('purchase', { 
    transactionId, 
    value, 
    currency, 
    items 
  });
};

// Combined sign up tracking
export const trackSignUpEvent = (method: string, userId?: string) => {
  trackSignUp(method);
  
  // Also track in Supabase
  trackSupabaseEvent('sign_up', { method }, userId);
};

// Combined certificate generation tracking
export const trackCertificateEvent = (templateId: string, participantCount: number, userId?: string) => {
  trackCertificateGeneration(templateId, participantCount);
  
  // Also track in Supabase
  trackSupabaseEvent('generate_certificate', { 
    templateId, 
    participantCount 
  }, userId);
};

export default {
  trackEvent,
  trackPage,
  trackPurchaseEvent,
  trackSignUpEvent,
  trackCertificateEvent
};