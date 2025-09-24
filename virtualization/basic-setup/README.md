# AIROS Virtual Testing Environment

A friendly virtualization setup for testing AIROS Linux Smart Phone functionality without hardware dependencies.

## 🚀 Quick Start

```bash
# Run the setup script
./quick-start.sh
```

This will:
1. Build the Docker environment
2. Start all services
3. Launch the friendly terminal interface
4. Provide access URLs

## 🔗 Access Points

- **Web UI**: http://localhost:3000 (Friendly web interface)
- **API**: http://localhost:8080 (REST API)
- **Terminal**: `docker exec -it airos-basic-vm /usr/local/bin/airos-terminal`

## 🧪 Demo Scenarios

### 1. Web Interface
Open http://localhost:3000 and click on app icons to test:
- WhatsApp (Google Services fix)
- Spotify (Permission fix)
- Instagram (Native library fix)
- Netflix (DRM compatibility)

### 2. Terminal Interface
```bash
# Access the friendly terminal
docker exec -it airos-basic-vm /usr/local/bin/airos-terminal

# Available commands:
airos-status    # Show system status
airos-start     # Start AI agent
airos-demo      # Run demo scenarios
airos-monitor   # Monitor agent activity
```

### 3. API Testing
```bash
# Check status
curl http://localhost:8080/api/status

# Install app with auto-fix
curl -X POST http://localhost:8080/api/install_app \
  -H "Content-Type: application/json" \
  -d '{"package_name": "com.whatsapp", "auto_fix": true}'

# Run compatibility test
curl -X POST http://localhost:8080/api/demo/test_compatibility \
  -H "Content-Type: application/json" \
  -d '{"apps": ["com.whatsapp", "com.spotify.music"]}'
```

## 📁 File Structure

```
basic-setup/
├── Dockerfile              # Container definition
├── docker-compose.yml      # Service orchestration
├── quick-start.sh          # Setup script
├── config/
│   └── airos.yml           # AIROS configuration
├── scripts/
│   └── airos-terminal-commands.sh  # Terminal commands
└── web-ui/
    └── index.html          # Web interface
```

## 🤖 Virtual Features

- **Mock Waydroid**: Simulates Android container
- **AI Agent**: Virtual compatibility fixer
- **Demo Apps**: Pre-configured test scenarios
- **Real-time Logging**: See AI fixing in action
- **Performance Monitoring**: CPU, memory, disk usage

## 🛠 Management Commands

```bash
# View logs
docker-compose logs -f

# Stop environment
docker-compose down

# Restart services
docker-compose restart

# Shell access
docker exec -it airos-basic-vm bash

# Remove everything
docker-compose down --volumes --rmi all
```

## 🎯 What This Demonstrates

1. **AI-Powered Fixing**: Simulates real compatibility issue resolution
2. **User Experience**: Friendly terminal and web interfaces
3. **System Integration**: Shows how AIROS components work together
4. **Daily Driver Readiness**: Tests usability for real phone scenarios

## 🔧 Customization

Edit `config/airos.yml` to:
- Change demo apps
- Adjust logging levels
- Enable/disable features
- Modify AI behavior

## 📊 Testing Scenarios

The virtual environment includes these compatibility test cases:

- **Permission Issues**: Apps requiring additional permissions
- **Google Services**: Apps needing Play Services compatibility
- **Native Libraries**: Apps with missing .so files
- **Framework Issues**: Apps with Android version conflicts
- **Full Stack**: Complete app compatibility testing

Perfect for validating AIROS before deploying to actual OnePlus 7 Pro hardware!