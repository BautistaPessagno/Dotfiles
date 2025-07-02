return {
  "neovim/nvim-lspconfig",
  event = { "BufReadPre", "BufNewFile" },
  dependencies = {
    "hrsh7th/cmp-nvim-lsp",
    { "antosha417/nvim-lsp-file-operations", config = true },
    { "folke/neodev.nvim", opts = {} },
    -- Mason y mason-lspconfig suelen ir junto a lspconfig
    "williamboman/mason.nvim",
    "williamboman/mason-lspconfig.nvim",
  },
  config = function()
    local vim, lspconfig = vim, require("lspconfig")
    local mason = require("mason")
    local mlsp = require("mason-lspconfig")
    local caps = require("cmp_nvim_lsp").default_capabilities()
    local keymap = vim.keymap

    -- 1) Inicializa Mason y mason-lspconfig
    mason.setup()
    mlsp.setup({
      ensure_installed = { "svelte", "graphql", "emmet_ls", "lua_ls" },
      automatic_installation = true,
    })

    -- 2) Mapea atajos al adjuntar cada servidor
    vim.api.nvim_create_autocmd("LspAttach", {
      group = vim.api.nvim_create_augroup("UserLspConfig", {}),
      callback = function(ev)
        local opts = { buffer = ev.buf, silent = true }
        keymap.set("n", "gR", "<cmd>Telescope lsp_references<CR>", opts)
        keymap.set("n", "gD", vim.lsp.buf.declaration, opts)
        keymap.set("n", "gd", "<cmd>Telescope lsp_definitions<CR>", opts)
        keymap.set("n", "gi", "<cmd>Telescope lsp_implementations<CR>", opts)
        keymap.set("n", "gt", "<cmd>Telescope lsp_type_definitions<CR>", opts)
        keymap.set({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, opts)
        keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts)
        keymap.set("n", "<leader>D", "<cmd>Telescope diagnostics bufnr=0<CR>", opts)
        keymap.set("n", "<leader>d", vim.diagnostic.open_float, opts)
        keymap.set("n", "[d", vim.diagnostic.goto_prev, opts)
        keymap.set("n", "]d", vim.diagnostic.goto_next, opts)
        keymap.set("n", "K", vim.lsp.buf.hover, opts)
        keymap.set("n", "<leader>rs", ":LspRestart<CR>", opts)
      end,
    })

    -- 3) Cambia iconos del gutter
    local signs = { Error = " ", Warn = " ", Hint = "󰠠 ", Info = " " }
    for type, icon in pairs(signs) do
      vim.fn.sign_define("DiagnosticSign" .. type, { text = icon, texthl = "DiagnosticSign" .. type })
    end

    -- 4) Configura cada servidor _sin_ usar setup_handlers
    --    • Para servidores sin ajustes especiales, el “handler por defecto”:
    local function setup_default(server)
      lspconfig[server].setup({ capabilities = caps })
    end

    -- Svelte (con autocmd personalizado)
    lspconfig.svelte.setup({
      capabilities = caps,
      on_attach = function(client, bufnr)
        vim.api.nvim_create_autocmd("BufWritePost", {
          pattern = { "*.js", "*.ts" },
          callback = function(ctx)
            client.notify("$/onDidChangeTsOrJsFile", { uri = ctx.match })
          end,
        })
      end,
    })

    -- GraphQL
    lspconfig.graphql.setup({
      capabilities = caps,
      filetypes = { "graphql", "gql", "svelte", "typescriptreact", "javascriptreact" },
    })

    -- Emmet
    lspconfig.emmet_ls.setup({
      capabilities = caps,
      filetypes = { "html", "typescriptreact", "javascriptreact", "css", "sass", "scss", "less", "svelte" },
    })

    -- Lua (Neovim)
    lspconfig.lua_ls.setup({
      capabilities = caps,
      settings = {
        Lua = {
          diagnostics = { globals = { "vim" } },
          completion = { callSnippet = "Replace" },
        },
      },
    })

    -- Si tuvieras más servidores “genéricos”, podrías hacer:
    -- for _, srv in ipairs({ "pyright", "tsserver", ... }) do
    --   setup_default(srv)
    -- end
  end,
}

