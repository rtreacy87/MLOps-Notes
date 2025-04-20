# 2. Azure ML Development Environment Setup

This guide covers how to set up your development environment for Azure Machine Learning, focusing on command-line tools and integrations.

## Azure ML SDK and CLI Setup

### Installing the Azure CLI

The Azure Command-Line Interface (CLI) is the foundation for interacting with Azure services.

```bash
# Linux (Ubuntu/Debian)
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

# macOS
brew update && brew install azure-cli

# Verify installation
az --version
```

### Installing the Azure ML CLI Extension

```bash
# Install the ML extension
az extension add -n ml

# Update the extension if already installed
az extension update -n ml

# Verify installation
az ml -h
```

### Setting Up the Python SDK

The Azure ML Python SDK is essential for programmatically interacting with Azure ML services. It allows you to automate workflows, manage resources, and build end-to-end ML pipelines. There are two primary methods for setting up your Python environment for Azure ML development: virtual environments and conda environments. Each has its advantages and is suitable for different scenarios.

#### Option 1: Using Python Virtual Environments

Python's built-in `venv` module provides a lightweight way to create isolated environments. This approach is ideal when you need a simple, clean environment with minimal dependencies.

```bash
# Create a virtual environment
python -m venv azureml-env

# Activate the environment
source azureml-env/bin/activate  # Linux/macOS
# or
# .\azureml-env\Scripts\activate  # Windows

# Install the Azure ML SDK
pip install azure-ai-ml azure-identity

# Install additional packages as needed
pip install pandas numpy scikit-learn matplotlib
```

#### Option 2: Using Conda Environments

Conda provides a more robust environment management system that handles complex dependencies and supports both Python and non-Python libraries. This approach is particularly valuable for ML projects with complex dependencies or when you need to share environments across a team.

```bash
# Create a conda environment
conda create -n azureml-env python=3.8

# Activate the environment
conda activate azureml-env

# Install the Azure ML SDK
pip install azure-ai-ml azure-identity

# Install additional ML packages
conda install -c conda-forge pandas numpy scikit-learn matplotlib

# For deep learning (optional)
conda install -c pytorch pytorch torchvision
# or
# conda install -c tensorflow tensorflow
```

#### Creating a Conda Environment from a YAML File

For reproducible environments, you can define your environment in a YAML file:

```bash
# Create an environment.yml file
cat > environment.yml << EOF
name: azureml-env
channels:
  - conda-forge
  - defaults
dependencies:
  - python=3.8
  - pip=21.0
  - pandas=1.3
  - numpy=1.20
  - scikit-learn=1.0
  - matplotlib=3.4
  - jupyter=1.0
  - pip:
    - azure-ai-ml==1.4.0
    - azure-identity==1.12.0
EOF

# Create the environment from the file
conda env create -f environment.yml

# Activate the environment
conda activate azureml-env
```

#### Comparing Virtual Environments and Conda Environments

| Feature | Python venv | Conda |
|---------|-------------|-------|
| **Package Management** | Python packages only | Python and non-Python packages |
| **Dependency Resolution** | Basic | Advanced (handles complex dependencies better) |
| **System Integration** | Minimal | Deep (can install system libraries) |
| **Environment Sharing** | Manual package list | YAML environment files |
| **Resource Usage** | Lightweight | More resource-intensive |
| **Setup Complexity** | Simple | More complex |
| **Cross-platform Compatibility** | Limited | Better |
| **GPU Support** | Manual setup | Built-in support for CUDA |

#### When to Choose Each Option

**Choose Python venv when:**
- You need a lightweight, simple environment
- Your project has straightforward dependencies
- You're working on a small project or prototype
- You want minimal setup overhead

**Choose Conda when:**
- Your project has complex dependencies
- You need non-Python packages (e.g., C libraries)
- You're working with deep learning frameworks
- You need to share environments across a team
- You want reproducible environments across different platforms
- You're working on a large-scale ML project

Regardless of which environment management system you choose, make sure to document your environment setup and dependencies to ensure reproducibility.

### Authenticating with Azure

```bash
# Login to Azure
az login

# Set default subscription
az account set --subscription <subscription-id>

# Verify current subscription
az account show
```

> **Security Note**: When working with Azure credentials, always follow secure practices for managing secrets. See the [Password Management and Security](security-password-management.md) wiki for detailed guidance on securely handling credentials.

### Creating a Configuration File

```bash
# Create a directory for configuration
mkdir -p ~/.azureml

# Create a config file
cat > ~/.azureml/config.json << EOF
{
    "subscription_id": "<subscription-id>",
    "resource_group": "<resource-group>",
    "workspace_name": "<workspace-name>"
}
EOF

# Set proper permissions to restrict access
chmod 600 ~/.azureml/config.json
chmod 700 ~/.azureml
```

