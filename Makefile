# -----------------------------------------------------------------------------
# Makefile for Environment Setup, Running Scripts, and Cleaning Up
#
# This Makefile provides targets for creating a Python virtual environment (venv), installing
# system dependencies, running various Python scripts, creating videos,
# and cleaning build files, caches, and GPU memory.
# -----------------------------------------------------------------------------

.PHONY: help create_env apt_deps run train ai analysis video gif traj multtraj compare build clean_gpu clean

.DEFAULT_GOAL := help

# -----------------------------------------------------------------------------
# Variables
# -----------------------------------------------------------------------------
VENV_DIR       := ./.venv
REQUIREMENTS   := requirements.txt
PYTHON_SYS     := python3.12
VENV_BIN       := $(VENV_DIR)/bin
PYTHON         := $(VENV_BIN)/python -u

# Raiz do projeto no PYTHONPATH (necessário para `from tools.utils import ...`)
export PYTHONPATH := $(CURDIR)$(if $(PYTHONPATH),:$(PYTHONPATH))

# -----------------------------------------------------------------------------
# Target: create_env
# Creates a Python 3.12 virtual environment (venv) and installs dependencies.
# -----------------------------------------------------------------------------
create_env: ## Cria o venv (.venv) com Python 3.12 e instala o requirements.txt
	@echo "Creating virtual environment in $(VENV_DIR)..."
	$(PYTHON_SYS) -m venv $(VENV_DIR)
	@echo "Installing dependencies..."
	$(VENV_BIN)/pip install --upgrade pip
	$(VENV_BIN)/pip install -r $(REQUIREMENTS)
	@echo "Done. Activate with: source $(VENV_BIN)/activate"

# -----------------------------------------------------------------------------
# Target: apt_deps
# Installs system dependencies (poppler-utils, ffmpeg, libavcodec-extra, graphviz, etc.).
# -----------------------------------------------------------------------------
apt_deps: ## Instala dependências de sistema via apt (requer sudo)
	@echo "Installing system dependencies..."
	sudo apt-get update && sudo apt-get install -y cmake libopenmpi-dev python3-dev python3.12-dev python3.12-venv zlib1g-dev libgl1-mesa-dri mesa-utils ccache

# -----------------------------------------------------------------------------
# Target: run
# Runs the main script of the project.
# -----------------------------------------------------------------------------
run: ## Simulação com o comportamento heurístico (baseline do TG)
	@echo "Running the main script..."
	$(PYTHON) ./src/planning/main.py


# -----------------------------------------------------------------------------
# -----------------------------------------------------------------------------
train: ## Treina o modelo de Behavior Cloning (CNN)
	@echo "Running the train script..."
	$(PYTHON) ./src/imitation_learning/train.py


# -----------------------------------------------------------------------------
# Target: beahvior cloning
# Runs the behavior cloning script.
# -----------------------------------------------------------------------------
ai: ## Simulação com o comportamento BC / coleta de demonstrações via joystick
	@echo "Running the behavior clone script..."
	$(PYTHON) ./src/imitation_learning/main.py

# -----------------------------------------------------------------------------
# Target: analysis
# Runs the analysis script.
# -----------------------------------------------------------------------------
analysis: ## Roda os episódios de avaliação e salva CSV em analysis/data/
	@echo "Running the analysis script..."
	$(PYTHON) ./analysis/main.py
# -----------------------------------------------------------------------------
# Target: video
# Runs the video creation script.
# -----------------------------------------------------------------------------
video: ## Gera vídeo a partir dos frames salvos
	@echo "Running the video creation script..."
	$(PYTHON) ./tools/create_video.py

# -----------------------------------------------------------------------------
# Target: gif
# Runs the gif creation script.
# -----------------------------------------------------------------------------
gif: ## Gera GIF recortado a partir de um vídeo
	@echo "Running the video creation script..."
	$(PYTHON) ./tools/create_gif.py

# -----------------------------------------------------------------------------
# Target: traj
# Runs the enemy behavior visualization script.
# -----------------------------------------------------------------------------
traj: ## Visualiza a trajetória de um inimigo
	@echo "Running the enemy behavior visualization script..."
	$(PYTHON) ./tools/view_enemy_behavior.py

# -----------------------------------------------------------------------------
# Target: multtraj
# Runs the multi enemy behavior visualization script.
# -----------------------------------------------------------------------------
multtraj: ## Visualiza trajetórias de múltiplos inimigos
	@echo "Running the multi enemy behavior visualization script..."
	$(PYTHON) ./tools/view_multi_enemy_behavior.py

# -----------------------------------------------------------------------------
# Target: compare
# Runs the script to compare different behaviors.
# -----------------------------------------------------------------------------
compare: ## Importa tools/compare.py (só define funções; a análise fica em analysis/compare.ipynb)
	@echo "Running the behavior comparison script..."
	$(PYTHON) ./tools/compare.py

# -----------------------------------------------------------------------------
# Target: sandbox
# Runs the sandbox script.
# -----------------------------------------------------------------------------
build: ## Compila módulos Cython (requer setup.py)
	@echo "Compilando módulos Cython selecionados..."
	$(VENV_BIN)/python setup.py build_ext


# -----------------------------------------------------------------------------
# Target: clean_gpu
# Cleans GPU memory by terminating running processes using nvidia-smi.
# -----------------------------------------------------------------------------
clean_gpu: ## Mata processos que estão usando a GPU (nvidia-smi)
	@echo "Cleaning GPU memory..."
	@for pid in $$(nvidia-smi --query-compute-apps=pid --format=csv,noheader,nounits); do \
		if [ "$$pid" != "No running processes found" ]; then \
			echo "Killing process $$pid"; \
			kill -9 $$pid || true; \
		fi; \
	done; \
	echo "GPU memory cleaned!"

# -----------------------------------------------------------------------------
# Target: clean
# Cleans generated files and caches.
# -----------------------------------------------------------------------------
clean: ## Remove o .venv e caches do Python
	@echo "Cleaning build files and caches..."
	rm -rf $(VENV_DIR) ./.pytest_cache
	find . -type f -name '*.py[co]' -delete
	find . -type d -name "__pycache__" | xargs rm -rf
	@echo "Clean complete."


# -----------------------------------------------------------------------------
# Target: help
# Displays this help message.
# -----------------------------------------------------------------------------
help: ## Mostra esta ajuda
	@echo "Uso: make <alvo>"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-12s\033[0m %s\n", $$1, $$2}'
