# Polling Application

A full-stack polling application with a Spring Boot backend and React frontend. Users can create polls, vote on them, and see real-time results.

## 🚀 Features

- **User Authentication**: Secure JWT-based authentication
- **Poll Management**: Create, view, and manage polls
- **Real-time Voting**: Cast votes and see live results
- **Vote Visualization**: Interactive charts showing vote percentages
- **Responsive Design**: Works seamlessly on desktop and mobile
- **RESTful API**: Clean API architecture with proper separation

## 🏗️ Architecture

### Backend (Spring Boot)
- **Framework**: Spring Boot 3.2.0
- **Security**: Spring Security with JWT
- **Database**: PostgreSQL
- **ORM**: JPA/Hibernate
- **Validation**: Bean Validation
- **Java Version**: 17

### Frontend (React)
- **Framework**: React 18
- **Build Tool**: Vite
- **Routing**: React Router DOM
- **HTTP Client**: Axios
- **Styling**: Custom CSS with CSS Variables

## 📋 Prerequisites

- **Java 17** or higher
- **Maven 3.6+**
- **Node.js 16+** and npm
- **PostgreSQL 12+**

## 🛠️ Installation & Setup

### 1. Database Setup

```bash
# Start PostgreSQL
# macOS
brew services start postgresql

# Linux
sudo systemctl start postgresql

# Create database
psql -U postgres
CREATE DATABASE pollingdb;
\q
```

### 2. Backend Setup

```bash
# Navigate to project root
cd PollingApp

# Update database credentials (if needed)
# Edit src/main/resources/application.properties

# Build and run
mvn clean install
mvn spring-boot:run
```

The backend will start on `http://localhost:8080`

### 3. Frontend Setup

```bash
# Navigate to frontend directory
cd frontend

# Install dependencies
npm install

# Start development server
npm run dev
```

The frontend will start on `http://localhost:5173`

## 🔧 Configuration

### Backend Configuration

Edit `src/main/resources/application.properties`:

```properties
# Database
spring.datasource.url=jdbc:postgresql://localhost:5432/pollingdb
spring.datasource.username=postgres
spring.datasource.password=your_password

# JWT Secret (change for production!)
app.jwt.secret=your-secret-key
app.jwt.expiration=86400000
```

### Frontend Configuration

Edit `frontend/src/services/api.js`:

```javascript
const API_BASE_URL = 'http://localhost:8080/api';
```

## 📚 API Documentation

### Authentication Endpoints

| Method | Endpoint | Description | Auth Required |
|--------|----------|-------------|---------------|
| POST | `/api/auth/signup` | Register new user | No |
| POST | `/api/auth/login` | Login user | No |

### Poll Endpoints

| Method | Endpoint | Description | Auth Required |
|--------|----------|-------------|---------------|
| GET | `/api/polls/all` | Get all polls | No |
| GET | `/api/polls/{id}` | Get poll by ID | No |
| GET | `/api/polls/user` | Get user's polls | Yes |
| POST | `/api/polls` | Create new poll | Yes |

### Vote Endpoints

| Method | Endpoint | Description | Auth Required |
|--------|----------|-------------|---------------|
| POST | `/api/polls/{id}/vote` | Cast vote | Yes |

For detailed API testing instructions, see [POSTMAN_API_TESTING.md](POSTMAN_API_TESTING.md)

## 🎯 Usage

### 1. Register a User
- Navigate to `http://localhost:5173`
- Click on "Sign Up"
- Fill in the registration form
- Submit

### 2. Login
- Click on "Login"
- Enter credentials
- You'll be redirected to the polls list

### 3. Create a Poll
- Click "Create New Poll"
- Enter your question
- Add at least 2 options
- Submit

### 4. Vote on a Poll
- Click on any poll card
- Select an option
- Click "Cast Vote"

### 5. View Results
- Vote counts and percentages are displayed in real-time
- Visual bars show the distribution of votes

## 📁 Project Structure

```
PollingApp/
├── src/main/java/com/polling/          # Backend source code
│   ├── controller/                      # REST Controllers
│   ├── service/                         # Business Logic
│   ├── repository/                      # Data Access Layer
│   ├── entity/                          # JPA Entities
│   ├── dto/                             # Data Transfer Objects
│   ├── security/                        # Security & JWT
│   └── config/                          # Configuration
├── src/main/resources/
│   └── application.properties          # App configuration
├── frontend/                           # React frontend
│   ├── src/
│   │   ├── components/                # React components
│   │   ├── context/                   # React Context
│   │   ├── services/                  # API services
│   │   └── App.jsx                    # Main component
│   └── package.json                   # Frontend dependencies
├── pom.xml                            # Maven configuration
└── README.md                          # This file
```

## 🧪 Testing

### Backend Testing

```bash
# Run backend tests
mvn test

# Run with coverage
mvn test jacoco:report
```

### Frontend Testing

```bash
cd frontend

# Run tests
npm test

# Build for production
npm run build
```

## 🚢 Deployment

### Backend Deployment

```bash
# Build JAR
mvn clean package

# Run JAR
java -jar target/polling-app-1.0.0.jar
```

### Frontend Deployment

```bash
cd frontend

# Build for production
npm run build

# Files will be in dist/ directory
# Deploy to Vercel, Netlify, or any static hosting
```

## 🔐 Security Features

- **JWT Authentication**: Secure token-based authentication
- **Password Encryption**: BCrypt password hashing
- **CORS Configuration**: Configurable cross-origin requests
- **Protected Routes**: Route-level security in both frontend and backend
- **Input Validation**: Request validation at all levels

## 🐛 Troubleshooting

### Common Issues

**Database Connection Failed**
- Ensure PostgreSQL is running
- Verify database credentials in `application.properties`
- Check if database `pollingdb` exists

**CORS Errors**
- Backend already has CORS enabled for all origins
- Check if backend is running on port 8080

**Build Fails**
- Clear Maven cache: `mvn clean`
- Clear npm cache: `npm cache clean --force`
- Delete `node_modules` and reinstall: `rm -rf node_modules && npm install`

**Port Already in Use**
- Backend: Change port in `application.properties`: `server.port=8081`
- Frontend: Vite will automatically use next available port

## 📝 Environment Variables

### Backend (.env or application.properties)
```properties
SERVER_PORT=8080
DB_URL=jdbc:postgresql://localhost:5432/pollingdb
DB_USERNAME=postgres
DB_PASSWORD=your_password
JWT_SECRET=your-secret-key
JWT_EXPIRATION=86400000
```

### Frontend (.env)
```
VITE_API_BASE_URL=http://localhost:8080/api
```

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

## 📄 License

This project is licensed under the MIT License.

## 👥 Authors

- Your Name

## 🙏 Acknowledgments

- Spring Boot Team
- React Team
- Vite Team

## 📞 Support

For support, email your-email@example.com or create an issue in the repository.

---

**Happy Polling! 🗳️**