> **Security Warning**: Configuration files often contain sensitive information. Never commit them to version control, always set restrictive file permissions, and consider using a password manager or Azure Key Vault for storing sensitive values. See the [Password Management and Security](security-password-management.md) wiki for more information.

## VS Code Integration with Azure ML

While we focus on command-line tools, VS Code provides excellent integration with Azure ML and can enhance your productivity.

### Installing VS Code

```bash
# Linux (Ubuntu/Debian)
sudo apt-get update
sudo apt-get install -y wget gpg
wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg
sudo install -D -o root -g root -m 644 packages.microsoft.gpg /etc/apt/keyrings/packages.microsoft.gpg
sudo sh -c 'echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list'
rm -f packages.microsoft.gpg
sudo apt-get update
sudo apt-get install -y code

# macOS
brew install --cask visual-studio-code
```

### Installing Azure ML Extensions for VS Code

```bash
# Install extensions from the command line
code --install-extension ms-toolsai.vscode-ai
code --install-extension ms-python.python
code --install-extension ms-azuretools.vscode-azureresourcegroups
```

### Configuring VS Code for Azure ML

VS Code provides excellent support for both virtual environments and conda environments. You can configure it to work with either type of environment for your Azure ML development.

#### For Virtual Environments

Create a `.vscode/settings.json` file in your project:

```bash
mkdir -p .vscode
cat > .vscode/settings.json << EOF
{
    "python.defaultInterpreterPath": "./azureml-env/bin/python",
    "python.linting.enabled": true,
    "python.linting.pylintEnabled": true,
    "python.formatting.provider": "black",
    "editor.formatOnSave": true,
    "azureML.defaultWorkspaceId": "/subscriptions/<subscription-id>/resourceGroups/<resource-group>/providers/Microsoft.MachineLearningServices/workspaces/<workspace-name>"
}
EOF
```

#### For Conda Environments

If you're using conda, you can configure VS Code to use your conda environment:

```bash
mkdir -p .vscode
cat > .vscode/settings.json << EOF
{
    "python.condaPath": "conda",
    "python.terminal.activateEnvironment": true,
    "python.defaultInterpreterPath": "~/miniconda3/envs/azureml-env/bin/python",
    "python.linting.enabled": true,
    "python.linting.pylintEnabled": true,
    "python.formatting.provider": "black",
    "editor.formatOnSave": true,
    "azureML.defaultWorkspaceId": "/subscriptions/<subscription-id>/resourceGroups/<resource-group>/providers/Microsoft.MachineLearningServices/workspaces/<workspace-name>"
}
EOF
```

You can also select your Python interpreter in VS Code by clicking on the Python version in the status bar and selecting your conda environment from the list.

## PyCharm Integration with Azure ML

PyCharm is a powerful Python IDE that provides excellent support for data science and ML development. It comes in two editions:

- **Community Edition**: Free and open-source with basic Python development features
- **Professional Edition**: Paid version with advanced features including scientific tools, web development, and **Azure integration**

> **Note**: Direct Azure ML integration is **only available in the Professional Edition**. If you're using the Community Edition, you'll need to use the Azure CLI or SDK through the terminal.

### Installing PyCharm

```bash
# Linux (Ubuntu/Debian)
sudo snap install pycharm-community --classic
# or for Professional Edition
# sudo snap install pycharm-professional --classic

# macOS
brew install --cask pycharm-ce
# or for Professional Edition
# brew install --cask pycharm
```

### Configuring PyCharm for Virtual Environments

1. Open PyCharm and create a new project or open an existing one
2. Go to File > Settings (or PyCharm > Preferences on macOS)
3. Navigate to Project > Python Interpreter
4. Click the gear icon and select "Add..."
5. Choose "Existing Environment" and select your virtual environment's Python interpreter:
   - For virtual environments: `~/azureml-env/bin/python` (Linux/macOS) or `C:\path\to\azureml-env\Scripts\python.exe` (Windows)
6. Click "Apply" and "OK"

### Configuring PyCharm for Conda Environments

1. Open PyCharm and create a new project or open an existing one
2. Go to File > Settings (or PyCharm > Preferences on macOS)
3. Navigate to Project > Python Interpreter
4. Click the gear icon and select "Add..."
5. Choose "Conda Environment" and select "Existing environment"
6. Browse to your conda environment's Python interpreter:
   - Linux/macOS: `~/miniconda3/envs/azureml-env/bin/python`
   - Windows: `C:\Users\username\miniconda3\envs\azureml-env\python.exe`
7. Click "Apply" and "OK"

### Azure ML Integration with PyCharm

