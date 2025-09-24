FROM ubuntu:22.04

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive
ENV AIROS_VERSION=0.1.0-alpha
ENV PYTHONUNBUFFERED=1

# Update and install base dependencies
RUN apt-get update && apt-get install -y \
    python3 \
    python3-pip \
    python3-venv \
    git \
    curl \
    wget \
    build-essential \
    pkg-config \
    sqlite3 \
    software-properties-common \
    gpg-agent \
    ca-certificates \
    sudo \
    vim \
    nano \
    htop \
    tree \
    figlet \
    lolcat \
    && rm -rf /var/lib/apt/lists/*

# Install Python dependencies
RUN pip3 install --no-cache-dir \
    aiohttp \
    psutil \
    PyYAML \
    watchdog \
    rich \
    typer \
    asyncio \
    websockets

# Create airos user
RUN useradd -m -s /bin/bash airos && \
    echo "airos ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Create AIROS directories
RUN mkdir -p /opt/airos \
    /var/lib/airos \
    /etc/airos \
    /var/log/airos

# Copy AIROS source code
WORKDIR /opt/airos
COPY src/ ./src/
COPY config/ ./config/

# Create friendly terminal setup
RUN echo '#!/bin/bash' > /usr/local/bin/airos-terminal && \
    echo 'clear' >> /usr/local/bin/airos-terminal && \
    echo 'figlet -c "AIROS Linux" | lolcat' >> /usr/local/bin/airos-terminal && \
    echo 'echo -e "\n🚀 Welcome to AIROS Linux Smart Phone Platform"' >> /usr/local/bin/airos-terminal && \
    echo 'echo -e "📱 Virtual Testing Environment"' >> /usr/local/bin/airos-terminal && \
    echo 'echo -e "🤖 AI Agent Ready\n"' >> /usr/local/bin/airos-terminal && \
    echo 'echo "Available commands:"' >> /usr/local/bin/airos-terminal && \
    echo 'echo "  airos-status    - Show system status"' >> /usr/local/bin/airos-terminal && \
    echo 'echo "  airos-start     - Start AI agent"' >> /usr/local/bin/airos-terminal && \
    echo 'echo "  airos-monitor   - Monitor agent activity"' >> /usr/local/bin/airos-terminal && \
    echo 'echo "  airos-demo      - Run demo scenarios"' >> /usr/local/bin/airos-terminal && \
    echo 'echo ""' >> /usr/local/bin/airos-terminal && \
    echo 'bash' >> /usr/local/bin/airos-terminal && \
    chmod +x /usr/local/bin/airos-terminal

# Set up bash customization
RUN echo 'export PS1="\[\033[38;5;39m\]airos@\h\[\033[0m\]:\[\033[38;5;118m\]\w\[\033[0m\]$ "' >> /home/airos/.bashrc && \
    echo 'alias ll="ls -la"' >> /home/airos/.bashrc && \
    echo 'alias airos-logs="tail -f /var/log/airos/agent.log"' >> /home/airos/.bashrc && \
    echo 'echo "🤖 AIROS Agent ready - type airos-start to begin"' >> /home/airos/.bashrc

# Set ownership
RUN chown -R airos:airos /opt/airos /var/lib/airos /var/log/airos /home/airos

# Switch to airos user
USER airos

# Set working directory
WORKDIR /home/airos

# Expose ports
EXPOSE 8080 8081

# Start friendly terminal by default
CMD ["/usr/local/bin/airos-terminal"]