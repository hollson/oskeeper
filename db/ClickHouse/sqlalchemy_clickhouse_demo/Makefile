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

# 检测是否在不支持符号链接的文件系统上运行（如VMware共享文件夹）
FS_TYPE := $(shell stat -f -c %T . 2>/dev/null)
IS_VMWARE_SHARED_FOLDER := $(if $(filter hgfs fuseblk vboxsf,$(FS_TYPE)),yes,no)

# 生成基于项目目录名的唯一虚拟环境路径，避免使用完整路径
PROJECT_DIR_NAME := sqlalchemy_clickhouse_demo
TEMP_VENV_PATH := /tmp/clickhouse_demo_venv_$(PROJECT_DIR_NAME)  # 使用项目目录名生成唯一的临时虚拟环境路径

# 对于VMware共享文件夹等不支持符号链接的文件系统，使用 --copies 参数创建虚拟环境
# 如果仍然遇到问题，则使用临时目录创建虚拟环境
ifeq ($(IS_VMWARE_SHARED_FOLDER),)  # 如果不是VMware共享文件夹
    VENV_PATH := $(VENV)  # 虚拟环境路径为本地.venv目录
    VENV_PYTHON := $(VENV)/bin/python  # 虚拟环境Python解释器路径
    VENV_PIP := $(VENV)/bin/pip  # 虚拟环境pip路径
    VENV_CREATE_ARGS :=  # 不需要特殊参数
else  # 如果是VMware共享文件夹
    VENV_PATH := $(TEMP_VENV_PATH)  # 虚拟环境路径为基于项目目录名的临时目录
    VENV_PYTHON := $(VENV_PATH)/bin/python  # 虚拟环境Python解释器路径
    VENV_PIP := $(VENV_PATH)/bin/pip  # 虚拟环境pip路径
    VENV_CREATE_ARGS := --copies  # 使用 --copies 而不是符号链接
endif

# 函数：检查是否支持创建符号链接
check-symlinks:
	@mkdir -p .test_venv 2>/dev/null || true
	@cd .test_venv && ln -s ../test_target link_test 2>/dev/null && rm -f link_test && echo "symlinks_supported=yes" || echo "symlinks_supported=no"
	@rm -rf .test_venv

.PHONY: help venv install clean run crud query batch setup check-symlinks

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
	@if [ "$(IS_VMWARE_SHARED_FOLDER)" != "" ]; then \
		echo "Detected file system that doesn't support symlinks (e.g., VMware shared folder), creating virtual environment in temporary location with --copies argument..."; \
		if [ -d "$(VENV_PATH)" ]; then \
			echo "Removing existing virtual environment at $(VENV_PATH)..."; \
			rm -rf "$(VENV_PATH)"; \
		fi; \
		if $(PYTHON) -m venv $(VENV_PATH) --copies; then \
			echo "Virtual environment created successfully in $(VENV_PATH)"; \
			if [ -d "$(VENV)" ]; then \
				rm -rf "$(VENV)"; \
			fi; \
			mkdir -p "$(VENV)/bin"; \
			echo "#!/bin/bash" > $(VENV)/bin/activate; \
			echo "export VIRTUAL_ENV=\"$(VENV_PATH)\"" >> $(VENV)/bin/activate; \
			echo "export PATH=\"$(VENV_PATH)/bin:\$$PATH\"" >> $(VENV)/bin/activate; \
			echo "export _OLD_VIRTUAL_PATH=\"\$$PATH\"" >> $(VENV)/bin/activate; \
			echo "unset PYTHONHOME" >> $(VENV)/bin/activate; \
			echo "export _OLD_VIRTUAL_PYTHONHOME=\"\$$PYTHONHOME\"" >> $(VENV)/bin/activate; \
		else \
			echo "Error: Could not create virtual environment. This is likely because the 'python3-venv' package is not installed."; \
			echo "On Debian/Ubuntu systems, please install it using:"; \
			echo "  sudo apt install python3-venv"; \
			exit 1; \
		fi; \
	else \
		$(PYTHON) -m venv $(VENV); \
	fi
	@echo "Virtual environment created in $(VENV_PATH)/"