> **Important Note**: Azure integration is **only available in PyCharm Professional Edition**. The Community Edition does not support Azure plugins or direct Azure service integration.

If you have PyCharm Professional Edition, you can install Azure plugins:

1. Go to File > Settings > Plugins
2. Search for "Azure" in the Marketplace tab
3. Install the "Azure Toolkit for IntelliJ" plugin
4. Restart PyCharm when prompted

If you're using PyCharm Community Edition, you'll need to:
- Use the Azure CLI or SDK directly from the terminal
- Manage Azure resources through the Azure portal or command line
- Consider using VS Code with Azure extensions as an alternative for Azure integration

### Setting Up Azure ML Project in PyCharm

```bash
# Create a PyCharm project configuration
mkdir -p .idea

# Create a run configuration for Azure ML scripts
cat > .idea/runConfigurations/train_model.xml << 'EOF'
<component name="ProjectRunConfigurationManager">
  <configuration default="false" name="train_model" type="PythonConfigurationType" factoryName="Python">
    <module name="your-project-name" />
    <option name="INTERPRETER_OPTIONS" value="" />
    <option name="PARENT_ENVS" value="true" />
    <envs>
      <env name="PYTHONUNBUFFERED" value="1" />
    </envs>
    <option name="SDK_HOME" value="" />
    <option name="WORKING_DIRECTORY" value="$PROJECT_DIR$" />
    <option name="IS_MODULE_SDK" value="true" />
    <option name="ADD_CONTENT_ROOTS" value="true" />
    <option name="ADD_SOURCE_ROOTS" value="true" />
    <option name="SCRIPT_NAME" value="$PROJECT_DIR$/src/models/train.py" />
    <option name="PARAMETERS" value="--data-path data/train.csv --model-output outputs/model" />
    <option name="SHOW_COMMAND_LINE" value="false" />
    <option name="EMULATE_TERMINAL" value="false" />
    <method v="2" />
  </configuration>
</component>
EOF
```

## Neovim Integration with Azure ML

Neovim is a highly extensible text editor that provides a modern experience while maintaining Vim's philosophy. It's popular among developers who prefer keyboard-driven workflows and terminal-based environments.

### Installing Neovim

```bash
# Linux (Ubuntu/Debian)
sudo apt-get install neovim

# macOS
brew install neovim

# Install Python support for Neovim
pip install pynvim
```

### Basic Neovim Configuration for Python Development

Create a basic Neovim configuration file:

```bash
# Create config directory
mkdir -p ~/.config/nvim

# Create init.vim configuration file
cat > ~/.config/nvim/init.vim << 'EOF'
" Basic settings
set number
set relativenumber
set expandtab
set tabstop=4
set shiftwidth=4
set autoindent
set smartindent
set cursorline
set showmatch
set incsearch
set hlsearch
set ignorecase
set smartcase
set termguicolors

" Python specific settings
au BufNewFile,BufRead *.py
    \ set textwidth=79 |
    \ set fileformat=unix

" Specify Python interpreter path for virtual environment
let g:python3_host_prog = expand('~/azureml-env/bin/python')
" For conda environments, use:
" let g:python3_host_prog = expand('~/miniconda3/envs/azureml-env/bin/python')
EOF
```

### Package Managers for Neovim

Neovim supports several package managers to install and manage plugins. The two most popular options are vim-plug and Lazy.nvim. Each has its own advantages and is suitable for different use cases.

#### Comparing vim-plug and Lazy.nvim

| Feature | vim-plug | Lazy.nvim |
|---------|----------|----------|
| **Language** | VimScript | Lua |
| **Performance** | Good | Excellent (lazy-loading by default) |
| **Configuration** | Simple | More complex but powerful |
| **Dependencies** | Manual management | Automatic dependency resolution |
| **Lazy Loading** | Available but manual | Built-in and automatic |
| **UI** | Minimal | Rich UI with status and operations |
| **Updates** | Manual | Automatic with lockfile |
| **Compatibility** | Works with both Vim and Neovim | Neovim-only (>= 0.8.0) |

**When to choose vim-plug:**
- You prefer simplicity and minimal configuration
- You need compatibility with both Vim and Neovim
- You're new to Vim/Neovim and want an easy starting point

**When to choose Lazy.nvim:**
- You want better performance through automatic lazy-loading
- You prefer Lua for configuration
- You need advanced features like automatic dependency management
- You're building a complex Neovim setup with many plugins

### Option 1: Installing Neovim Plugins with vim-plug

Set up vim-plug and install useful plugins for Python and Azure ML development:

