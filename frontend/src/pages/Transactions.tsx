import React, { useState } from 'react';
import {
  Box,
  Paper,
  Typography,
  Grid,
  Card,
  CardContent,
  TextField,
  InputAdornment,
  FormControl,
  InputLabel,
  Select,
  MenuItem,
  Button,
  Chip,
  IconButton,
  Tooltip,
} from '@mui/material';
import {
  Search as SearchIcon,
  FilterList as FilterListIcon,
  Refresh as RefreshIcon,
  GetApp as ExportIcon,
} from '@mui/icons-material';
import { useQuery } from 'react-query';
import { transactionApi } from '../services/api';
import { Transaction, TransactionStatus, TransactionType } from '../types';
import TransactionTable from '../components/TransactionTable';
import { formatCurrency } from '../utils/helpers';

const Transactions: React.FC = () => {
  const [searchTerm, setSearchTerm] = useState('');
  const [statusFilter, setStatusFilter] = useState<TransactionStatus | 'all'>('all');
  const [typeFilter, setTypeFilter] = useState<TransactionType | 'all'>('all');
  const [page, setPage] = useState(0);
  const [rowsPerPage, setRowsPerPage] = useState(25);

  // Get transactions from API
  const { data: transactionsData, isLoading, refetch } = useQuery(
    ['transactions', page, rowsPerPage, statusFilter, typeFilter],
    () => transactionApi.getAllTransactions(page + 1, rowsPerPage),
    {
      keepPreviousData: true,
    }
  );

  const mockTransactions: Transaction[] = transactionsData?.transactions || [];

  const filteredTransactions = mockTransactions.filter(transaction => {
    const matchesSearch = 
      transaction.id.toLowerCase().includes(searchTerm.toLowerCase()) ||
      transaction.description?.toLowerCase().includes(searchTerm.toLowerCase()) ||
      transaction.fromAccountId.toLowerCase().includes(searchTerm.toLowerCase()) ||
      transaction.toAccountId.toLowerCase().includes(searchTerm.toLowerCase());
    
    const matchesStatus = statusFilter === 'all' || transaction.status === statusFilter;
    const matchesType = typeFilter === 'all' || transaction.type === typeFilter;
    
    return matchesSearch && matchesStatus && matchesType;
  });

  const handleViewTransaction = (transaction: Transaction) => {
    console.log('View transaction:', transaction);
    // Implement view transaction logic
  };

  const handleRefresh = () => {
    refetch();
  };

  const handleExport = () => {
    console.log('Export transactions');
    // Implement export logic
  };

  const getStatusCounts = () => {
    const counts = {
      [TransactionStatus.Completed]: 0,
      [TransactionStatus.Processing]: 0,
      [TransactionStatus.Failed]: 0,
      [TransactionStatus.Pending]: 0,
      [TransactionStatus.Cancelled]: 0,
      [TransactionStatus.RolledBack]: 0,
    };
    
    mockTransactions.forEach(transaction => {
      counts[transaction.status]++;
    });
    
    return counts;
  };

  const statusCounts = getStatusCounts();
  const totalVolume = mockTransactions
    .filter(t => t.status === TransactionStatus.Completed)
    .reduce((sum, t) => sum + t.amount, 0);

  return (
    <Box className="fade-in">
      <Typography variant="h4" gutterBottom sx={{ fontWeight: 'bold', mb: 3 }}>
        Transactions
      </Typography>

      {/* Summary Cards */}
      <Grid container spacing={3} sx={{ mb: 4 }}>
        <Grid item xs={12} sm={6} md={2}>
          <Card>
            <CardContent>
              <Typography color="textSecondary" gutterBottom variant="h6">
                Total
              </Typography>
              <Typography variant="h4" component="h2" sx={{ fontWeight: 'bold' }}>
                {mockTransactions.length}
              </Typography>
            </CardContent>
          </Card>
        </Grid>
        <Grid item xs={12} sm={6} md={2}>
          <Card>
            <CardContent>
              <Typography color="textSecondary" gutterBottom variant="h6">
                Completed
              </Typography>
              <Typography variant="h4" component="h2" sx={{ fontWeight: 'bold', color: 'success.main' }}>
                {statusCounts[TransactionStatus.Completed]}
              </Typography>
            </CardContent>
          </Card>
        </Grid>
        <Grid item xs={12} sm={6} md={2}>
          <Card>
            <CardContent>
              <Typography color="textSecondary" gutterBottom variant="h6">
                Processing
              </Typography>
              <Typography variant="h4" component="h2" sx={{ fontWeight: 'bold', color: 'warning.main' }}>
                {statusCounts[TransactionStatus.Processing]}
              </Typography>
            </CardContent>
          </Card>
        </Grid>
        <Grid item xs={12} sm={6} md={2}>
          <Card>
            <CardContent>
              <Typography color="textSecondary" gutterBottom variant="h6">
                Failed
              </Typography>
              <Typography variant="h4" component="h2" sx={{ fontWeight: 'bold', color: 'error.main' }}>
                {statusCounts[TransactionStatus.Failed]}
              </Typography>
            </CardContent>
          </Card>
        </Grid>
        <Grid item xs={12} sm={6} md={2}>
          <Card>
            <CardContent>
              <Typography color="textSecondary" gutterBottom variant="h6">
                Rolled Back
              </Typography>
              <Typography variant="h4" component="h2" sx={{ fontWeight: 'bold', color: 'info.main' }}>
                {statusCounts[TransactionStatus.RolledBack]}
              </Typography>
            </CardContent>
          </Card>
        </Grid>
        <Grid item xs={12} sm={6} md={2}>
          <Card>
            <CardContent>
              <Typography color="textSecondary" gutterBottom variant="h6">
                Total Volume
              </Typography>
              <Typography variant="h4" component="h2" sx={{ fontWeight: 'bold' }}>
                {formatCurrency(totalVolume)}
              </Typography>
            </CardContent>
          </Card>
        </Grid>
      </Grid>

      {/* Filters and Search */}
      <Paper sx={{ p: 2, mb: 3 }}>
        <Grid container spacing={2} alignItems="center">
          <Grid item xs={12} md={4}>
            <TextField
              fullWidth
              placeholder="Search transactions..."
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
              InputProps={{
                startAdornment: (
                  <InputAdornment position="start">
                    <SearchIcon />
                  </InputAdornment>
                ),
              }}
            />
          </Grid>
          <Grid item xs={12} md={2}>
            <FormControl fullWidth>
              <InputLabel>Status</InputLabel>
              <Select
                value={statusFilter}
                label="Status"
                onChange={(e) => setStatusFilter(e.target.value as TransactionStatus | 'all')}
              >
                <MenuItem value="all">All Status</MenuItem>
                <MenuItem value={TransactionStatus.Completed}>Completed</MenuItem>
                <MenuItem value={TransactionStatus.Processing}>Processing</MenuItem>
                <MenuItem value={TransactionStatus.Failed}>Failed</MenuItem>
                <MenuItem value={TransactionStatus.Pending}>Pending</MenuItem>
                <MenuItem value={TransactionStatus.Cancelled}>Cancelled</MenuItem>
                <MenuItem value={TransactionStatus.RolledBack}>Rolled Back</MenuItem>
              </Select>
            </FormControl>
          </Grid>
          <Grid item xs={12} md={2}>
            <FormControl fullWidth>
              <InputLabel>Type</InputLabel>
              <Select
                value={typeFilter}
                label="Type"
                onChange={(e) => setTypeFilter(e.target.value as TransactionType | 'all')}
              >
                <MenuItem value="all">All Types</MenuItem>
                <MenuItem value={TransactionType.Transfer}>Transfer</MenuItem>
                <MenuItem value={TransactionType.Deposit}>Deposit</MenuItem>
                <MenuItem value={TransactionType.Withdrawal}>Withdrawal</MenuItem>
                <MenuItem value={TransactionType.Refund}>Refund</MenuItem>
              </Select>
            </FormControl>
          </Grid>
          <Grid item xs={12} md={4}>
            <Box display="flex" gap={1}>
              <Button
                variant="outlined"
                startIcon={<RefreshIcon />}
                onClick={handleRefresh}
              >
                Refresh
              </Button>
              <Button
                variant="outlined"
                startIcon={<ExportIcon />}
                onClick={handleExport}
              >
                Export
              </Button>
            </Box>
          </Grid>
        </Grid>
      </Paper>

      {/* Transactions Table */}
      <Paper sx={{ p: 2 }}>
        <TransactionTable
          transactions={filteredTransactions}
          showPagination={true}
          showActions={true}
          onViewTransaction={handleViewTransaction}
        />
      </Paper>
    </Box>
  );
};

export default Transactions;
