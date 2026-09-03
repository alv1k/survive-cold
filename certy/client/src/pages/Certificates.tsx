import React, { useState } from 'react';
import { Container, Typography, Button, TextField, Box, Paper, FormControl, InputLabel, Select, MenuItem } from '@mui/material';
import Header from '../components/common/Header';
import Footer from '../components/common/Footer';

const Certificates = () => {
  const [participants, setParticipants] = useState('');
  const [eventTitle, setEventTitle] = useState('');
  const [selectedTemplate, setSelectedTemplate] = useState('');
  const [templates] = useState([
    { id: 'template1', name: 'Basic Certificate' },
    { id: 'template2', name: 'Professional Certificate' },
    { id: 'template3', name: 'Academic Certificate' },
  ]);

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    // In a real app, this would trigger certificate generation
    alert('Certificates will be generated based on the provided data');
  };

  return (
    <>
      <Header />
      <Container maxWidth="lg" sx={{ mt: 4, mb: 4 }}>
        <Typography variant="h4" gutterBottom>
          Generate Certificates
        </Typography>
        
        <Paper sx={{ p: 3, mb: 3 }}>
          <form onSubmit={handleSubmit}>
            <TextField
              fullWidth
              label="Event Title"
              value={eventTitle}
              onChange={(e) => setEventTitle(e.target.value)}
              margin="normal"
              required
            />
            
            <FormControl fullWidth margin="normal" required>
              <InputLabel>Template</InputLabel>
              <Select
                value={selectedTemplate}
                label="Template"
                onChange={(e) => setSelectedTemplate(e.target.value)}
              >
                {templates.map((template) => (
                  <MenuItem key={template.id} value={template.id}>
                    {template.name}
                  </MenuItem>
                ))}
              </Select>
            </FormControl>
            
            <TextField
              fullWidth
              label="Participants (one per line, format: Name)"
              value={participants}
              onChange={(e) => setParticipants(e.target.value)}
              margin="normal"
              multiline
              rows={6}
              placeholder="Enter participants, one per line&#10;Example:&#10;John Doe&#10;Jane Smith&#10;Alex Johnson"
              required
            />
            
            <Box sx={{ mt: 3, textAlign: 'right' }}>
              <Button variant="contained" type="submit" size="large">
                Generate Certificates
              </Button>
            </Box>
          </form>
        </Paper>
      </Container>
      <Footer />
    </>
  );
};

export default Certificates;