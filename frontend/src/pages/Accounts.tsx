import React, { useState } from 'react';
import {
  Box,
  Paper,
  Typography,
  Grid,
  Card,
  CardContent,
  Chip,
  IconButton,
  Tooltip,
  TextField,
  InputAdornment,
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
  TablePagination,
} from '@mui/material';
import {
  Search as SearchIcon,
  AccountBalance as AccountBalanceIcon,
  Visibility as VisibilityIcon,
  Edit as EditIcon,
} from '@mui/icons-material';
import { useQuery } from 'react-query';
import { accountApi } from '../services/api';
import { Account } from '../types';
import { formatCurrency, formatDate } from '../utils/helpers';

const AccountCard: React.FC<{ account: Account }> = ({ account }) => (
  <Card className="card-hover">
    <CardContent>
      <Box display="flex" alignItems="center" justifyContent="space-between" mb={2}>
        <Box display="flex" alignItems="center">
          <AccountBalanceIcon sx={{ mr: 1, color: 'primary.main' }} />
          <Typography variant="h6" component="h2">
            {account.accountNumber}
          </Typography>
        </Box>
        <Chip
          label={account.isActive ? 'Active' : 'Inactive'}
          color={account.isActive ? 'success' : 'default'}
          size="small"
        />
      </Box>
      
      <Typography variant="body2" color="textSecondary" gutterBottom>
        {account.accountHolderName}
      </Typography>
      
      <Typography variant="h5" color="primary" sx={{ fontWeight: 'bold', mb: 1 }}>
        {formatCurrency(account.balance, account.currency)}
      </Typography>
      
      <Typography variant="caption" color="textSecondary">
        Created: {formatDate(account.createdAt)}
      </Typography>
      
      <Box display="flex" justifyContent="flex-end" mt={2}>
        <Tooltip title="View Details">
          <IconButton size="small">
            <VisibilityIcon />
          </IconButton>
        </Tooltip>
        <Tooltip title="Edit Account">
          <IconButton size="small">
            <EditIcon />
          </IconButton>
        </Tooltip>
      </Box>
    </CardContent>
  </Card>
);

