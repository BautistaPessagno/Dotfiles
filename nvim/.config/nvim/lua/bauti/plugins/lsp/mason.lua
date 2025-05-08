return {
  "williamboman/mason.nvim",
  dependencies = {
    "neovim/nvim-lspconfig",
    { "williamboman/mason-lspconfig.nvim", enabled = false },
    "WhoIsSethDaniel/mason-tool-installer.nvim",
  },
  config = function()
    -- import mason
    local mason = require("mason")

    -- import mason-lspconfig
    -- local mason_lspconfig = require("mason-lspconfig") -- Not strictly needed if setup is removed

    local mason_tool_installer = require("mason-tool-installer")

    -- enable mason and configure icons
    mason.setup({
      ui = {
        icons = {
          package_installed = "✓",
          package_pending = "➜",
          package_uninstalled = "✗",
        },
      },
      ensure_installed = {
        --"tsserver",
        "html",
        "cssls",
        "tailwindcss",
        "svelte",
        "lua_ls",
        "graphql",
        "emmet_ls",
        "prismals",
        "pyright",
      },
    })

    -- mason_lspconfig.setup({
    --   -- list of servers for mason to install
    --   ensure_installed = {
    --     --"tsserver",
    --     "html",
    --     "cssls",
    --     "tailwindcss",
    --     "svelte",
    --     "lua_ls",
    --     "graphql",
    --     "emmet_ls",
    --     "prismals",
    --     "pyright",
    --   },
    --   automatic_installation = false, -- Prevent automatic server setup by mason-lspconfig
    -- })

    mason_tool_installer.setup({
      ensure_installed = {
        "prettier", -- prettier formatter
        "stylua", -- lua formatter
        "isort", -- python formatter
        "black", -- python formatter
        "pylint",
      },
    })
  end,
}
