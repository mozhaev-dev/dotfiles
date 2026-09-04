-- Bootstrap lazy.nvim so a fresh machine needs nothing but this file.
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.uv.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "--branch=stable",
    "https://github.com/folke/lazy.nvim.git",
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- Leader
vim.g.mapleader = " "

-- nvim-tree replaces the built-in netrw file browser.
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

require("lazy").setup({
  -- Colorscheme
  {
    "folke/tokyonight.nvim",
    lazy = false,
    priority = 1000,
    config = function()
      require("tokyonight").setup({
        style = "night",
        styles = {
          comments = { italic = false },
          keywords = { italic = false },
        },
      })
    end,
  },
  -- Treesitter
  {
    "nvim-treesitter/nvim-treesitter",
    branch = "main",
    build = ":TSUpdate",
    config = function()
      require("nvim-treesitter").setup()

      local parsers = {
        "bash",
        "c",
        "css",
        "html",
        "javascript",
        "json",
        "lua",
        "rust",
        "tsx",
        "typescript",
      }

      local installed = require("nvim-treesitter.config").get_installed("parsers")
      local missing = vim.tbl_filter(function(parser)
        return not vim.tbl_contains(installed, parser)
      end, parsers)
      if #missing > 0 then
        require("nvim-treesitter").install(missing)
      end

      -- This branch has no `highlight` option: highlighting starts per buffer.
      vim.api.nvim_create_autocmd("FileType", {
        callback = function(args)
          local lang = vim.treesitter.language.get_lang(vim.bo[args.buf].filetype)
          if not lang then
            return
          end
          local ok, added = pcall(vim.treesitter.language.add, lang)
          if ok and added then
            pcall(vim.treesitter.start, args.buf, lang)
          end
        end,
      })
    end,
  },
  -- LSP
  {
    "neovim/nvim-lspconfig",
    config = function()
      local capabilities = vim.lsp.protocol.make_client_capabilities()
      local ok_cmp, cmp_lsp = pcall(require, "cmp_nvim_lsp")
      if ok_cmp then
        capabilities = cmp_lsp.default_capabilities(capabilities)
      end

      local servers = {
        { name = "ts_ls", cmd = "typescript-language-server" },
        { name = "lua_ls", cmd = "lua-language-server" },
        { name = "rust_analyzer", cmd = "rust-analyzer" },
        { name = "clangd", cmd = "clangd" },
      }

      for _, server in ipairs(servers) do
        if vim.fn.executable(server.cmd) == 1 then
          vim.lsp.config(server.name, { capabilities = capabilities })
          vim.lsp.enable(server.name)
        end
      end
    end,
  },
  -- Autocomplete
  {
    "hrsh7th/nvim-cmp",
    event = "InsertEnter",
    dependencies = {
      "hrsh7th/cmp-nvim-lsp",
      "windwp/nvim-autopairs",
    },
    config = function()
      local cmp = require("cmp")
      local ok_autopairs, cmp_autopairs = pcall(require, "nvim-autopairs.completion.cmp")
      cmp.setup({
        snippet = {
          expand = function(args)
            vim.snippet.expand(args.body)
          end,
        },
        mapping = cmp.mapping.preset.insert({
          ["<C-Space>"] = cmp.mapping.complete(),
          ["<CR>"] = cmp.mapping.confirm({ select = true }),
          ["<Tab>"] = cmp.mapping.select_next_item(),
          ["<S-Tab>"] = cmp.mapping.select_prev_item(),
        }),
        sources = {
          { name = "nvim_lsp" },
        },
      })

      if ok_autopairs then
        cmp.event:on("confirm_done", cmp_autopairs.on_confirm_done())
      end
    end,
  },
  -- Auto pairs
  {
    "windwp/nvim-autopairs",
    config = function()
      require("nvim-autopairs").setup({})
    end,
  },
  -- Telescope
  {
    "nvim-telescope/telescope.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    config = function()
      local builtin = require("telescope.builtin")
      local function project_root()
        local git_root = vim.fn.systemlist("git rev-parse --show-toplevel")[1]
        if vim.v.shell_error == 0 and git_root and git_root ~= "" then
          return git_root
        end
        return vim.uv.cwd()
      end

      vim.keymap.set("n", "<leader>ff", function()
        builtin.find_files({ cwd = project_root() })
      end, { silent = true })
      vim.keymap.set("n", "<leader>fg", function()
        builtin.live_grep({ cwd = project_root() })
      end, { silent = true })
      vim.keymap.set("n", "<leader>fb", builtin.buffers, { silent = true })
      vim.keymap.set("n", "<leader>fh", builtin.help_tags, { silent = true })
    end,
  },
  -- File tree
  {
    "nvim-tree/nvim-tree.lua",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    cmd = { "NvimTreeOpen", "NvimTreeToggle" },
    keys = {
      { "<leader>e", "<cmd>NvimTreeToggle<cr>", desc = "Toggle file tree" },
    },
    opts = {
      hijack_cursor = true,
      sync_root_with_cwd = true,
      respect_buf_cwd = true,
      update_focused_file = {
        enable = true,
        update_root = true,
      },
      view = {
        width = 35,
      },
      filesystem_watchers = {
        enable = false,
      },
      renderer = {
        group_empty = true,
        highlight_git = true,
        icons = {
          show = {
            file = true,
            folder = true,
            folder_arrow = true,
            git = true,
          },
        },
      },
    },
  },
  -- Git signs in gutter
  {
    "lewis6991/gitsigns.nvim",
    config = function()
      require("gitsigns").setup({
        signs = {
          add = { text = "│" },
          change = { text = "│" },
          delete = { text = "_" },
          topdelete = { text = "‾" },
          changedelete = { text = "~" },
        },
        signcolumn = true,
      })
    end,
  },
})

-- LSP mappings
vim.api.nvim_create_autocmd("LspAttach", {
  callback = function(args)
    local opts = { buffer = args.buf, silent = true }
    vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
    vim.keymap.set("n", "gr", function()
      local ok, builtin = pcall(require, "telescope.builtin")
      if ok then
        builtin.lsp_references()
      else
        vim.lsp.buf.references()
      end
    end, opts)
    vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts)
  end,
})

-- Line numbers
vim.opt.number = true
vim.opt.relativenumber = true

-- Search
vim.opt.ignorecase = true
vim.opt.smartcase = true

-- Clipboard
vim.opt.clipboard = "unnamedplus"

-- Mouse
vim.opt.mouse = "a"

-- Line wrapping
vim.opt.wrap = false

-- Colors
vim.opt.termguicolors = true
vim.cmd("colorscheme tokyonight")

-- Layout
vim.opt.signcolumn = "yes"

-- Tabs
vim.opt.tabstop = 2
vim.opt.shiftwidth = 2
vim.opt.expandtab = true

-- Scroll
vim.opt.scrolloff = 5

-- Rust is formatted with 4 spaces, not the 2 used everywhere else here.
vim.api.nvim_create_autocmd("FileType", {
  pattern = "rust",
  callback = function()
    vim.bo.tabstop = 4
    vim.bo.shiftwidth = 4
  end,
})

-- Machine-local overrides. Loaded last so they win over everything above.
local local_config = vim.fn.stdpath("config") .. "/local.lua"
if vim.uv.fs_stat(local_config) then
  dofile(local_config)
end
