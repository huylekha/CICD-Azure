import React from 'react';
import {
  Box,
  Grid,
  Card,
  CardContent,
  Typography,
  Paper,
  LinearProgress,
} from '@mui/material';
import {
  AccountBalance as AccountBalanceIcon,
  Receipt as ReceiptIcon,
  TrendingUp as TrendingUpIcon,
  Send as SendIcon,
} from '@mui/icons-material';
import { useQuery } from 'react-query';
import {
  LineChart,
  Line,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  ResponsiveContainer,
  BarChart,
  Bar,
  PieChart,
  Pie,
  Cell,
} from 'recharts';
import { dashboardApi } from '../services/api';
import { Transaction } from '../types';
import TransactionTable from '../components/TransactionTable';

const StatCard: React.FC<{
  title: string;
  value: string | number;
  icon: React.ReactNode;
  color: string;
  loading?: boolean;
}> = ({ title, value, icon, color, loading = false }) => (
  <Card className="card-hover">
    <CardContent>
      <Box display="flex" alignItems="center" justifyContent="space-between">
        <Box>
          <Typography color="textSecondary" gutterBottom variant="h6">
            {title}
          </Typography>
          <Typography variant="h4" component="h2" sx={{ fontWeight: 'bold' }}>
            {loading ? <LinearProgress /> : value}
          </Typography>
        </Box>
        <Box
          sx={{
            backgroundColor: color,
            borderRadius: '50%',
            p: 1,
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
          }}
        >
          {icon}
        </Box>
      </Box>
    </CardContent>
  </Card>
);

const Dashboard: React.FC = () => {
  const { data: stats, isLoading: statsLoading } = useQuery(
    'dashboard-stats',
    dashboardApi.getStats,
    {
      refetchInterval: 30000, // Refetch every 30 seconds
    }
  );

  const { data: recentTransactions, isLoading: transactionsLoading } = useQuery(
    'recent-transactions',
    () => dashboardApi.getRecentTransactions(5),
    {
      refetchInterval: 10000, // Refetch every 10 seconds
    }
  );

  const { data: chartData, isLoading: chartLoading } = useQuery(
    'transaction-chart',
    () => dashboardApi.getTransactionChartData(7),
    {
      refetchInterval: 60000, // Refetch every minute
    }
  );

  const pieData = [
    { name: 'Completed', value: 85, color: '#4caf50' },
    { name: 'Processing', value: 10, color: '#ff9800' },
    { name: 'Failed', value: 5, color: '#f44336' },
  ];

  return (
    <Box className="fade-in">
      <Typography variant="h4" gutterBottom sx={{ fontWeight: 'bold', mb: 3 }}>
        Dashboard
      </Typography>

      {/* Stats Cards */}
      <Grid container spacing={3} sx={{ mb: 4 }}>
        <Grid item xs={12} sm={6} md={3}>
          <StatCard
            title="Total Accounts"
            value={stats?.totalAccounts || 0}
            icon={<AccountBalanceIcon sx={{ color: 'white' }} />}
            color="#1976d2"
            loading={statsLoading}
          />
        </Grid>
        <Grid item xs={12} sm={6} md={3}>
          <StatCard
            title="Total Transactions"
            value={stats?.totalTransactions || 0}
            icon={<ReceiptIcon sx={{ color: 'white' }} />}
            color="#388e3c"
            loading={statsLoading}
          />
        </Grid>
        <Grid item xs={12} sm={6} md={3}>
          <StatCard
            title="Total Volume"
            value={`$${(stats?.totalVolume || 0).toLocaleString()}`}
            icon={<TrendingUpIcon sx={{ color: 'white' }} />}
            color="#f57c00"
            loading={statsLoading}
          />
        </Grid>
        <Grid item xs={12} sm={6} md={3}>
          <StatCard
            title="Active Transfers"
            value={stats?.activeTransfers || 0}
            icon={<SendIcon sx={{ color: 'white' }} />}
            color="#d32f2f"
            loading={statsLoading}
          />
        </Grid>
      </Grid>

      {/* Charts */}
      <Grid container spacing={3} sx={{ mb: 4 }}>
        <Grid item xs={12} md={8}>
          <Paper sx={{ p: 3 }}>
            <Typography variant="h6" gutterBottom>
              Transaction Volume (Last 7 Days)
            </Typography>
            {chartLoading ? (
              <LinearProgress />
            ) : (
              <ResponsiveContainer width="100%" height={300}>
                <LineChart data={chartData}>
                  <CartesianGrid strokeDasharray="3 3" />
                  <XAxis dataKey="date" />
                  <YAxis />
                  <Tooltip formatter={(value) => [`$${value}`, 'Amount']} />
                  <Line
                    type="monotone"
                    dataKey="amount"
                    stroke="#1976d2"
                    strokeWidth={2}
                    dot={{ fill: '#1976d2' }}
                  />
                </LineChart>
              </ResponsiveContainer>
            )}
          </Paper>
        </Grid>
        <Grid item xs={12} md={4}>
          <Paper sx={{ p: 3 }}>
            <Typography variant="h6" gutterBottom>
              Transaction Status
            </Typography>
            <ResponsiveContainer width="100%" height={300}>
              <PieChart>
                <Pie
                  data={pieData}
                  cx="50%"
                  cy="50%"
                  innerRadius={60}
                  outerRadius={100}
                  paddingAngle={5}
                  dataKey="value"
                >
                  {pieData.map((entry, index) => (
                    <Cell key={`cell-${index}`} fill={entry.color} />
                  ))}
                </Pie>
                <Tooltip />
              </PieChart>
            </ResponsiveContainer>
          </Paper>
        </Grid>
      </Grid>

      {/* Recent Transactions */}
      <Paper sx={{ p: 3 }}>
        <Typography variant="h6" gutterBottom>
          Recent Transactions
        </Typography>
        {transactionsLoading ? (
          <LinearProgress />
        ) : (
          <TransactionTable
            transactions={recentTransactions || []}
            showPagination={false}
            showActions={false}
          />
        )}
      </Paper>
    </Box>
  );
};

export default Dashboard;
