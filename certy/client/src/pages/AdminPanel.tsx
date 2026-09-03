import React, { useState, useEffect } from 'react';
import { Container, Typography, Table, TableBody, TableCell, TableContainer, TableHead, TableRow, Paper, Button, Tab, Tabs, Box } from '@mui/material';
import Header from '../components/common/Header';
import Footer from '../components/common/Footer';

const AdminPanel = () => {
  const [value, setValue] = useState(0);

  const handleChange = (event: React.SyntheticEvent, newValue: number) => {
    setValue(newValue);
  };

  // Mock data for demonstration
  const [users] = useState([
    { id: '1', name: 'John Doe', email: 'john@example.com', role: 'user', registrationDate: '2023-01-15' },
    { id: '2', name: 'Jane Smith', email: 'jane@example.com', role: 'admin', registrationDate: '2023-02-20' },
    { id: '3', name: 'Alex Johnson', email: 'alex@example.com', role: 'user', registrationDate: '2023-03-10' },
  ]);

  const [orders] = useState([
    { id: '101', userId: '1', amount: 990, status: 'paid', date: '2023-04-01' },
    { id: '102', userId: '2', amount: 1990, status: 'pending', date: '2023-04-02' },
    { id: '103', userId: '3', amount: 2990, status: 'refunded', date: '2023-04-03' },
  ]);

  const [coupons] = useState([
    { id: 'C100', code: 'SAVE10', discount: '10%', active: true },
    { id: 'C101', code: 'WELCOME', discount: '15%', active: true },
    { id: 'C102', code: 'SPRING20', discount: '20%', active: false },
  ]);

  return (
    <>
      <Header />
      <Container maxWidth="lg" sx={{ mt: 4, mb: 4 }}>
        <Typography variant="h4" gutterBottom>
          Admin Panel
        </Typography>
        
        <Box sx={{ borderBottom: 1, borderColor: 'divider' }}>
          <Tabs value={value} onChange={handleChange} aria-label="admin tabs">
            <Tab label="Users" />
            <Tab label="Orders" />
            <Tab label="Coupons" />
          </Tabs>
        </Box>
        
        {value === 0 && (
          <TableContainer component={Paper} sx={{ mt: 2 }}>
            <Table>
              <TableHead>
                <TableRow>
                  <TableCell>ID</TableCell>
                  <TableCell>Name</TableCell>
                  <TableCell>Email</TableCell>
                  <TableCell>Role</TableCell>
                  <TableCell>Registration Date</TableCell>
                  <TableCell>Actions</TableCell>
                </TableRow>
              </TableHead>
              <TableBody>
                {users.map((user) => (
                  <TableRow key={user.id}>
                    <TableCell>{user.id}</TableCell>
                    <TableCell>{user.name}</TableCell>
                    <TableCell>{user.email}</TableCell>
                    <TableCell>{user.role}</TableCell>
                    <TableCell>{user.registrationDate}</TableCell>
                    <TableCell>
                      <Button variant="text" size="small">Edit</Button>
                      <Button variant="text" size="small" sx={{ ml: 1 }}>Delete</Button>
                    </TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>
          </TableContainer>
        )}
        
        {value === 1 && (
          <TableContainer component={Paper} sx={{ mt: 2 }}>
            <Table>
              <TableHead>
                <TableRow>
                  <TableCell>Order ID</TableCell>
                  <TableCell>User ID</TableCell>
                  <TableCell>Amount</TableCell>
                  <TableCell>Status</TableCell>
                  <TableCell>Date</TableCell>
                  <TableCell>Actions</TableCell>
                </TableRow>
              </TableHead>
              <TableBody>
                {orders.map((order) => (
                  <TableRow key={order.id}>
                    <TableCell>{order.id}</TableCell>
                    <TableCell>{order.userId}</TableCell>
                    <TableCell>{order.amount} RUB</TableCell>
                    <TableCell>{order.status}</TableCell>
                    <TableCell>{order.date}</TableCell>
                    <TableCell>
                      <Button variant="text" size="small">View</Button>
                      <Button variant="text" size="small" sx={{ ml: 1 }}>Refund</Button>
                    </TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>
          </TableContainer>
        )}
        
        {value === 2 && (
          <TableContainer component={Paper} sx={{ mt: 2 }}>
            <Table>
              <TableHead>
                <TableRow>
                  <TableCell>ID</TableCell>
                  <TableCell>Code</TableCell>
                  <TableCell>Discount</TableCell>
                  <TableCell>Active</TableCell>
                  <TableCell>Actions</TableCell>
                </TableRow>
              </TableHead>
              <TableBody>
                {coupons.map((coupon) => (
                  <TableRow key={coupon.id}>
                    <TableCell>{coupon.id}</TableCell>
                    <TableCell>{coupon.code}</TableCell>
                    <TableCell>{coupon.discount}</TableCell>
                    <TableCell>{coupon.active ? 'Yes' : 'No'}</TableCell>
                    <TableCell>
                      <Button variant="text" size="small">Edit</Button>
                      <Button variant="text" size="small" sx={{ ml: 1 }}>Delete</Button>
                    </TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>
          </TableContainer>
        )}
      </Container>
      <Footer />
    </>
  );
};

export default AdminPanel;