```bash
# Install vim-plug plugin manager
sh -c 'curl -fLo "${XDG_DATA_HOME:-$HOME/.local/share}"/nvim/site/autoload/plug.vim --create-dirs \
       https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'

# Update Neovim configuration with plugins
cat >> ~/.config/nvim/init.vim << 'EOF'

" Plugin section
call plug#begin('~/.local/share/nvim/plugged')

" Python development
Plug 'neovim/nvim-lspconfig'           " Language Server Protocol support
Plug 'nvim-treesitter/nvim-treesitter' " Better syntax highlighting
Plug 'hrsh7th/nvim-cmp'                " Completion framework
Plug 'hrsh7th/cmp-nvim-lsp'            " LSP completion source
Plug 'hrsh7th/cmp-buffer'              " Buffer completion source
Plug 'hrsh7th/cmp-path'                " Path completion source
Plug 'hrsh7th/cmp-cmdline'             " Command line completion source
Plug 'L3MON4D3/LuaSnip'                " Snippet engine
Plug 'saadparwaiz1/cmp_luasnip'        " Snippet completion source
Plug 'dense-analysis/ale'              " Linting engine
Plug 'sbdchd/neoformat'                " Code formatter
Plug 'nvim-lua/plenary.nvim'           " Lua functions library
Plug 'nvim-telescope/telescope.nvim'   " Fuzzy finder
Plug 'nvim-tree/nvim-tree.lua'         " File explorer

" Python-specific plugins
Plug 'vim-python/python-syntax'        " Enhanced Python syntax
Plug 'Vimjas/vim-python-pep8-indent'   " PEP8 indentation
Plug 'jupyter-vim/jupyter-vim'         " Jupyter integration

" Git integration
Plug 'tpope/vim-fugitive'              " Git commands
Plug 'lewis6991/gitsigns.nvim'         " Git signs

" Theme
Plug 'folke/tokyonight.nvim'           " Tokyo Night theme

call plug#end()

" Theme configuration
colorscheme tokyonight-night

" Python linting and formatting
let g:ale_linters = {'python': ['flake8', 'pylint']}
let g:ale_fixers = {'python': ['black', 'isort']}
let g:ale_fix_on_save = 1

" LSP configuration for Python
lua << EOF
require'lspconfig'.pyright.setup{}
EOF

" Key mappings
nnoremap <space>e :NvimTreeToggle<CR>
nnoremap <space>f :Telescope find_files<CR>
nnoremap <space>g :Telescope live_grep<CR>
nnoremap <space>b :Telescope buffers<CR>
EOF
```

### Option 2: Installing Neovim Plugins with Lazy.nvim

Set up Lazy.nvim and install the same plugins with automatic lazy-loading:

