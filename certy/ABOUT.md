# About: certy

A certificate generator and management system — a full-stack web application for creating, managing, and printing professional certificates for events and training. Supports bulk generation, YooKassa payment processing, subscriptions, and an admin panel.

- **Language:** TypeScript
- **Frontend:** React 18, Material-UI (MUI), React Router, Zustand, React Hook Form, react-pdf
- **Backend:** Node.js, Express, PostgreSQL (Sequelize ORM), PDFKit, Puppeteer, JWT, YooKassa API
- **Infrastructure:** Docker Compose (PostgreSQL + Server + Client), Nginx reverse proxy
- **Database:** PostgreSQL
- **Features:**
  - PDF certificate generation (PDFKit + Puppeteer)
  - YooKassa payment integration (Mir cards, SBP)
  - Subscription management with certificate limits
  - Admin panel with analytics
  - Google Analytics integration
- **Package Manager:** npm (root + client + server separately)
- **How to Run:** `npm run build` (builds both TypeScript server and React client), `docker-compose up -d`
- **API Endpoints:** Auth, Certificates (CRUD + generate), Payments (create/status/refund), Subscriptions
- **Deployment:** Docker Compose — PostgreSQL, Node.js server (port 5000), React client (port 3000)
