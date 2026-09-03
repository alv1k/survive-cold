# Certy - Certificate Generator and Management System

Certy is a web application that allows users to easily generate and print professional certificates for events, training programs, and other occasions. The platform supports bulk certificate generation, multiple templates, and integrates with YooKassa for payments.

## Features

- **Certificate Generation**: Create custom certificates using professional templates
- **Bulk Processing**: Generate multiple certificates from a list of participants
- **Payment Integration**: Secure payments via YooKassa (supports Mir cards and SBP)
- **Subscription Management**: Different plans with varying certificate limits
- **Admin Panel**: Manage users, orders, and system analytics
- **Analytics**: Track user engagement and revenue metrics
- **Responsive Design**: Works on desktop and mobile devices

## Tech Stack

### Frontend
- React 18
- TypeScript
- Material-UI
- React Router
- Zustand (state management)
- React Hook Form

### Backend
- Node.js
- Express
- TypeScript
- PostgreSQL
- YooKassa API
- PDFKit/Puppeteer (for PDF generation)

### Infrastructure
- Docker & Docker Compose
- Nginx (reverse proxy)

## Getting Started

### Prerequisites

- Node.js (v16 or higher)
- PostgreSQL
- Python (for certificate generation)

### Installation

1. Clone the repository:
```bash
git clone <repository-url>
cd certy
```

2. Install dependencies for both client and server:
```bash
# Install server dependencies
cd server
npm install

# Install client dependencies
cd ../client
npm install
```

3. Set up environment variables:
```bash
cp .env.example .env
# Update the .env file with your configuration
```

4. Set up the database:
```bash
# Make sure PostgreSQL is running
# Create the database and run migrations (details in database/ folder)
```

5. Run the application in development mode:
```bash
# Terminal 1: Start the server
cd server
npm run dev

# Terminal 2: Start the client
cd client
npm start
```

## Environment Variables

The application requires several environment variables to work properly:

- `DB_HOST`, `DB_PORT`, `DB_NAME`, `DB_USER`, `DB_PASSWORD` - Database configuration
- `JWT_SECRET` - Secret key for JWT tokens
- `YOOKASSA_SHOP_ID`, `YOOKASSA_SECRET_KEY` - YooKassa API credentials
- `CLIENT_URL` - URL of the client application
- `GA_MEASUREMENT_ID` - Google Analytics ID (optional)

## Project Structure

```
certy/
├── client/                 # React frontend application
│   ├── src/
│   │   ├── components/    # React components
│   │   ├── pages/         # Page components
│   │   ├── hooks/         # Custom React hooks
│   │   ├── store/         # Zustand stores
│   │   ├── api/           # API integration
│   │   ├── types/         # TypeScript type definitions
│   │   └── utils/         # Utility functions
├── server/                 # Node.js Express backend
│   ├── src/
│   │   ├── controllers/   # Route controllers
│   │   ├── routes/        # API routes
│   │   ├── middleware/    # Express middleware
│   │   ├── utils/         # Utility functions
│   │   ├── config/        # Configuration files
│   │   └── types/         # TypeScript definitions
├── database/               # Database schema and migrations
├── certificates/           # Certificate templates and generator
├── docker/                 # Docker configuration
├── analytics/              # Analytics utilities
└── ...
```

## API Endpoints

### Authentication
- `POST /api/auth/register` - Register a new user
- `POST /api/auth/login` - Login a user
- `GET /api/auth/me` - Get current user info

### Certificates
- `GET /api/certificates` - Get user's certificates
- `POST /api/certificates/generate` - Generate new certificates

### Payments
- `POST /api/payment/create` - Create a payment via YooKassa
- `GET /api/payment/status/:paymentId` - Get payment status
- `POST /api/payment/refund/:paymentId` - Refund a payment

### Subscriptions
- `GET /api/subscriptions` - Get user's subscriptions
- `POST /api/subscriptions` - Create a new subscription
- `DELETE /api/subscriptions/cancel` - Cancel subscription

## Deployment

The application can be deployed using Docker:

```bash
cd docker
docker-compose up -d
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## License

This project is licensed under the MIT License.