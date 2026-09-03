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