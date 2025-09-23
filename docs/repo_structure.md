# AIROS Repository Structure

## Complete GitHub Repository Organization

```
airos/
├── README.md                              # Main project documentation
├── LICENSE                                # GPLv3 license
├── CONTRIBUTING.md                        # Contribution guidelines
├── CHANGELOG.md                          # Version history
├── CODE_OF_CONDUCT.md                   # Community standards
├── .github/
│   ├── workflows/
│   │   ├── test.yml                     # CI/CD pipeline
│   │   ├── release.yml                  # Release automation
│   │   └── docker-publish.yml           # Container publishing
│   ├── ISSUE_TEMPLATE/
│   │   ├── bug_report.md                # Bug report template
│   │   ├── feature_request.md           # Feature request template
│   │   └── device_support.md            # New device request
│   └── PULL_REQUEST_TEMPLATE.md         # PR template
│
├── docs/                                 # Documentation
│   ├── GETTING_STARTED.md              # Quick start guide
│   ├── ARCHITECTURE.md                 # System design
│   ├── API_REFERENCE.md                # API documentation
│   ├── CONTRIBUTING.md                 # How to contribute
│   ├── FAQ.md                          # Frequently asked questions
│   └── WORKFLOW.md                     # Development workflow
│
├── install/                             # Installation guides
│   ├── DEVICE_SUPPORT.md               # Supported devices matrix
│   ├── REQUIREMENTS.md                 # System requirements
│   ├── UBUNTU_TOUCH_GUIDE.md           # Ubuntu Touch installation
│   ├── POSTMARKETOS_GUIDE.md           # PostmarketOS installation
│   ├── DROIDIAN_GUIDE.md               # Droidian installation
│   ├── ANDROID_ROM_GUIDE.md            # Android ROM building
│   └── scripts/
│       ├── install.sh                  # Universal installer
│       ├── check-device.sh             # Device compatibility checker
│       └── backup-device.sh            # Backup helper
│
├── devices/                             # Device-specific guides
│   ├── template/                       # Template for new devices
│   │   ├── README.md
│   │   ├── install.sh
│   │   └── config.yml
│   ├── oneplus-7-pro/
│   │   ├── README.md                   # Complete guide
│   │   ├── install.sh                  # Device-specific installer
│   │   ├── config.yml                  # Device configuration
│   │   ├── known-issues.md             # Known problems
│   │   └── logs/                       # Installation logs
│   ├── pixel-4a-5g/
│   ├── pinephone/
│   └── [other-devices]/
│
├── virtualization/                      # Virtual testing
│   ├── VIRTUALIZATION_GUIDE.md         # Main guide
│   ├── docker/
│   │   ├── Dockerfile                  # AIROS container
│   │   ├── docker-compose.yml          # Full stack
│   │   └── README.md                   # Docker instructions
│   ├── qemu/
│   │   ├── run-vm.sh                   # QEMU launcher
│   │   ├── create-image.sh             # Image builder
│   │   └── configs/                    # VM configurations
│   ├── vagrant/
│   │   ├── Vagrantfile                 # Vagrant setup
│   │   └── provision.sh                # Provisioning script
│   └── waydroid/
│       ├── setup-desktop.sh            # Desktop Waydroid setup
│       └── config.ini                  # Waydroid config
│
├── src/                                 # Source code
│   ├── airos-agent/                    # AI agent service
│   │   ├── airos_agent.py              # Main service
│   │   ├── requirements.txt            # Python dependencies
│   │   └── tests/                      # Unit tests
│   ├── compatibility-fixer/            # App fixing system
│   │   ├── fixer.py                    # Main fixer
│   │   ├── fixes/                      # Fix database
│   │   └── tests/
│   ├── android-rom/                    # Android ROM code
│   │   ├── AIAgentService.java         # Android service
│   │   ├── Android.mk                  # Build config
│   │   └── AndroidManifest.xml         # Manifest
│   └── installation-scripts/           # Setup scripts
│       ├── install-airos.sh            # Main installer
│       ├── install-microg.sh           # MicroG installer
│       └── install-aurora.sh           # Aurora Store installer
│
├── community/                           # Community contributions
│   ├── SUCCESS_STORIES.md              # Installation successes
│   ├── APP_COMPATIBILITY.md            # App compatibility list
│   ├── TROUBLESHOOTING.md              # Common problems/solutions
│   ├── logs/                            # Installation logs
│   │   ├── template.md                 # Log template
│   │   └── [user-logs]/               # Actual logs
│   ├── fixes/                          # Community app fixes
│   │   ├── whatsapp.fix               # WhatsApp fixes
│   │   ├── banking/                    # Banking app fixes
│   │   └── [app-fixes]/               # Other app fixes
│   └── translations/                   # Localization
│       ├── README.es.md
│       ├── README.zh.md
│       └── [languages]/
│
├── tests/                               # Test suites
│   ├── unit/                           # Unit tests
│   ├── integration/                    # Integration tests
│   ├── e2e/                           # End-to-end tests
│   └── benchmarks/                     # Performance tests
│
├── tools/                               # Development tools
│   ├── claude-assistant.py             # AI installation helper
│   ├── log-analyzer.py                 # Log analysis tool
│   ├── fix-generator.py                # Fix creation tool
│   └── device-profiler.py              # Device profiling
│
├── releases/                            # Release artifacts
│   ├── latest/                         # Latest stable
│   ├── beta/                           # Beta releases
│   └── archive/                        # Old versions
│
├── assets/                              # Media assets
│   ├── images/                         # Screenshots, diagrams
│   ├── videos/                         # Demo videos
│   └── logos/                          # Project logos
│
├── config/                              # Configuration files
│   ├── default.yml                     # Default config
│   ├── docker.yml                      # Docker config
│   └── ci.yml                          # CI config
│
├── scripts/                             # Utility scripts
│   ├── setup-dev.sh                    # Developer setup
│   ├── run-tests.sh                    # Test runner
│   ├── build-release.sh                # Release builder
│   └── update-docs.sh                  # Doc generator
│
├── .gitignore                           # Git ignore rules
├── .dockerignore                        # Docker ignore rules
├── requirements.txt                     # Python dependencies
├── requirements-dev.txt                 # Dev dependencies
├── package.json                         # Node dependencies (if any)
├── Makefile                            # Build automation
└── docker-compose.yml                   # Docker orchestration
```

