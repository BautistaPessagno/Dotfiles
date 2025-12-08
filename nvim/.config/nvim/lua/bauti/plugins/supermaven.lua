return {
  "supermaven-inc/supermaven-nvim",
  event = "InsertEnter",
  config = function()
    require("supermaven-nvim").setup({
      keymaps = {
        accept_suggestion = "<Tab>",
        clear_suggestion = "<C-]>",
        accept_word = "<C-j>", -- aceptar palabra parcial
      },
      ignore_filetypes = { -- no sugerir en estos filetypes
        cpp = true,
        -- markdown = true,
        -- "gitcommit", -- también acepta estilo lista
      },
      color = {
        suggestion_color = "#555555", -- color de ghost text
        cterm = 244,
      },
      log_level = "info", -- "off" para desactivar logs
    })
  end,
}
