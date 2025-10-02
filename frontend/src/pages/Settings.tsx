import React, { useState } from 'react';
import {
  Box,
  Paper,
  Typography,
  Grid,
  Card,
  CardContent,
  Switch,
  FormControlLabel,
  TextField,
  Button,
  Divider,
  Alert,
  Chip,
  List,
  ListItem,
  ListItemText,
  ListItemSecondaryAction,
  IconButton,
} from '@mui/material';
import {
  Save as SaveIcon,
  Refresh as RefreshIcon,
  Delete as DeleteIcon,
  Add as AddIcon,
} from '@mui/icons-material';
import { useQuery, useMutation } from 'react-query';
import toast from 'react-hot-toast';
import { healthApi } from '../services/api';

const Settings: React.FC = () => {
  const [settings, setSettings] = useState({
    autoRefresh: true,
    refreshInterval: 30,
    notifications: true,
    emailNotifications: true,
    smsNotifications: false,
    darkMode: false,
    language: 'en',
    timezone: 'UTC',
  });

  const { data: healthStatus, refetch: checkHealth } = useQuery(
    'health-check',
    healthApi.checkHealth,
    {
      refetchInterval: 60000,
    }
  );

  const handleSettingChange = (key: string, value: any) => {
    setSettings(prev => ({
      ...prev,
      [key]: value,
    }));
  };

  const handleSaveSettings = () => {
    // In a real app, this would save to backend
    localStorage.setItem('app-settings', JSON.stringify(settings));
    toast.success('Settings saved successfully!');
  };

  const handleResetSettings = () => {
    const defaultSettings = {
      autoRefresh: true,
      refreshInterval: 30,
      notifications: true,
      emailNotifications: true,
      smsNotifications: false,
      darkMode: false,
      language: 'en',
      timezone: 'UTC',
    };
    setSettings(defaultSettings);
    toast.success('Settings reset to defaults!');
  };

  const apiEndpoints = [
    { name: 'Payment Service', url: 'http://localhost:5001', status: 'healthy' },
    { name: 'Notification Service', url: 'http://localhost:5002', status: 'healthy' },
    { name: 'Database', url: 'PostgreSQL', status: 'healthy' },
    { name: 'Message Queue', url: 'RabbitMQ', status: 'healthy' },
  ];

  return (
    <Box className="fade-in">
      <Typography variant="h4" gutterBottom sx={{ fontWeight: 'bold', mb: 3 }}>
        Settings
      </Typography>

      <Grid container spacing={3}>
        {/* General Settings */}
        <Grid item xs={12} md={6}>
          <Paper sx={{ p: 3 }}>
            <Typography variant="h6" gutterBottom>
              General Settings
            </Typography>
            
            <Box sx={{ mt: 2 }}>
              <FormControlLabel
                control={
                  <Switch
                    checked={settings.autoRefresh}
                    onChange={(e) => handleSettingChange('autoRefresh', e.target.checked)}
                  />
                }
                label="Auto Refresh Dashboard"
              />
            </Box>

            <Box sx={{ mt: 2 }}>
              <TextField
                fullWidth
                label="Refresh Interval (seconds)"
                type="number"
                value={settings.refreshInterval}
                onChange={(e) => handleSettingChange('refreshInterval', parseInt(e.target.value))}
                disabled={!settings.autoRefresh}
                helperText="How often to refresh dashboard data"
              />
            </Box>

            <Box sx={{ mt: 2 }}>
              <FormControlLabel
                control={
                  <Switch
                    checked={settings.darkMode}
                    onChange={(e) => handleSettingChange('darkMode', e.target.checked)}
                  />
                }
                label="Dark Mode"
              />
            </Box>

            <Box sx={{ mt: 2 }}>
              <TextField
                fullWidth
                select
                label="Language"
                value={settings.language}
                onChange={(e) => handleSettingChange('language', e.target.value)}
                SelectProps={{
                  native: true,
                }}
              >
                <option value="en">English</option>
                <option value="vi">Tiếng Việt</option>
                <option value="es">Español</option>
                <option value="fr">Français</option>
              </TextField>
            </Box>

            <Box sx={{ mt: 2 }}>
              <TextField
                fullWidth
                select
                label="Timezone"
                value={settings.timezone}
                onChange={(e) => handleSettingChange('timezone', e.target.value)}
                SelectProps={{
                  native: true,
                }}
              >
                <option value="UTC">UTC</option>
                <option value="America/New_York">Eastern Time</option>
                <option value="America/Chicago">Central Time</option>
                <option value="America/Denver">Mountain Time</option>
                <option value="America/Los_Angeles">Pacific Time</option>
                <option value="Europe/London">London</option>
                <option value="Asia/Tokyo">Tokyo</option>
                <option value="Asia/Ho_Chi_Minh">Ho Chi Minh</option>
              </TextField>
            </Box>
          </Paper>
        </Grid>

        {/* Notification Settings */}
        <Grid item xs={12} md={6}>
          <Paper sx={{ p: 3 }}>
            <Typography variant="h6" gutterBottom>
              Notification Settings
            </Typography>
            
            <Box sx={{ mt: 2 }}>
              <FormControlLabel
                control={
                  <Switch
                    checked={settings.notifications}
                    onChange={(e) => handleSettingChange('notifications', e.target.checked)}
                  />
                }
                label="Enable Notifications"
              />
            </Box>

            <Box sx={{ mt: 2 }}>
              <FormControlLabel
                control={
                  <Switch
                    checked={settings.emailNotifications}
                    onChange={(e) => handleSettingChange('emailNotifications', e.target.checked)}
                    disabled={!settings.notifications}
                  />
                }
                label="Email Notifications"
              />
            </Box>

            <Box sx={{ mt: 2 }}>
              <FormControlLabel
                control={
                  <Switch
                    checked={settings.smsNotifications}
                    onChange={(e) => handleSettingChange('smsNotifications', e.target.checked)}
                    disabled={!settings.notifications}
                  />
                }
                label="SMS Notifications"
              />
            </Box>

            <Divider sx={{ my: 3 }} />

            <Box display="flex" gap={2}>
              <Button
                variant="contained"
                startIcon={<SaveIcon />}
                onClick={handleSaveSettings}
              >
                Save Settings
              </Button>
              <Button
                variant="outlined"
                onClick={handleResetSettings}
              >
                Reset to Defaults
              </Button>
            </Box>
          </Paper>
        </Grid>

        {/* System Status */}
        <Grid item xs={12}>
          <Paper sx={{ p: 3 }}>
            <Box display="flex" alignItems="center" justifyContent="space-between" mb={2}>
              <Typography variant="h6">
                System Status
              </Typography>
              <Button
                variant="outlined"
                startIcon={<RefreshIcon />}
                onClick={() => checkHealth()}
                size="small"
              >
                Refresh
              </Button>
            </Box>

            <Grid container spacing={2}>
              {apiEndpoints.map((endpoint, index) => (
                <Grid item xs={12} sm={6} md={3} key={index}>
                  <Card variant="outlined">
                    <CardContent>
                      <Box display="flex" alignItems="center" justifyContent="space-between">
                        <Box>
                          <Typography variant="subtitle2" gutterBottom>
                            {endpoint.name}
                          </Typography>
                          <Typography variant="body2" color="textSecondary">
                            {endpoint.url}
                          </Typography>
                        </Box>
                        <Chip
                          label={endpoint.status}
                          color={endpoint.status === 'healthy' ? 'success' : 'error'}
                          size="small"
                        />
                      </Box>
                    </CardContent>
                  </Card>
                </Grid>
              ))}
            </Grid>

            {healthStatus && (
              <Alert severity="success" sx={{ mt: 2 }}>
                Last health check: {new Date(healthStatus.timestamp).toLocaleString()}
              </Alert>
            )}
          </Paper>
        </Grid>

        {/* API Configuration */}
        <Grid item xs={12}>
          <Paper sx={{ p: 3 }}>
            <Typography variant="h6" gutterBottom>
              API Configuration
            </Typography>
            
            <List>
              <ListItem>
                <ListItemText
                  primary="Payment Service API"
                  secondary="http://localhost:5001/api/payment"
                />
                <ListItemSecondaryAction>
                  <IconButton edge="end" aria-label="delete">
                    <DeleteIcon />
                  </IconButton>
                </ListItemSecondaryAction>
              </ListItem>
              <ListItem>
                <ListItemText
                  primary="Notification Service API"
                  secondary="http://localhost:5002/api/notification"
                />
                <ListItemSecondaryAction>
                  <IconButton edge="end" aria-label="delete">
                    <DeleteIcon />
                  </IconButton>
                </ListItemSecondaryAction>
              </ListItem>
              <ListItem>
                <ListItemText
                  primary="Database Connection"
                  secondary="PostgreSQL - localhost:5432"
                />
                <ListItemSecondaryAction>
                  <IconButton edge="end" aria-label="delete">
                    <DeleteIcon />
                  </IconButton>
                </ListItemSecondaryAction>
              </ListItem>
            </List>

            <Button
              variant="outlined"
              startIcon={<AddIcon />}
              sx={{ mt: 2 }}
            >
              Add API Endpoint
            </Button>
          </Paper>
        </Grid>
      </Grid>
    </Box>
  );
};

export default Settings;
