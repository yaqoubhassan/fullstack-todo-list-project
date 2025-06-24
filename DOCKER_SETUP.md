# Docker Setup Documentation for Todo List Application

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Setup Instructions](#setup-instructions)
3. [Network and Security Configurations](#network-and-security-configurations)
4. [Environment Variables](#environment-variables)
5. [Troubleshooting Guide](#troubleshooting-guide)
6. [Container Management](#container-management)

## Prerequisites

Before setting up this application, ensure you have the following installed:

- **Docker Desktop** (version 20.10 or higher)

  - Windows: [Download Docker Desktop for Windows](https://www.docker.com/products/docker-desktop/)
  - Mac: [Download Docker Desktop for Mac](https://www.docker.com/products/docker-desktop/)
  - Linux: Install Docker Engine and Docker Compose separately

- **Git** (to clone the repository)
- **A text editor** (to modify configuration files if needed)

### Verify Installation

Open a terminal and run:

```bash
docker --version
docker-compose --version
```

## Setup Instructions

### Step 1: Clone the Repository

```bash
git clone <your-repository-url>
cd <project-directory>
```

### Step 2: Check Environment Variables

The `.env` file is already configured with default values. Review it to ensure the settings are appropriate:

```bash
cat .env
```

**Important**: For production use, change the default passwords!

### Step 3: Make Scripts Executable (Linux/Mac)

```bash
chmod +x start.sh stop.sh logs.sh test-containers.sh
```

### Step 4: Start the Application

```bash
# Using the start script
./start.sh

# Or using docker-compose directly
docker-compose up --build -d
```

### Step 5: Verify the Application is Running

Wait about 30 seconds for all services to initialize, then:

1. Open your browser and navigate to: `http://localhost`
2. You should see the Todo List application
3. Try creating a new todo to test functionality

### Step 6: Run Container Tests

```bash
./test-containers.sh
```

## Network and Security Configurations

### Network Architecture

The application uses a custom Docker bridge network (`todo-network`) with the following configuration:

- **Network Name**: todo-network
- **Subnet**: 172.20.0.0/16
- **Driver**: bridge

#### Service Communication:

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│   Frontend  │────▶│   Backend   │────▶│   MongoDB   │
│  (Port 80)  │     │ (Port 3000) │     │ (Port 27017)│
└─────────────┘     └─────────────┘     └─────────────┘
     nginx              Node.js            Database
```

### Port Mappings

| Service  | Container Port | Host Port | Purpose                  |
| -------- | -------------- | --------- | ------------------------ |
| Frontend | 80             | 80        | Web UI access            |
| Backend  | 3000           | 3000      | API access (development) |
| MongoDB  | 27017          | 27017     | Database (development)   |

### Security Configurations

#### 1. **MongoDB Security**

- Root user credentials stored in environment variables
- Application-specific user created with limited permissions
- Database initialization script runs only on first startup

#### 2. **Backend Security**

- CORS configured to accept requests only from specified origins
- Environment-based configuration for production/development
- No hardcoded credentials

#### 3. **Frontend Security**

- Nginx configured with security headers
- API requests proxied through nginx to hide backend details
- Content Security Policy headers implemented

#### 4. **Network Isolation**

- Services communicate only through the Docker network
- MongoDB is not directly accessible from outside in production
- Frontend acts as the only public-facing service

### Production Security Recommendations

1. **Change all default passwords** in the `.env` file
2. **Use Docker secrets** instead of environment variables for sensitive data
3. **Implement SSL/TLS** certificates for HTTPS
4. **Restrict port exposure** - only expose port 80/443 in production
5. **Add rate limiting** to the nginx configuration
6. **Regular security updates** for base images

## Environment Variables

### Backend Environment Variables

- `NODE_ENV`: Application environment (development/production)
- `PORT`: Backend server port (default: 3000)
- `MONGODB_URI`: MongoDB connection string
- `CORS_ORIGIN`: Allowed CORS origins

### Database Environment Variables

- `MONGO_INITDB_ROOT_USERNAME`: MongoDB root username
- `MONGO_INITDB_ROOT_PASSWORD`: MongoDB root password
- `MONGO_INITDB_DATABASE`: Initial database name
- `MONGO_APP_USERNAME`: Application database user
- `MONGO_APP_PASSWORD`: Application database password

### Frontend Environment Variables

- `REACT_APP_API_URL`: Backend API URL (set during build)

## Troubleshooting Guide

### Common Issues and Solutions

#### 1. **Port Already in Use**

**Error**: "bind: address already in use"

**Solution**:

```bash
# Find process using the port (example for port 80)
sudo lsof -i :80  # Mac/Linux
netstat -ano | findstr :80  # Windows

# Stop the process or change the port in docker-compose.yml
```

#### 2. **MongoDB Connection Failed**

**Error**: "MongoServerError: Authentication failed"

**Solution**:

```bash
# Remove existing volumes and restart
docker-compose down -v
docker-compose up --build -d
```

#### 3. **Frontend Can't Connect to Backend**

**Error**: "Failed to fetch" or CORS errors

**Solution**:

- Check if backend is running: `docker-compose ps`
- Verify CORS_ORIGIN in `.env` matches your access URL
- Check nginx proxy configuration in `Frontend/nginx.conf`

#### 4. **Container Keeps Restarting**

**Solution**:

```bash
# Check logs for specific service
docker-compose logs backend  # or frontend, mongodb

# Common fixes:
# - Check syntax errors in code
# - Verify environment variables
# - Ensure node_modules are not copied
```

#### 5. **Changes Not Reflecting**

**Solution**:

```bash
# Rebuild containers
docker-compose down
docker-compose build --no-cache
docker-compose up -d
```

#### 6. **Database Data Lost**

**Solution**:

- Data is persisted in Docker volumes
- Check if volume exists: `docker volume ls`
- Never use `docker-compose down -v` unless you want to delete data

### Debugging Commands

```bash
# View all running containers
docker-compose ps

# View logs for all services
docker-compose logs -f

# View logs for specific service
docker-compose logs -f backend

# Enter a running container
docker-compose exec backend sh
docker-compose exec mongodb mongosh

# Check container resource usage
docker stats

# Inspect network
docker network inspect todo-list_todo-network
```

## Container Management

### Starting and Stopping

```bash
# Start all services
./start.sh
# or
docker-compose up -d

# Stop all services
./stop.sh
# or
docker-compose down

# Restart a specific service
docker-compose restart backend

# Stop and remove everything (including volumes)
docker-compose down -v
```

### Monitoring

```bash
# View logs
./logs.sh
# or
docker-compose logs -f

# View logs for specific service
./logs.sh backend
```

### Updating the Application

```bash
# Pull latest code
git pull

# Rebuild and restart
docker-compose down
docker-compose build --no-cache
docker-compose up -d
```

### Backup and Restore

#### Backup MongoDB Data

```bash
# Create backup
docker-compose exec mongodb mongodump --out /backup --authenticationDatabase admin -u root -p password123

# Copy backup to host
docker cp todo-mongodb:/backup ./mongodb-backup
```

#### Restore MongoDB Data

```bash
# Copy backup to container
docker cp ./mongodb-backup todo-mongodb:/backup

# Restore backup
docker-compose exec mongodb mongorestore /backup --authenticationDatabase admin -u root -p password123
```

## Health Checks

The backend includes a health check endpoint that verifies:

- Backend API is responsive
- MongoDB connection is active
- Overall system health

Access health check at: `http://localhost:3000/`

---

**Note**: This documentation is designed for development. For production deployment, additional security measures and optimizations should be implemented.