const Accounts: React.FC = () => {
  const [searchTerm, setSearchTerm] = useState('');
  const [page, setPage] = useState(0);
  const [rowsPerPage, setRowsPerPage] = useState(10);
  const [viewMode, setViewMode] = useState<'cards' | 'table'>('cards');

  // Get accounts from API
  const { data: accounts = [], isLoading } = useQuery('accounts', accountApi.getAccounts);

  const filteredAccounts = accounts.filter(account =>
    account.accountNumber.toLowerCase().includes(searchTerm.toLowerCase()) ||
    account.accountHolderName.toLowerCase().includes(searchTerm.toLowerCase())
  );

  const paginatedAccounts = filteredAccounts.slice(
    page * rowsPerPage,
    page * rowsPerPage + rowsPerPage
  );

  const handleChangePage = (event: unknown, newPage: number) => {
    setPage(newPage);
  };

  const handleChangeRowsPerPage = (event: React.ChangeEvent<HTMLInputElement>) => {
    setRowsPerPage(parseInt(event.target.value, 10));
    setPage(0);
  };

  const totalBalance = accounts.reduce((sum, account) => sum + account.balance, 0);
  const activeAccounts = accounts.filter(account => account.isActive).length;

  return (
    <Box className="fade-in">
      <Typography variant="h4" gutterBottom sx={{ fontWeight: 'bold', mb: 3 }}>
        Accounts
      </Typography>

      {/* Summary Cards */}
      <Grid container spacing={3} sx={{ mb: 4 }}>
        <Grid item xs={12} sm={6} md={3}>
          <Card>
            <CardContent>
              <Typography color="textSecondary" gutterBottom variant="h6">
                Total Accounts
              </Typography>
              <Typography variant="h4" component="h2" sx={{ fontWeight: 'bold' }}>
                {accounts.length}
              </Typography>
            </CardContent>
          </Card>
        </Grid>
        <Grid item xs={12} sm={6} md={3}>
          <Card>
            <CardContent>
              <Typography color="textSecondary" gutterBottom variant="h6">
                Active Accounts
              </Typography>
              <Typography variant="h4" component="h2" sx={{ fontWeight: 'bold' }}>
                {activeAccounts}
              </Typography>
            </CardContent>
          </Card>
        </Grid>
        <Grid item xs={12} sm={6} md={3}>
          <Card>
            <CardContent>
              <Typography color="textSecondary" gutterBottom variant="h6">
                Total Balance
              </Typography>
              <Typography variant="h4" component="h2" sx={{ fontWeight: 'bold' }}>
                {formatCurrency(totalBalance)}
              </Typography>
            </CardContent>
          </Card>
        </Grid>
        <Grid item xs={12} sm={6} md={3}>
          <Card>
            <CardContent>
              <Typography color="textSecondary" gutterBottom variant="h6">
                Average Balance
              </Typography>
              <Typography variant="h4" component="h2" sx={{ fontWeight: 'bold' }}>
                {formatCurrency(totalBalance / accounts.length)}
              </Typography>
            </CardContent>
          </Card>
        </Grid>
      </Grid>

      {/* Search and Controls */}
      <Paper sx={{ p: 2, mb: 3 }}>
        <Box display="flex" alignItems="center" justifyContent="space-between">
          <TextField
            placeholder="Search accounts..."
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
            InputProps={{
              startAdornment: (
                <InputAdornment position="start">
                  <SearchIcon />
                </InputAdornment>
              ),
            }}
            sx={{ minWidth: 300 }}
          />
        </Box>
      </Paper>

      {/* Accounts Display */}
      {viewMode === 'cards' ? (
        <Grid container spacing={3}>
          {paginatedAccounts.map((account) => (
            <Grid item xs={12} sm={6} md={4} key={account.id}>
              <AccountCard account={account} />
            </Grid>
          ))}
        </Grid>
      ) : (
        <TableContainer component={Paper}>
          <Table>
            <TableHead>
              <TableRow>
                <TableCell>Account Number</TableCell>
                <TableCell>Account Holder</TableCell>
                <TableCell>Balance</TableCell>
                <TableCell>Status</TableCell>
                <TableCell>Created</TableCell>
                <TableCell>Actions</TableCell>
              </TableRow>
            </TableHead>
            <TableBody>
              {paginatedAccounts.map((account) => (
                <TableRow key={account.id} hover>
                  <TableCell>
                    <Typography variant="body2" sx={{ fontFamily: 'monospace' }}>
                      {account.accountNumber}
                    </Typography>
                  </TableCell>
                  <TableCell>{account.accountHolderName}</TableCell>
                  <TableCell>
                    <Typography variant="body2" sx={{ fontWeight: 'bold' }}>
                      {formatCurrency(account.balance, account.currency)}
                    </Typography>
                  </TableCell>
                  <TableCell>
                    <Chip
                      label={account.isActive ? 'Active' : 'Inactive'}
                      color={account.isActive ? 'success' : 'default'}
                      size="small"
                    />
                  </TableCell>
                  <TableCell>{formatDate(account.createdAt)}</TableCell>
                  <TableCell>
                    <Tooltip title="View Details">
                      <IconButton size="small">
                        <VisibilityIcon />
                      </IconButton>
                    </Tooltip>
                    <Tooltip title="Edit Account">
                      <IconButton size="small">
                        <EditIcon />
                      </IconButton>
                    </Tooltip>
                  </TableCell>
                </TableRow>
              ))}
            </TableBody>
          </Table>
          <TablePagination
            rowsPerPageOptions={[5, 10, 25]}
            component="div"
            count={filteredAccounts.length}
            rowsPerPage={rowsPerPage}
            page={page}
            onPageChange={handleChangePage}
            onRowsPerPageChange={handleChangeRowsPerPage}
          />
        </TableContainer>
      )}
    </Box>
  );
};

export default Accounts;
