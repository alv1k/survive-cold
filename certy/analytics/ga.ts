// Analytics utilities for Google Analytics and other tracking services

// Track a custom event in Google Analytics
export const trackGAEvent = (action: string, category: string, label?: string, value?: number) => {
  if (typeof window !== 'undefined' && (window as any).gtag) {
    (window as any).gtag('event', action, {
      event_category: category,
      event_label: label,
      value: value
    });
  }
};

// Track a page view
export const trackPageView = (pagePath: string, pageTitle?: string) => {
  if (typeof window !== 'undefined' && (window as any).gtag) {
    (window as any).gtag('config', process.env.REACT_APP_GA_MEASUREMENT_ID, {
      page_path: pagePath,
      page_title: pageTitle
    });
  }
};

// Track purchase event
export const trackPurchase = (transactionId: string, value: number, currency: string = 'RUB', items: any[] = []) => {
  if (typeof window !== 'undefined' && (window as any).gtag) {
    (window as any).gtag('event', 'purchase', {
      transaction_id: transactionId,
      value: value,
      currency: currency,
      items: items
    });
  }
};

// Track sign up event
export const trackSignUp = (method: string) => {
  if (typeof window !== 'undefined' && (window as any).gtag) {
    (window as any).gtag('event', 'sign_up', {
      method: method
    });
  }
};

// Track certificate generation
export const trackCertificateGeneration = (templateId: string, participantCount: number) => {
  if (typeof window !== 'undefined' && (window as any).gtag) {
    (window as any).gtag('event', 'generate_certificate', {
      template_id: templateId,
      participant_count: participantCount
    });
  }
};

export default {
  trackGAEvent,
  trackPageView,
  trackPurchase,
  trackSignUp,
  trackCertificateGeneration
};