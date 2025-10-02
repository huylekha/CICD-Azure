import axios from 'axios';
import { Account, Transaction, TransferRequest, TransferResponse, DashboardStats } from '../types';

const API_BASE_URL = process.env.REACT_APP_API_URL || 'http://localhost:5001';

const api = axios.create({
  baseURL: API_BASE_URL,
  timeout: 10000,
  headers: {
    'Content-Type': 'application/json',
  },
});

// Request interceptor
api.interceptors.request.use(
  (config) => {
    // Add auth token if available
    const token = localStorage.getItem('authToken');
    if (token) {
      config.headers.Authorization = `Bearer ${token}`;
    }
    return config;
  },
  (error) => {
    return Promise.reject(error);
  }
);

// Response interceptor
api.interceptors.response.use(
  (response) => {
    return response;
  },
  (error) => {
    if (error.response?.status === 401) {
      // Handle unauthorized access
      localStorage.removeItem('authToken');
      window.location.href = '/login';
    }
    return Promise.reject(error);
  }
);

// Account API
export const accountApi = {
  getAccount: async (accountId: string): Promise<Account> => {
    const response = await api.get(`/api/account/${accountId}`);
    return response.data;
  },

  getAccounts: async (): Promise<Account[]> => {
    const response = await api.get('/api/account');
    return response.data;
  },

  createAccount: async (accountData: Partial<Account>): Promise<Account> => {
    const response = await api.post('/api/account', accountData);
    return response.data;
  },
};

// Transaction API
export const transactionApi = {
  getTransaction: async (transactionId: string): Promise<Transaction> => {
    const response = await api.get(`/api/transaction/${transactionId}`);
    return response.data;
  },

  getAccountTransactions: async (
    accountId: string,
    page: number = 1,
    pageSize: number = 20
  ): Promise<{ transactions: Transaction[]; totalCount: number; page: number; pageSize: number }> => {
    const response = await api.get(
      `/api/transaction/account/${accountId}?page=${page}&pageSize=${pageSize}`
    );
    return response.data;
  },

  getAllTransactions: async (
    page: number = 1,
    pageSize: number = 20
  ): Promise<{ transactions: Transaction[]; totalCount: number; page: number; pageSize: number }> => {
    const response = await api.get(`/api/transaction?page=${page}&pageSize=${pageSize}`);
    return response.data;
  },
};

// Transfer API
export const transferApi = {
  transferMoney: async (transferData: TransferRequest): Promise<TransferResponse> => {
    const response = await api.post('/api/payment/transfer', transferData);
    return response.data;
  },

  rollbackTransfer: async (transactionId: string, reason: string): Promise<{ success: boolean; errorMessage?: string }> => {
    const response = await api.post('/api/payment/rollback', {
      transactionId,
      reason,
    });
    return response.data;
  },
};

// Dashboard API
export const dashboardApi = {
  getStats: async (): Promise<DashboardStats> => {
    // Mock data for now - would be implemented in backend
    return {
      totalAccounts: 150,
      totalTransactions: 2847,
      totalVolume: 1250000,
      activeTransfers: 12,
    };
  },

  getRecentTransactions: async (limit: number = 10): Promise<Transaction[]> => {
    const response = await transactionApi.getAllTransactions(1, limit);
    return response.transactions;
  },

  getTransactionChartData: async (days: number = 30): Promise<Array<{ date: string; amount: number }>> => {
    // Mock data for chart
    const data = [];
    const today = new Date();
    for (let i = days - 1; i >= 0; i--) {
      const date = new Date(today);
      date.setDate(date.getDate() - i);
      data.push({
        date: date.toISOString().split('T')[0],
        amount: Math.floor(Math.random() * 10000) + 1000,
      });
    }
    return data;
  },
};

// Health check
export const healthApi = {
  checkHealth: async (): Promise<{ status: string; timestamp: string }> => {
    const response = await api.get('/health');
    return response.data;
  },
};

export default api;