```bash
# Create a Lua-based configuration for Neovim
mkdir -p ~/.config/nvim/lua/plugins

# Create the main init.lua file
cat > ~/.config/nvim/init.lua << 'EOF'
-- Basic settings
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.expandtab = true
vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.autoindent = true
vim.opt.smartindent = true
vim.opt.cursorline = true
vim.opt.showmatch = true
vim.opt.incsearch = true
vim.opt.hlsearch = true
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.termguicolors = true

-- Python specific settings
vim.api.nvim_create_autocmd({"BufNewFile", "BufRead"}, {
  pattern = "*.py",
  callback = function()
    vim.opt_local.textwidth = 79
    vim.opt_local.fileformat = "unix"
  end
})

-- Specify Python interpreter path for virtual environment
vim.g.python3_host_prog = vim.fn.expand('~/azureml-env/bin/python')
-- For conda environments, use:
-- vim.g.python3_host_prog = vim.fn.expand('~/miniconda3/envs/azureml-env/bin/python')

-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", -- latest stable release
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- Initialize lazy.nvim
require("lazy").setup("plugins")

-- Key mappings
vim.keymap.set('n', '<space>e', '<cmd>NvimTreeToggle<CR>', { noremap = true, silent = true })
vim.keymap.set('n', '<space>f', '<cmd>Telescope find_files<CR>', { noremap = true, silent = true })
vim.keymap.set('n', '<space>g', '<cmd>Telescope live_grep<CR>', { noremap = true, silent = true })
vim.keymap.set('n', '<space>b', '<cmd>Telescope buffers<CR>', { noremap = true, silent = true })
EOF

# Create the plugins specification file
cat > ~/.config/nvim/lua/plugins/init.lua << 'EOF'
return {
  -- LSP Configuration
  {
    "neovim/nvim-lspconfig",
    event = { "BufReadPre", "BufNewFile" },
    dependencies = {
      "hrsh7th/cmp-nvim-lsp",
    },
    config = function()
      require("lspconfig").pyright.setup{}
    end,
  },

  -- Treesitter for better syntax highlighting
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    event = { "BufReadPost", "BufNewFile" },
    config = function()
      require("nvim-treesitter.configs").setup {
        ensure_installed = { "python", "lua", "vim", "yaml", "json" },
        highlight = { enable = true },
      }
    end,
  },

  -- Completion framework
  {
    "hrsh7th/nvim-cmp",
    event = "InsertEnter",
    dependencies = {
      "hrsh7th/cmp-buffer",
      "hrsh7th/cmp-path",
      "hrsh7th/cmp-cmdline",
      "hrsh7th/cmp-nvim-lsp",
      "L3MON4D3/LuaSnip",
      "saadparwaiz1/cmp_luasnip",
    },
    config = function()
      local cmp = require("cmp")
      local luasnip = require("luasnip")

      cmp.setup {
        snippet = {
          expand = function(args)
            luasnip.lsp_expand(args.body)
          end,
        },
        mapping = cmp.mapping.preset.insert({
          ['<C-d>'] = cmp.mapping.scroll_docs(-4),
          ['<C-f>'] = cmp.mapping.scroll_docs(4),
          ['<C-Space>'] = cmp.mapping.complete(),
          ['<CR>'] = cmp.mapping.confirm({ select = true }),
        }),
        sources = cmp.config.sources({
          { name = 'nvim_lsp' },
          { name = 'luasnip' },
        }, {
          { name = 'buffer' },
          { name = 'path' },
        }),
      }
    end,
  },

  -- Linting and formatting
  {
    "dense-analysis/ale",
    event = { "BufReadPre", "BufNewFile" },
    config = function()
      vim.g.ale_linters = {python = {'flake8', 'pylint'}}
      vim.g.ale_fixers = {python = {'black', 'isort'}}
      vim.g.ale_fix_on_save = 1
    end,
  },

  -- Code formatter
  { "sbdchd/neoformat", cmd = "Neoformat" },

  -- Fuzzy finder
  {
    "nvim-telescope/telescope.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    cmd = "Telescope",
  },

  -- File explorer
  {
    "nvim-tree/nvim-tree.lua",
    cmd = "NvimTreeToggle",
    config = function()
      require("nvim-tree").setup()
    end,
  },

  -- Python-specific plugins
  { "vim-python/python-syntax", ft = "python" },
  { "Vimjas/vim-python-pep8-indent", ft = "python" },
  { "jupyter-vim/jupyter-vim", ft = "python" },

  -- Git integration
  { "tpope/vim-fugitive", cmd = { "Git", "Gstatus", "Gblame" } },
  {
    "lewis6991/gitsigns.nvim",
    event = { "BufReadPre", "BufNewFile" },
    config = function()
      require("gitsigns").setup()
    end,
  },

  -- Theme
  {
    "folke/tokyonight.nvim",
    lazy = false,
    priority = 1000,
    config = function()
      vim.cmd[[colorscheme tokyonight-night]]
    end,
  },
}
EOF
```

#### Installing and Updating Plugins

**With vim-plug:**
```bash
# Open Neovim
nvim

# Inside Neovim, run these commands:
# Install plugins
:PlugInstall

# Update plugins
:PlugUpdate

# Upgrade vim-plug itself
:PlugUpgrade
```

**With Lazy.nvim:**
```bash
# Open Neovim (plugins will be installed automatically on first run)
nvim

# Inside Neovim, open the Lazy UI
:Lazy

# From the UI, you can:
# - Update plugins (u)
# - Install plugins (I)
# - Clean unused plugins (X)
# - Check for plugin health (H)
```

### Setting Up Azure ML Project in Neovim

Create a project-specific configuration file:

```bash
# Create a project-specific Neovim configuration
mkdir -p .nvim
cat > .nvim/init.lua << 'EOF'
-- Project-specific Neovim configuration for Azure ML

-- Set Python path to the project's virtual environment
vim.g.python3_host_prog = vim.fn.expand('~/azureml-env/bin/python')
-- For conda: vim.g.python3_host_prog = vim.fn.expand('~/miniconda3/envs/azureml-env/bin/python')

-- Azure ML workspace configuration
local azure_config = {
  subscription_id = "<subscription-id>",
  resource_group = "<resource-group>",
  workspace_name = "<workspace-name>"
}

-- Custom commands for Azure ML workflows
vim.api.nvim_create_user_command('AzureMLRun', function()
  vim.cmd('terminal python src/models/train.py --data-path data/train.csv --model-output outputs/model')
end, {})

vim.api.nvim_create_user_command('AzureMLDeploy', function()
  vim.cmd('terminal python src/pipelines/deploy_model.py')
end, {})

-- Key mappings for Azure ML commands
vim.api.nvim_set_keymap('n', '<leader>ar', ':AzureMLRun<CR>', {noremap = true, silent = true})
vim.api.nvim_set_keymap('n', '<leader>ad', ':AzureMLDeploy<CR>', {noremap = true, silent = true})
EOF
```