## File Naming Conventions

### Documentation
- `UPPERCASE.md` - Major documentation files
- `lowercase-with-dashes.md` - Sub-documentation
- `device-name/` - Device-specific folders

### Code
- `snake_case.py` - Python files
- `PascalCase.java` - Java files
- `kebab-case.sh` - Shell scripts
- `lowercase.yml` - Configuration files

### Logs
- `YYYY-MM-DD-device-os.md` - Installation logs
- `username-device-attempt-N.md` - User logs

## Branch Structure

```
main                    # Stable releases
├── develop            # Development branch
├── feature/*          # New features
├── fix/*             # Bug fixes
├── device/*          # Device-specific work
├── release/*         # Release preparation
└── hotfix/*          # Emergency fixes
```

## Version Tags

```
v0.1.0-alpha          # Initial alpha
v0.2.0-beta           # Beta release
v1.0.0                # First stable
v1.0.1                # Patch release
v1.1.0                # Minor release
v2.0.0                # Major release
```

## Required Files for New Device Support

When adding a new device, create these files:

```
devices/[device-name]/
├── README.md                    # Complete installation guide
├── install.sh                   # Automated installer
├── config.yml                   # Device configuration
├── known-issues.md             # Current problems
├── hardware-support.md         # Feature matrix
├── performance.md              # Benchmarks
├── recovery.md                 # Recovery instructions
└── logs/
    └── .gitkeep                # Keep empty folder
```

## Documentation Standards

### README Template
```markdown
# Device Name - AIROS Installation

## Overview
[Brief description]

## Quick Start
[One-liner installation]

## Compatibility
[Feature matrix]

## Installation
[Step-by-step guide]

## Troubleshooting
[Common issues]

## Resources
[Links and references]
```

### Log Template
```markdown
# Installation Log - [Device] - [Date]

## System Info
- Device: 
- Previous OS:
- Computer OS:
- AIROS Version:

## Installation Steps
[Detailed steps with timestamps]

## Issues Encountered
[Problems and solutions]

## Final Status
[Success/Partial/Failed]

## Notes
[Additional observations]
```

## Continuous Integration Files

### `.github/workflows/test.yml`
```yaml
name: Test Suite
on: [push, pull_request]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - run: make test
```

### `Makefile`
```makefile
.PHONY: help build test clean

help:
	@echo "Available commands:"
	@echo "  make build    - Build project"
	@echo "  make test     - Run tests"
	@echo "  make clean    - Clean artifacts"

build:
	docker build -t airos .

test:
	pytest tests/
	./scripts/run-tests.sh

clean:
	rm -rf build/ dist/
```

## Contributing Guidelines

### Adding New Features
1. Create feature branch from `develop`
2. Add tests for new code
3. Update documentation
4. Submit PR to `develop`

### Reporting Bugs
1. Check existing issues
2. Use bug report template
3. Include logs and system info
4. Provide reproduction steps

### Device Support
1. Test thoroughly on device
2. Document all features
3. Submit installation log
4. Create device-specific folder

## License Headers

All source files should include:

```python
# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (C) 2024 AIROS Contributors
```

---

<p align="center">
  <b>Organized for collaboration 🤝</b>
  <br>
  <sub>Clear structure enables contribution</sub>
</p>