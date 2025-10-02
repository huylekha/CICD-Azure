export interface Account {
  id: string;
  accountNumber: string;
  accountHolderName: string;
  balance: number;
  currency: string;
  isActive: boolean;
  createdAt: string;
  updatedAt: string;
}

export interface Transaction {
  id: string;
  fromAccountId: string;
  toAccountId: string;
  amount: number;
  currency: string;
  description?: string;
  status: TransactionStatus;
  type: TransactionType;
  createdAt: string;
  completedAt?: string;
  failedAt?: string;
  failureReason?: string;
  correlationId?: string;
}

export enum TransactionStatus {
  Pending = 'Pending',
  Processing = 'Processing',
  Completed = 'Completed',
  Failed = 'Failed',
  Cancelled = 'Cancelled',
  RolledBack = 'RolledBack'
}

export enum TransactionType {
  Transfer = 'Transfer',
  Deposit = 'Deposit',
  Withdrawal = 'Withdrawal',
  Refund = 'Refund'
}

export interface TransferRequest {
  fromAccountId: string;
  toAccountId: string;
  amount: number;
  currency: string;
  description?: string;
}

export interface TransferResponse {
  success: boolean;
  transactionId?: string;
  errorMessage?: string;
}

export interface DashboardStats {
  totalAccounts: number;
  totalTransactions: number;
  totalVolume: number;
  activeTransfers: number;
}

export interface ChartData {
  name: string;
  value: number;
  date?: string;
}

export interface ApiResponse<T> {
  data: T;
  success: boolean;
  message?: string;
}