To use this project configuration, start Neovim with:

```bash
nvim -u .nvim/init.lua
```

Or create an alias in your shell configuration:

```bash
alias nvim-azure="nvim -u .nvim/init.lua"
```

## Jupyter Notebooks in Azure ML

### Setting Up Jupyter Locally

Jupyter notebooks are essential for interactive ML development and experimentation. You can set up Jupyter to work with either virtual environments or conda environments.

#### Using Jupyter with Virtual Environments

```bash
# Install Jupyter in your virtual environment
pip install jupyter ipykernel

# Register your virtual environment as a kernel
python -m ipykernel install --user --name azureml --display-name "Azure ML (venv)"

# Start Jupyter
jupyter notebook
```

#### Using Jupyter with Conda Environments

Conda makes it particularly easy to work with Jupyter notebooks, as it can automatically register your environment as a kernel:

```bash
# Create a conda environment with Jupyter
conda create -n azureml-env python=3.8 jupyter ipykernel pandas numpy matplotlib

# Activate the environment
conda activate azureml-env

# Install the Azure ML SDK
pip install azure-ai-ml azure-identity

# Register the conda environment as a Jupyter kernel
python -m ipykernel install --user --name azureml-env --display-name "Azure ML (conda)"

# Start Jupyter
jupyter notebook
```

#### Managing Jupyter Kernels

```bash
# List all available Jupyter kernels
jupyter kernelspec list

# Remove a kernel
jupyter kernelspec uninstall azureml-env
```

When you open a notebook, you can select your environment from the kernel dropdown menu in the top right corner.

### Using Azure ML Compute Instances for Jupyter

```bash
# Create a compute instance
az ml compute create --name <compute-instance-name> --type computeinstance \
                     --size Standard_DS3_v2 \
                     --workspace-name <workspace-name> --resource-group <resource-group>

# List compute instances
az ml compute list --type ComputeInstance \
                   --workspace-name <workspace-name> --resource-group <resource-group>

# Start a compute instance
az ml compute start --name <compute-instance-name> \
                    --workspace-name <workspace-name> --resource-group <resource-group>

# Get the Jupyter URL
az ml compute show --name <compute-instance-name> \
                   --workspace-name <workspace-name> --resource-group <resource-group> \
                   --query "properties.jupyterLabEndpoint"
```

### Working with Notebooks from the Command Line

```bash
# Convert a Jupyter notebook to a Python script
jupyter nbconvert --to python notebook.ipynb

# Run a notebook non-interactively
jupyter nbconvert --to notebook --execute notebook.ipynb --output executed_notebook.ipynb
```

## GitHub/Azure DevOps Integration

### Setting Up Git

```bash
# Install Git
sudo apt-get install -y git  # Ubuntu/Debian
# or
brew install git  # macOS

# Configure Git
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"

# Generate SSH key
ssh-keygen -t rsa -b 4096 -C "your.email@example.com"

# Display the public key to add to GitHub/Azure DevOps
cat ~/.ssh/id_rsa.pub
```

### Cloning a Repository

```bash
# Clone a repository
git clone <repository-url>
cd <repository-directory>
```

### Setting Up Azure DevOps CLI

```bash
# Install the Azure DevOps extension
az extension add --name azure-devops

# Configure default organization and project
az devops configure --defaults organization=https://dev.azure.com/YourOrganization project=YourProject

# Login to Azure DevOps
az devops login
```

### Creating an ML Project in Azure DevOps

```bash
# Create a new Azure DevOps project
az devops project create --name MLOpsProject --description "Machine Learning Operations Project"

# Create a Git repository
az repos create --name MLOpsRepo

# Clone the repository
git clone https://dev.azure.com/YourOrganization/MLOpsProject/_git/MLOpsRepo
cd MLOpsRepo
```

### Setting Up CI/CD for ML Projects

```bash
# Create a pipeline YAML file
mkdir -p .azure-pipelines
cat > .azure-pipelines/train-deploy-pipeline.yml << 'EOF'
trigger:
  branches:
    include:
    - main
  paths:
    include:
    - models/*
    - pipelines/*

pool:
  vmImage: 'ubuntu-latest'

steps:
- task: UsePythonVersion@0
  inputs:
    versionSpec: '3.8'
    addToPath: true

- script: |
    python -m pip install --upgrade pip
    pip install azure-ai-ml azure-identity
  displayName: 'Install dependencies'

- script: |
    az login --service-principal -u $(SP_ID) -p $(SP_PASSWORD) --tenant $(TENANT_ID)
    az account set --subscription $(SUBSCRIPTION_ID)
  displayName: 'Login to Azure'

- script: |
    python pipelines/run_training_pipeline.py
  displayName: 'Run training pipeline'

- script: |
    python pipelines/deploy_model.py
  displayName: 'Deploy model'
EOF

# Add the pipeline file to Git
git add .azure-pipelines/train-deploy-pipeline.yml
git commit -m "Add CI/CD pipeline for ML workflow"
git push
```

