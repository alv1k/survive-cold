// Analytics utility functions for tracking events

// Track a custom event
export const trackEvent = (eventName: string, properties?: Record<string, any>) => {
  // In a real implementation, this could send data to Google Analytics, etc.
  console.log(`Tracking event: ${eventName}`, properties);
  
  // Example implementation with Google Analytics
  if (typeof window !== 'undefined' && (window as any).gtag) {
    (window as any).gtag('event', eventName, properties);
  }
};

// Track page view
export const trackPageView = (pagePath: string, pageTitle?: string) => {
  console.log(`Tracking page view: ${pagePath}`);
  
  if (typeof window !== 'undefined' && (window as any).gtag) {
    (window as any).gtag('config', process.env.REACT_APP_GA_MEASUREMENT_ID, {
      page_path: pagePath,
      page_title: pageTitle || pagePath
    });
  }
};

// Track purchase event
export const trackPurchase = (transactionId: string, value: number, currency: string = 'RUB') => {
  trackEvent('purchase', {
    transaction_id: transactionId,
    value: value,
    currency: currency
  });
};

// Track certificate generation
export const trackCertificateGeneration = (participantName: string, eventId: string) => {
  trackEvent('generate_certificate', {
    participant_name: participantName,
    event_id: eventId
  });
};