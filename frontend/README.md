# Polling App - React Frontend

A modern React frontend application for the Polling App built with Vite, React Router, and Axios.

## Features

- **User Authentication**: Login and signup functionality with JWT token management
- **Poll Management**: View all polls, create new polls, and see poll details
- **Voting System**: Cast votes on polls with real-time vote count visualization
- **Responsive Design**: Mobile-friendly UI with modern styling
- **Protected Routes**: Secure routes that require authentication

## Tech Stack

- **React 18**: Modern React with hooks
- **Vite**: Fast build tool and dev server
- **React Router DOM**: Client-side routing
- **Axios**: HTTP client for API requests
- **CSS3**: Custom styling with CSS variables

## Prerequisites

- Node.js (v16 or higher)
- npm or yarn
- Backend API running on http://localhost:8080

## Installation

1. Navigate to the frontend directory:
```bash
cd frontend
```

2. Install dependencies:
```bash
npm install
```

## Running the Application

1. Make sure the backend Spring Boot application is running on port 8080

2. Start the development server:
```bash
npm run dev
```

3. Open your browser and navigate to:
```
http://localhost:5173
```

## Available Scripts

- `npm run dev` - Start development server
- `npm run build` - Build for production
- `npm run preview` - Preview production build locally
- `npm run lint` - Run ESLint

## Project Structure

```
frontend/
├── src/
│   ├── components/          # React components
│   │   ├── Login.jsx       # Login page
│   │   ├── Signup.jsx      # Signup page
│   │   ├── Navbar.jsx      # Navigation bar
│   │   ├── PollList.jsx    # List of all polls
│   │   ├── PollDetail.jsx  # Poll detail with voting
│   │   ├── CreatePoll.jsx  # Create new poll form
│   │   └── ProtectedRoute.jsx  # Route protection
│   ├── context/            # React Context
│   │   └── AuthContext.jsx # Authentication context
│   ├── services/           # API services
│   │   └── api.js         # Axios configuration and API calls
│   ├── App.jsx            # Main App component
│   ├── App.css            # Application styles
│   ├── main.jsx           # Entry point
│   └── index.css          # Global styles
├── public/                # Static assets
├── index.html            # HTML template
├── vite.config.js       # Vite configuration
└── package.json         # Dependencies and scripts
```

## API Integration

The frontend connects to the backend API with the following endpoints:

### Authentication
- `POST /api/auth/login` - User login
- `POST /api/auth/signup` - User registration

### Polls
- `GET /api/polls/all` - Get all polls (public)
- `GET /api/polls/{id}` - Get poll by ID (public)
- `GET /api/polls/user` - Get user's polls (protected)
- `POST /api/polls` - Create new poll (protected)
- `POST /api/polls/{id}/vote` - Vote on a poll (protected)

## Features Overview

### Authentication
- JWT-based authentication
- Token stored in localStorage
- Automatic token injection in API requests
- Protected routes with redirect to login

### Poll Features
- View all available polls
- Create new polls with multiple options
- Vote on polls (requires login)
- Real-time vote count visualization with percentage bars
- See expired polls

### User Experience
- Responsive design for mobile and desktop
- Loading states for async operations
- Error handling with user-friendly messages
- Success notifications

## Environment Configuration

The API base URL is configured in `src/services/api.js`:

```javascript
const API_BASE_URL = 'http://localhost:8080/api';
```

To change the backend URL, modify this constant.

## Building for Production

1. Build the application:
```bash
npm run build
```

2. The built files will be in the `dist/` directory

3. Preview the production build:
```bash
npm run preview
```

## Deployment

The built application can be deployed to:
- Vercel
- Netlify
- AWS S3 + CloudFront
- Any static hosting service

Make sure to update the API base URL for production deployment.

## Troubleshooting

### CORS Issues
If you encounter CORS errors, make sure the backend has CORS enabled for the frontend origin.

### API Connection
Ensure the backend is running on the correct port (8080 by default).

### Authentication Issues
Clear localStorage and try logging in again if you face authentication issues.

## License

This project is part of the Polling App application.
