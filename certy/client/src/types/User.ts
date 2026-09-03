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