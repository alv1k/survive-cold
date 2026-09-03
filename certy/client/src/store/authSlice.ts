import { create } from 'zustand';

interface AuthState {
  user: any;
  token: string | null;
  isAuthenticated: boolean;
  login: (userData: any, token: string) => void;
  logout: () => void;
}

export const useAuthStore = create<AuthState>((set) => ({
  user: null,
  token: null,
  isAuthenticated: false,
  login: (userData, token) => set({ user: userData, token, isAuthenticated: true }),
  logout: () => set({ user: null, token: null, isAuthenticated: false }),
}));