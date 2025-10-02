import React, { useState } from 'react';
import {
  Box,
  Paper,
  Typography,
  TextField,
  Button,
  Grid,
  FormControl,
  InputLabel,
  Select,
  MenuItem,
  Alert,
  CircularProgress,
  Card,
  CardContent,
  Divider,
} from '@mui/material';
import { Send as SendIcon, AccountBalance as AccountBalanceIcon } from '@mui/icons-material';
import { useForm, Controller } from 'react-hook-form';
import { yupResolver } from '@hookform/resolvers/yup';
import * as yup from 'yup';
import { useMutation, useQuery } from 'react-query';
import toast from 'react-hot-toast';
import { transferApi, accountApi } from '../services/api';
import { TransferRequest, Account } from '../types';

const schema = yup.object({
  fromAccountId: yup.string().required('From account is required'),
  toAccountId: yup.string().required('To account is required'),
  amount: yup
    .number()
    .positive('Amount must be positive')
    .required('Amount is required'),
  currency: yup.string().required('Currency is required'),
  description: yup.string().max(500, 'Description must be less than 500 characters'),
});

interface TransferFormData {
  fromAccountId: string;
  toAccountId: string;
  amount: number;
  currency: string;
  description?: string;
}

const Transfer: React.FC = () => {
  const [selectedFromAccount, setSelectedFromAccount] = useState<Account | null>(null);
  const [selectedToAccount, setSelectedToAccount] = useState<Account | null>(null);

  const {
    control,
    handleSubmit,
    formState: { errors },
    reset,
    watch,
  } = useForm<TransferFormData>({
    resolver: yupResolver(schema),
    defaultValues: {
      currency: 'USD',
    },
  });

  const watchedFromAccount = watch('fromAccountId');
  const watchedToAccount = watch('toAccountId');
  const watchedAmount = watch('amount');

  // Get accounts from API
  const { data: accounts = [], isLoading: accountsLoading } = useQuery('accounts', accountApi.getAccounts);

  const transferMutation = useMutation(transferApi.transferMoney, {
    onSuccess: (data) => {
      if (data.success) {
        toast.success('Transfer completed successfully!');
        reset();
        setSelectedFromAccount(null);
        setSelectedToAccount(null);
      } else {
        toast.error(data.errorMessage || 'Transfer failed');
      }
    },
    onError: (error: any) => {
      toast.error(error.response?.data?.message || 'Transfer failed');
    },
  });

  const onSubmit = (data: TransferFormData) => {
    if (data.fromAccountId === data.toAccountId) {
      toast.error('Cannot transfer to the same account');
      return;
    }

    const transferRequest: TransferRequest = {
      fromAccountId: data.fromAccountId,
      toAccountId: data.toAccountId,
      amount: data.amount,
      currency: data.currency,
      description: data.description,
    };

    transferMutation.mutate(transferRequest);
  };

  const handleFromAccountChange = (accountId: string) => {
    const account = accounts.find(acc => acc.id === accountId);
    setSelectedFromAccount(account || null);
  };

  const handleToAccountChange = (accountId: string) => {
    const account = accounts.find(acc => acc.id === accountId);
    setSelectedToAccount(account || null);
  };

  if (accountsLoading) {
    return (
      <Box display="flex" justifyContent="center" alignItems="center" minHeight="400px">
        <CircularProgress />
      </Box>
    );
  }

  return (
    <Box className="fade-in">
      <Typography variant="h4" gutterBottom sx={{ fontWeight: 'bold', mb: 3 }}>
        Transfer Money
      </Typography>

      <Grid container spacing={3}>
        <Grid item xs={12} md={8}>
          <Paper sx={{ p: 3 }}>
            <Typography variant="h6" gutterBottom>
              Transfer Details
            </Typography>
            
            <Box component="form" onSubmit={handleSubmit(onSubmit)} sx={{ mt: 2 }}>
              <Grid container spacing={3}>
                <Grid item xs={12} sm={6}>
                  <FormControl fullWidth error={!!errors.fromAccountId}>
                    <InputLabel>From Account</InputLabel>
                    <Controller
                      name="fromAccountId"
                      control={control}
                      render={({ field }) => (
                        <Select
                          {...field}
                          label="From Account"
                          onChange={(e) => {
                            field.onChange(e);
                            handleFromAccountChange(e.target.value);
                          }}
                        >
                          {accounts.map((account) => (
                            <MenuItem key={account.id} value={account.id}>
                              {account.accountNumber} - {account.accountHolderName}
                            </MenuItem>
                          ))}
                        </Select>
                      )}
                    />
                    {errors.fromAccountId && (
                      <Typography variant="caption" color="error">
                        {errors.fromAccountId.message}
                      </Typography>
                    )}
                  </FormControl>
                </Grid>

                <Grid item xs={12} sm={6}>
                  <FormControl fullWidth error={!!errors.toAccountId}>
                    <InputLabel>To Account</InputLabel>
                    <Controller
                      name="toAccountId"
                      control={control}
                      render={({ field }) => (
                        <Select
                          {...field}
                          label="To Account"
                          onChange={(e) => {
                            field.onChange(e);
                            handleToAccountChange(e.target.value);
                          }}
                        >
                          {accounts
                            .filter(account => account.id !== watchedFromAccount)
                            .map((account) => (
                              <MenuItem key={account.id} value={account.id}>
                                {account.accountNumber} - {account.accountHolderName}
                              </MenuItem>
                            ))}
                        </Select>
                      )}
                    />
                    {errors.toAccountId && (
                      <Typography variant="caption" color="error">
                        {errors.toAccountId.message}
                      </Typography>
                    )}
                  </FormControl>
                </Grid>

                <Grid item xs={12} sm={6}>
                  <Controller
                    name="amount"
                    control={control}
                    render={({ field }) => (
                      <TextField
                        {...field}
                        fullWidth
                        label="Amount"
                        type="number"
                        error={!!errors.amount}
                        helperText={errors.amount?.message}
                        inputProps={{ min: 0, step: 0.01 }}
                      />
                    )}
                  />
                </Grid>

                <Grid item xs={12} sm={6}>
                  <FormControl fullWidth error={!!errors.currency}>
                    <InputLabel>Currency</InputLabel>
                    <Controller
                      name="currency"
                      control={control}
                      render={({ field }) => (
                        <Select {...field} label="Currency">
                          <MenuItem value="USD">USD</MenuItem>
                          <MenuItem value="EUR">EUR</MenuItem>
                          <MenuItem value="GBP">GBP</MenuItem>
                        </Select>
                      )}
                    />
                    {errors.currency && (
                      <Typography variant="caption" color="error">
                        {errors.currency.message}
                      </Typography>
                    )}
                  </FormControl>
                </Grid>

                <Grid item xs={12}>
                  <Controller
                    name="description"
                    control={control}
                    render={({ field }) => (
                      <TextField
                        {...field}
                        fullWidth
                        label="Description (Optional)"
                        multiline
                        rows={3}
                        error={!!errors.description}
                        helperText={errors.description?.message}
                      />
                    )}
                  />
                </Grid>

                <Grid item xs={12}>
                  <Button
                    type="submit"
                    variant="contained"
                    size="large"
                    startIcon={
                      transferMutation.isLoading ? (
                        <CircularProgress size={20} color="inherit" />
                      ) : (
                        <SendIcon />
                      )
                    }
                    disabled={transferMutation.isLoading}
                    sx={{ minWidth: 200 }}
                  >
                    {transferMutation.isLoading ? 'Processing...' : 'Transfer Money'}
                  </Button>
                </Grid>
              </Grid>
            </Box>
          </Paper>
        </Grid>

        <Grid item xs={12} md={4}>
          <Card>
            <CardContent>
              <Typography variant="h6" gutterBottom>
                Account Information
              </Typography>
              
              {selectedFromAccount && (
                <Box sx={{ mb: 2 }}>
                  <Typography variant="subtitle2" color="textSecondary">
                    From Account
                  </Typography>
                  <Typography variant="body2">
                    {selectedFromAccount.accountNumber} - {selectedFromAccount.accountHolderName}
                  </Typography>
                  <Typography variant="h6" color="primary">
                    Balance: ${selectedFromAccount.balance.toLocaleString()}
                  </Typography>
                </Box>
              )}

              {selectedToAccount && (
                <Box sx={{ mb: 2 }}>
                  <Typography variant="subtitle2" color="textSecondary">
                    To Account
                  </Typography>
                  <Typography variant="body2">
                    {selectedToAccount.accountNumber} - {selectedToAccount.accountHolderName}
                  </Typography>
                  <Typography variant="h6" color="primary">
                    Balance: ${selectedToAccount.balance.toLocaleString()}
                  </Typography>
                </Box>
              )}

              {watchedAmount && selectedFromAccount && (
                <>
                  <Divider sx={{ my: 2 }} />
                  <Typography variant="subtitle2" color="textSecondary">
                    After Transfer
                  </Typography>
                  <Typography variant="body2">
                    From Account: ${(selectedFromAccount.balance - watchedAmount).toLocaleString()}
                  </Typography>
                  {selectedToAccount && (
                    <Typography variant="body2">
                      To Account: ${(selectedToAccount.balance + watchedAmount).toLocaleString()}
                    </Typography>
                  )}
                </>
              )}
            </CardContent>
          </Card>
        </Grid>
      </Grid>
    </Box>
  );
};

export default Transfer;
