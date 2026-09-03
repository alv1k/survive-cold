export interface User {
  id: string;
  email: string;
  name: string;
  role: 'admin' | 'user';
  password: string;
  created_at: Date;
  updated_at: Date;
}

export interface Subscription {
  id: string;
  user_id: string;
  plan_id: string;
  plan_name: string;
  start_date: Date;
  end_date: Date;
  is_active: boolean;
  max_certificates: number;
  created_at: Date;
  updated_at: Date;
  canceled_at?: Date;
}

export interface Order {
  id: string;
  user_id: string;
  amount: number;
  currency: string;
  status: 'pending' | 'paid' | 'cancelled' | 'refunded';
  created_at: Date;
  updated_at: Date;
}

export interface OrderItem {
  id: string;
  order_id: string;
  type: 'certificate' | 'subscription';
  name: string;
  quantity: number;
  unit_price: number;
  total_price: number;
}

export interface Payment {
  id: string;
  yookassa_id: string;
  user_id: string;
  amount: number;
  currency: string;
  status: string;
  order_id?: string;
  coupon_code?: string;
  created_at: Date;
}

export interface Coupon {
  id: string;
  code: string;
  discount_percent?: number;
  discount_fixed?: number;
  is_active: boolean;
  valid_from?: Date;
  valid_to?: Date;
  max_uses?: number;
  used_count: number;
  created_at: Date;
  updated_at: Date;
}

export interface SubscriptionPlan {
  id: string;
  name: string;
  price: number;
  duration_days: number;
  max_certificates: number;
  features: string[];
  is_active: boolean;
  created_at: Date;
  updated_at: Date;
}

export interface Certificate {
  id: string;
  user_id: string;
  template_id: string;
  template_name: string;
  participant_name: string;
  event_title: string;
  issue_date: Date;
  status: 'generated' | 'printed' | 'pending';
  file_path?: string;
  created_at: Date;
}

export interface AnalyticsEvent {
  id: string;
  user_id?: string;
  event: string;
  properties: Record<string, any>;
  ip_address: string;
  user_agent: string;
  created_at: Date;
}