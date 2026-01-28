# Frappe LMS Local Setup Guide

This guide explains how to run the Frappe LMS application locally using Docker.

## Prerequisites

1. **Docker Desktop** must be installed and running on your system
2. **Git** (if you need to clone the repository)

## Step-by-Step Setup Process

### 1. Ensure Docker is Running

- Start Docker Desktop application
- Verify Docker is working: `docker --version`
- Verify Docker Compose is available: `docker-compose --version`

### 2. Navigate to the Docker Directory

```bash
cd "path\to\lms\docker"
```

### 3. Fix Line Endings (Windows-specific issue)

The `init.sh` script may have Windows line endings that cause issues in the Linux container. Fix this using PowerShell:

```powershell
(Get-Content "init.sh" -Raw) -replace "`r`n", "`n" | Set-Content "init.sh" -NoNewline
```

### 4. Start the Application

```bash
docker-compose up -d
```

This command:

- Downloads required Docker images (MariaDB, Redis, Frappe/Bench)
- Creates and starts 3 containers: `mariadb`, `redis`, and `frappe`
- Runs the setup in the background (`-d` flag)

### 5. Monitor the Setup Process

Check the setup progress with:

```bash
docker-compose logs frappe --follow
```

The setup process includes:

- Creating Python virtual environment
- Installing Frappe framework
- Installing LMS application
- Building assets (JavaScript/CSS)
- Creating database site
- Installing LMS app to the site
- Starting all services

### 6. Verify Everything is Running

```bash
docker-compose ps
```

You should see 3 running containers with ports exposed:

- `lms-frappe-1` on ports 8000 and 9000
- `lms-mariadb-1`
- `lms-redis-1`

## Access the Application

- **Main Application**: <http://localhost:8000/>
- **LMS Portal**: <http://localhost:8000/lms>
- **Admin Credentials**:
  - Username: `Administrator`
  - Password: `admin`

## Container Services

The Frappe container runs multiple services:

- **Web server** (port 8000) - Main application
- **SocketIO** (port 9000) - Real-time features  
- **Background worker** - Handles queued tasks
- **Scheduler** - Handles scheduled tasks

## Managing the Application

### Stopping the Application

```bash
docker-compose down
```

### Complete Reset (if needed)

```bash
docker-compose down --volumes
docker-compose up -d
```

### View Logs

```bash
# View all logs
docker-compose logs

# View specific service logs
docker-compose logs frappe
docker-compose logs mariadb
docker-compose logs redis

# Follow logs in real-time
docker-compose logs -f frappe
```

## Troubleshooting

### Common Issues

1. **Docker Desktop not running**: Ensure Docker Desktop is started and running
2. **Port conflicts**: Make sure ports 8000 and 9000 are not used by other applications
3. **Line ending issues**: Run the PowerShell command from step 3 if you encounter script errors
4. **Slow setup**: First-time setup takes 5-10 minutes as it downloads and builds everything

### Checking Container Status

```bash
# Check if containers are running
docker-compose ps

# Check container health
docker-compose logs frappe --tail=20
```

## Development Notes

- The application runs in **developer mode** by default
- Code changes in the LMS directory will be reflected in the running container
- The database persists between container restarts
- Assets are built automatically during setup

## Setup Time

This process takes approximately **5-10 minutes** on the first run as it downloads images and sets up the complete environment.
