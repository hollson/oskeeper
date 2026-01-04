# Makefile for SQLAlchemy ClickHouse Demo Project

# Default Python interpreter
PYTHON := python3

# Check if uv is available, otherwise fall back to pip
UV_AVAILABLE := $(shell command -v uv 2> /dev/null)

ifeq ($(UV_AVAILABLE),)
    PIP_CMD := $(PYTHON) -m pip
    INSTALL_CMD := $(PIP_CMD) install
else
    PIP_CMD := uv pip
    INSTALL_CMD := uv pip install
endif

# Virtual environment directory
VENV := .venv
VENV_PYTHON := $(VENV)/bin/python
VENV_PIP := $(VENV)/bin/pip

.PHONY: help venv install clean run crud query batch setup

# Show help message
help:
	@echo "SQLAlchemy ClickHouse Demo Project Makefile"
	@echo ""
	@echo "Usage:"
	@echo "  make help         - Show this help message"
	@echo "  make setup        - Setup project with uv if available, otherwise pip"
	@echo "  make run          - Run the main application"
	@echo "  make crud         - Run CRUD operations example"
	@echo "  make query        - Run query operations example"
	@echo "  make batch        - Run batch operations example"
	@echo "  make clean        - Remove virtual environment"
	@echo ""

# Create virtual environment
venv:
	@echo "Creating virtual environment..."
	$(PYTHON) -m venv $(VENV)
	@echo "Virtual environment created in $(VENV)/"

# Install dependencies using uv or pip
install: venv
	@echo "Checking for uv availability..."
	@if command -v uv > /dev/null; then \
		echo "Using uv for dependency management..."; \
		$(VENV_PYTHON) -m pip install --upgrade pip; \
		uv venv $(VENV) --seed; \
		uv pip install -r requirements.txt; \
	else \
		echo "uv not available, using pip..."; \
		$(VENV_PIP) install --upgrade pip; \
		$(VENV_PIP) install -r requirements.txt; \
	fi
	@echo "Dependencies installed successfully"

# Setup project with uv if available
setup:
	@echo "Setting up project with uv if available..."
	@if command -v uv > /dev/null; then \
		echo "uv is available, setting up project..."; \
		uv venv $(VENV) --seed; \
		uv pip install -r requirements.txt; \
		echo "Project setup completed with uv."; \
	else \
		echo "uv is not available, creating virtual environment and using pip..."; \
		$(PYTHON) -m venv $(VENV); \
		$(VENV_PYTHON) -m pip install --upgrade pip; \
		$(VENV_PIP) install -r requirements.txt; \
		echo "Project setup completed with pip."; \
	fi

# Clean virtual environment
clean:
	@echo "Removing virtual environment..."
	rm -rf $(VENV)
	@echo "Virtual environment removed"

# Run the main application (auto-checks environment and installs dependencies)
run: install
	@echo "Running SQLAlchemy ClickHouse demo..."
	$(VENV_PYTHON) main.py

# Run CRUD operations example
crud: install
	@echo "Running CRUD operations example..."
	$(VENV_PYTHON) -m examples.crud_operations

# Run query operations example
query: install
	@echo "Running query operations example..."
	$(VENV_PYTHON) -m examples.query_operations

# Run batch operations example
batch: install
	@echo "Running batch operations example..."
	$(VENV_PYTHON) -m examples.batch_operations