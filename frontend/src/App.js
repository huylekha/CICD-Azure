import React from 'react';
import { Box, Typography, Container, Button, Grid, Card, CardContent } from '@mui/material';
import { AccountBalance, Send, History, Settings } from '@mui/icons-material';

function App() {
  return (
    <Container maxWidth="lg">
      <Box sx={{ my: 4 }}>
        <Typography variant="h2" component="h1" gutterBottom align="center">
          🚀 CI/CD Azure Microservices Demo
        </Typography>
        <Typography variant="h5" component="h2" gutterBottom align="center" color="primary">
          Frontend Demo với Mock Data
        </Typography>
        
        <Box sx={{ mt: 4, mb: 4 }}>
          <Typography variant="body1" align="center" sx={{ mb: 3 }}>
            Đây là demo frontend với mock data. Backend services chưa được deploy.
          </Typography>
        </Box>

        <Grid container spacing={3}>
          <Grid item xs={12} md={6}>
            <Card>
              <CardContent>
                <Typography variant="h6" gutterBottom>
                  <AccountBalance sx={{ mr: 1, verticalAlign: 'middle' }} />
                  Account Management
                </Typography>
                <Typography variant="body2" color="text.secondary">
                  Quản lý tài khoản với mock data
                </Typography>
                <Button variant="contained" sx={{ mt: 2 }} fullWidth>
                  View Accounts
                </Button>
              </CardContent>
            </Card>
          </Grid>

          <Grid item xs={12} md={6}>
            <Card>
              <CardContent>
                <Typography variant="h6" gutterBottom>
                  <Send sx={{ mr: 1, verticalAlign: 'middle' }} />
                  Transfer Money
                </Typography>
                <Typography variant="body2" color="text.secondary">
                  Chuyển tiền giữa các tài khoản
                </Typography>
                <Button variant="contained" sx={{ mt: 2 }} fullWidth>
                  Transfer Now
                </Button>
              </CardContent>
            </Card>
          </Grid>

          <Grid item xs={12} md={6}>
            <Card>
              <CardContent>
                <Typography variant="h6" gutterBottom>
                  <History sx={{ mr: 1, verticalAlign: 'middle' }} />
                  Transaction History
                </Typography>
                <Typography variant="body2" color="text.secondary">
                  Xem lịch sử giao dịch
                </Typography>
                <Button variant="contained" sx={{ mt: 2 }} fullWidth>
                  View History
                </Button>
              </CardContent>
            </Card>
          </Grid>

          <Grid item xs={12} md={6}>
            <Card>
              <CardContent>
                <Typography variant="h6" gutterBottom>
                  <Settings sx={{ mr: 1, verticalAlign: 'middle' }} />
                  Settings
                </Typography>
                <Typography variant="body2" color="text.secondary">
                  Cài đặt hệ thống
                </Typography>
                <Button variant="contained" sx={{ mt: 2 }} fullWidth>
                  Open Settings
                </Button>
              </CardContent>
            </Card>
          </Grid>
        </Grid>

        <Box sx={{ mt: 4 }}>
          <Typography variant="h6" gutterBottom>✅ Features:</Typography>
          <Grid container spacing={1}>
            <Grid item xs={12} sm={6}>
              <Typography variant="body2">• React với Material-UI</Typography>
              <Typography variant="body2">• Transfer Money Form</Typography>
              <Typography variant="body2">• Transaction History</Typography>
            </Grid>
            <Grid item xs={12} sm={6}>
              <Typography variant="body2">• Account Management</Typography>
              <Typography variant="body2">• Real-time Updates (Mock)</Typography>
              <Typography variant="body2">• Responsive Design</Typography>
            </Grid>
          </Grid>
        </Box>

        <Box sx={{ mt: 4, p: 2, bgcolor: 'grey.100', borderRadius: 1 }}>
          <Typography variant="h6" gutterBottom>🌐 Demo URLs:</Typography>
          <Typography variant="body2">• Frontend: http://localhost:3000</Typography>
          <Typography variant="body2">• RabbitMQ: http://localhost:15672 (admin/admin123)</Typography>
          <Typography variant="body2">• PostgreSQL: localhost:5432 (postgresadmin/admin123)</Typography>
        </Box>
      </Box>
    </Container>
  );
}

export default App;