## Project Structure for ML Development

Create a standardized project structure for your ML projects:

```bash
# Create project directories
mkdir -p src/{data,models,pipelines,utils} config notebooks tests

# Create a README
cat > README.md << 'EOF'
# Azure ML Project

This project uses Azure Machine Learning for [brief description].

## Setup

1. Clone this repository
2. Install dependencies: `pip install -r requirements.txt`
3. Configure Azure ML: Update `config/azure_config.json` with your workspace details

## Project Structure

- `src/data/`: Data processing scripts
- `src/models/`: Model training and evaluation code
- `src/pipelines/`: ML pipeline definitions
- `src/utils/`: Utility functions
- `config/`: Configuration files
- `notebooks/`: Jupyter notebooks for exploration
- `tests/`: Unit and integration tests
EOF

# Create a requirements file
cat > requirements.txt << 'EOF'
azure-ai-ml>=1.0.0
azure-identity>=1.10.0
pandas>=1.4.0
numpy>=1.22.0
scikit-learn>=1.0.0
matplotlib>=3.5.0
pytest>=7.0.0
black>=22.0.0
pylint>=2.12.0
EOF

# Create a configuration file
mkdir -p config
cat > config/azure_config.json << 'EOF'
{
    "subscription_id": "<subscription-id>",
    "resource_group": "<resource-group>",
    "workspace_name": "<workspace-name>"
}
EOF

# Create a .gitignore file
cat > .gitignore << 'EOF'
# Python
__pycache__/
*.py[cod]
*$py.class
*.so
.Python
env/
build/
develop-eggs/
dist/
downloads/
eggs/
.eggs/
lib/
lib64/
parts/
sdist/
var/
*.egg-info/
.installed.cfg
*.egg

# Virtual Environment
venv/
ENV/
azureml-env/

# Conda Environment
.conda/
miniconda/
anaconda/
.anaconda/
environment.yml

# Jupyter Notebook
.ipynb_checkpoints

# Azure ML
outputs/
.azureml/

# Security and credentials
.env
.env.*
*.pem
*.key
credentials.json
*_rsa
*_dsa
*_ed25519
*_ecdsa
secrets/
.password-store/

# VS Code
.vscode/*
!.vscode/settings.json
!.vscode/tasks.json
!.vscode/launch.json
!.vscode/extensions.json

# PyCharm
.idea/*
!.idea/runConfigurations/
*.iml
*.iws

# Neovim
.nvim/
*.swp
*.swo
*~

# Data
data/
*.csv
*.parquet
*.h5

# Logs
logs/
*.log
EOF

# Initialize Git repository
git init
git add .
git commit -m "Initial project structure"
```

## Command-Line Workflow Examples

### Training a Model

```bash
# Create a training script
mkdir -p src/models
cat > src/models/train.py << 'EOF'
import argparse
import os
import pandas as pd
import numpy as np
from sklearn.ensemble import RandomForestClassifier
from sklearn.metrics import accuracy_score
import joblib
import mlflow
import mlflow.sklearn

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--data-path", type=str, help="Path to the training data")
    parser.add_argument("--model-output", type=str, help="Path to output the model")
    parser.add_argument("--n-estimators", type=int, default=100, help="Number of estimators")
    parser.add_argument("--max-depth", type=int, default=10, help="Max depth")
    args = parser.parse_args()

    # Start MLflow run
    mlflow.start_run()

    # Log parameters
    mlflow.log_param("n_estimators", args.n_estimators)
    mlflow.log_param("max_depth", args.max_depth)

    # Read data
    data = pd.read_csv(args.data_path)
    X = data.drop("target", axis=1)
    y = data["target"]

    # Train model
    model = RandomForestClassifier(
        n_estimators=args.n_estimators,
        max_depth=args.max_depth,
        random_state=42
    )
    model.fit(X, y)

    # Evaluate model
    y_pred = model.predict(X)
    accuracy = accuracy_score(y, y_pred)
    mlflow.log_metric("accuracy", accuracy)

    # Save model
    os.makedirs(args.model_output, exist_ok=True)
    joblib.dump(model, os.path.join(args.model_output, "model.pkl"))

    # End MLflow run
    mlflow.end_run()

if __name__ == "__main__":
    main()
EOF

# Create a job submission script
cat > run_training.py << 'EOF'
from azure.identity import DefaultAzureCredential
from azure.ai.ml import MLClient, command
from azure.ai.ml.entities import Environment
from azure.ai.ml import Input, Output
import json

# Load configuration
with open("config/azure_config.json") as f:
    config = json.load(f)

# Connect to workspace
credential = DefaultAzureCredential()
ml_client = MLClient(
    credential=credential,
    subscription_id=config["subscription_id"],
    resource_group_name=config["resource_group"],
    workspace_name=config["workspace_name"]
)

# Define job
job = command(
    code="./src",
    command="python models/train.py --data-path ${{inputs.training_data}} --model-output ${{outputs.model_output}} --n-estimators 100 --max-depth 8",
    inputs={
        "training_data": Input(
            type="uri_file",
            path="azureml://datastores/workspaceblobstore/paths/data/train.csv"
        )
    },
    outputs={
        "model_output": Output(
            type="uri_folder",
            path="azureml://datastores/workspaceblobstore/paths/models/sklearn"
        )
    },
    environment="AzureML-sklearn-1.0-ubuntu20.04-py38-cpu:1",
    compute="cpu-cluster",
    display_name="train-random-forest",
    experiment_name="model-training"
)

# Submit job
returned_job = ml_client.jobs.create_or_update(job)
print(f"Job name: {returned_job.name}")
print(f"Job status: {returned_job.status}")
EOF

# Run the training job
python run_training.py
```