# Install dependencies using uv or pip
install: venv
	@echo "Checking for uv availability..."
	@if command -v uv > /dev/null; then \
		echo "Using uv for dependency management..."; \
		uv pip install -r requirements.txt; \
	else \
		echo "uv not available, using pip..."; \
		if [ "yes" = "$(IS_VMWARE_SHARED_FOLDER)" ]; then \
			echo "Using temp venv location for pip upgrade..."; \
			/tmp/clickhouse_demo_venv_sqlalchemy_clickhouse_demo/bin/pip install --upgrade pip; \
			echo "Installing requirements using temp venv..."; \
			/tmp/clickhouse_demo_venv_sqlalchemy_clickhouse_demo/bin/pip install -r requirements.txt; \
		else \
			echo "Using local venv for pip upgrade..."; \
			$(VENV_PIP) install --upgrade pip; \
			echo "Installing requirements using local venv..."; \
			$(VENV_PIP) install -r requirements.txt; \
		fi; \
	fi
	@echo "Dependencies installed successfully"

# Setup project with uv if available
setup:
	@echo "Setting up project with uv if available..."
	@if command -v uv > /dev/null; then \
		echo "uv is available, setting up project..."; \
		uv pip install -r requirements.txt; \
		echo "Project setup completed with uv."; \
	else \
		echo "uv is not available, creating virtual environment and using pip..."; \
		if [ "yes" = "$(IS_VMWARE_SHARED_FOLDER)" ]; then \
			/tmp/clickhouse_demo_venv_sqlalchemy_clickhouse_demo/bin/pip install --upgrade pip; \
			/tmp/clickhouse_demo_venv_sqlalchemy_clickhouse_demo/bin/pip install -r requirements.txt; \
		else \
			$(VENV_PIP) install --upgrade pip; \
			$(VENV_PIP) install -r requirements.txt; \
		fi; \
		echo "Project setup completed with pip."; \
	fi

# Clean virtual environment
clean:
	@echo "Removing virtual environment..."
	if [ "$(IS_VMWARE_SHARED_FOLDER)" != "" ]; then \
		echo "Detected file system that doesn't support symlinks (e.g., VMware shared folder), removing virtual environment from temp location..."; \
		rm -rf "$(VENV_PATH)"; \
	fi; \
	rm -rf $(VENV)
	@echo "Virtual environment removed"

# Run the main application (auto-checks environment and installs dependencies)
run: install
	@echo "Running SQLAlchemy ClickHouse demo..."
	@if [ "yes" = "$(IS_VMWARE_SHARED_FOLDER)" ]; then \
		/tmp/clickhouse_demo_venv_sqlalchemy_clickhouse_demo/bin/python main.py; \
	else \
		$(VENV_PYTHON) main.py; \
	fi

# Run CRUD operations example
crud: install
	@echo "Running CRUD operations example..."
	@if [ "yes" = "$(IS_VMWARE_SHARED_FOLDER)" ]; then \
		/tmp/clickhouse_demo_venv_sqlalchemy_clickhouse_demo/bin/python -m examples.crud_operations; \
	else \
		$(VENV_PYTHON) -m examples.crud_operations; \
	fi

# Run query operations example
query: install
	@echo "Running query operations example..."
	@if [ "yes" = "$(IS_VMWARE_SHARED_FOLDER)" ]; then \
		/tmp/clickhouse_demo_venv_sqlalchemy_clickhouse_demo/bin/python -m examples.query_operations; \
	else \
		$(VENV_PYTHON) -m examples.query_operations; \
	fi

# Run batch operations example
batch: install
	@echo "Running batch operations example..."
	@if [ "yes" = "$(IS_VMWARE_SHARED_FOLDER)" ]; then \
		/tmp/clickhouse_demo_venv_sqlalchemy_clickhouse_demo/bin/python -m examples.batch_operations; \
	else \
		$(VENV_PYTHON) -m examples.batch_operations; \
	fi