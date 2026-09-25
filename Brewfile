# Version control
brew "git"
brew "lazygit"

# Terminal
brew "tmux"

# Editor
brew "neovim"
brew "tree-sitter-cli"      # nvim-treesitter builds parsers with it
brew "lua-language-server"
brew "typescript-language-server"

# Utils
brew "bat"
brew "eza"
brew "fzf"
brew "ripgrep"
brew "zoxide"

# Optional machine-local applications and toolchains.
local_file = File.expand_path("~/.config/homebrew/Brewfile.local")
instance_eval(File.read(local_file), local_file) if File.file?(local_file)