### Creating and Running a Pipeline

```bash
# Create a pipeline script
mkdir -p src/pipelines
cat > src/pipelines/create_pipeline.py << 'EOF'
from azure.identity import DefaultAzureCredential
from azure.ai.ml import MLClient, Input, Output, dsl, load_component
import json

# Load configuration
with open("config/azure_config.json") as f:
    config = json.load(f)

# Connect to workspace
credential = DefaultAzureCredential()
ml_client = MLClient(
    credential=credential,
    subscription_id=config["subscription_id"],
    resource_group_name=config["resource_group"],
    workspace_name=config["workspace_name"]
)

# Define pipeline
@dsl.pipeline(
    description="Training pipeline",
    compute="cpu-cluster"
)
def training_pipeline(data_path):
    # Load components
    data_prep = load_component(source="azureml://registries/azureml/components/data_prep/versions/1")
    train_model = load_component(source="azureml://registries/azureml/components/train_model/versions/1")
    evaluate_model = load_component(source="azureml://registries/azureml/components/evaluate_model/versions/1")

    # Data preparation step
    prep_step = data_prep(
        input_data=data_path
    )

    # Training step
    train_step = train_model(
        training_data=prep_step.outputs.output_data,
        n_estimators=100,
        max_depth=8
    )

    # Evaluation step
    evaluate_step = evaluate_model(
        model_input=train_step.outputs.model_output,
        test_data=prep_step.outputs.output_data
    )

    return {
        "pipeline_output": evaluate_step.outputs.evaluation_results
    }

# Create pipeline
pipeline = training_pipeline(
    data_path=Input(
        type="uri_file",
        path="azureml://datastores/workspaceblobstore/paths/data/train.csv"
    )
)

# Submit pipeline
pipeline_job = ml_client.jobs.create_or_update(
    pipeline,
    experiment_name="training-pipeline"
)

print(f"Pipeline job name: {pipeline_job.name}")
print(f"Pipeline job status: {pipeline_job.status}")
EOF

# Run the pipeline
python src/pipelines/create_pipeline.py
```

## Troubleshooting Development Environment Issues

### Authentication Issues

```bash
# Check if you're logged in
az account show

# If not logged in or token expired, login again
az login

# For service principal authentication issues
az login --service-principal -u <client-id> -p <client-secret> --tenant <tenant-id>
```

### Azure ML SDK Issues

```bash
# Check SDK version
pip show azure-ai-ml

# Update SDK
pip install --upgrade azure-ai-ml

# Clear Azure ML CLI extension cache
az extension remove -n ml
az extension add -n ml
```

### Compute Issues

```bash
# Check compute status
az ml compute list --workspace-name <workspace-name> --resource-group <resource-group>

# Restart a compute instance
az ml compute restart --name <compute-instance-name> \
                      --workspace-name <workspace-name> --resource-group <resource-group>

# Create a new compute cluster if needed
az ml compute create --name cpu-cluster --type amlcompute --min-nodes 0 --max-nodes 4 \
                     --workspace-name <workspace-name> --resource-group <resource-group>
```

## Next Steps

After setting up your development environment:

1. Explore [Azure ML Fundamentals](azure-ml-fundamentals.md) to understand the core concepts
2. Learn about [Data Management in Azure](data-management.md) to work with your datasets
3. Proceed to [Model Development](model-development.md) to start training models
