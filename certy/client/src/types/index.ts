export interface User {
  id: string;
  email: string;
  name: string;
  role: 'admin' | 'user';
  subscription?: Subscription;
}

export interface Subscription {
  id: string;
  userId: string;
  planId: string;
  planName: string;
  startDate: Date;
  endDate: Date;
  isActive: boolean;
  maxCertificates: number;
}

export interface Order {
  id: string;
  userId: string;
  amount: number;
  currency: string;
  status: 'pending' | 'paid' | 'cancelled' | 'refunded';
  items: OrderItem[];
  createdAt: Date;
  updatedAt: Date;
}

export interface OrderItem {
  id: string;
  orderId: string;
  type: 'certificate' | 'subscription';
  name: string;
  quantity: number;
  unitPrice: number;
  totalPrice: number;
}

export interface Certificate {
  id: string;
  userId: string;
  templateId: string;
  templateName: string;
  participantName: string;
  eventTitle: string;
  issueDate: Date;
  status: 'generated' | 'printed' | 'pending';
  filePath?: string;
}