return {
  "xTacobaco/cursor-agent.nvim",
  -- Load only when one of the commands is invoked
  cmd = { "CursorAgent", "CursorAgentSelection", "CursorAgentBuffer" },
  config = function()
    -- Force our own keymaps so the plugin does not install the default
    -- floating-terminal mapping for <leader>ca.
    vim.g.cursor_agent_mapped = true

    local util = require("cursor-agent.util")
    local cfg = require("cursor-agent.config")

    -- Keep a single persistent side panel terminal
    local side_state = {
      win = nil,
      bufnr = nil,
      job_id = nil,
    }

    local function job_is_alive(job_id)
      if not job_id or job_id == 0 then
        return false
      end
      local ok, res = pcall(vim.fn.jobwait, { job_id }, 0)
      if not ok or type(res) ~= "table" then
        return false
      end
      return res[1] == -1
    end

    local function build_default_argv()
      local active = cfg.get()
      local base = util.to_argv(active.cmd)
      return util.concat_argv(base, active.args)
    end

    local function open_side_term(opts)
      opts = opts or {}
      local argv = opts.argv or build_default_argv()
      local width_ratio = opts.width_ratio or 0.35
      local desired_width = math.max(40, math.floor(vim.o.columns * width_ratio))
      local title = opts.title or "Cursor Agent"

      -- Create or reuse a right vsplit
      vim.cmd("keepalt botright vsplit")
      local win = vim.api.nvim_get_current_win()

      -- Set width and window-local UI settings
      pcall(vim.api.nvim_win_set_width, win, desired_width)
      vim.wo[win].number = false
      vim.wo[win].relativenumber = false
      vim.wo[win].signcolumn = "no"
      vim.wo[win].cursorline = false

      -- Reuse terminal buffer when available
      local bufnr = side_state.bufnr
      local reuse = bufnr and vim.api.nvim_buf_is_valid(bufnr) and job_is_alive(side_state.job_id)
      if reuse and not opts.fresh then
        vim.api.nvim_win_set_buf(win, bufnr)
        side_state.win = win
        -- Jump to bottom and enter insert for immediate typing
        local ok_lines, line_count = pcall(vim.api.nvim_buf_line_count, bufnr)
        if ok_lines then
          pcall(vim.api.nvim_win_set_cursor, win, { line_count, 0 })
        end
        vim.schedule(function()
          pcall(vim.cmd, "startinsert")
        end)
        return bufnr, win, side_state.job_id
      end

      -- Spawn new terminal buffer and job
      bufnr = vim.api.nvim_create_buf(false, true)
      vim.api.nvim_buf_set_option(bufnr, "bufhidden", "hide")
      vim.api.nvim_win_set_buf(win, bufnr)

      local root = util.get_project_root()
      local job_id = vim.fn.termopen(argv, {
        cwd = root,
        on_exit = function(_, code)
          side_state.job_id = nil
          if code ~= 0 then
            util.notify(("cursor-agent exited with code %d"):format(code), vim.log.levels.WARN)
          end
        end,
      })

      -- Convenience close mapping
      pcall(vim.keymap.set, "n", "q", function()
        if side_state.win and vim.api.nvim_win_is_valid(side_state.win) then
          vim.api.nvim_win_close(side_state.win, true)
        end
      end, { buffer = bufnr, nowait = true, silent = true })

      -- Title in statusline (lightweight)
      pcall(vim.api.nvim_buf_set_name, bufnr, title)

      side_state.bufnr = bufnr
      side_state.win = win
      side_state.job_id = job_id

      -- Jump to bottom and enter insert for immediate typing
      local ok_lines, line_count = pcall(vim.api.nvim_buf_line_count, bufnr)
      if ok_lines then
        pcall(vim.api.nvim_win_set_cursor, win, { line_count, 0 })
      end
      vim.schedule(function()
        pcall(vim.cmd, "startinsert")
      end)

      return bufnr, win, job_id
    end

    local function toggle_side_chat()
      local st = side_state
      if st.win and vim.api.nvim_win_is_valid(st.win) then
        vim.api.nvim_win_close(st.win, true)
        st.win = nil
        return
      end
      open_side_term({})
    end

    -- Override commands to use side panel instead of floating terminal
    vim.api.nvim_create_user_command("CursorAgent", function()
      toggle_side_chat()
    end, { desc = "Toggle Cursor Agent side chat", force = true })

    vim.api.nvim_create_user_command("CursorAgentSelection", function()
      local sel = require("cursor-agent.context").get_visual_selection()
      if not sel or sel == "" then
        util.notify("No visual selection", vim.log.levels.WARN)
        return
      end
      local tmp = util.write_tempfile(sel, ".txt")
      local argv = build_default_argv()
      table.insert(argv, tmp)
      -- Restart a fresh session in the side panel with the selection
      open_side_term({ argv = argv, fresh = true, title = "Selection → Cursor Agent" })
    end, { range = true, desc = "Send selection to Cursor Agent (side panel)", force = true })

    vim.api.nvim_create_user_command("CursorAgentBuffer", function()
      local bufctx = require("cursor-agent.context").get_buffer_context()
      local tmp = util.write_tempfile(bufctx.content, ".txt")
      local argv = build_default_argv()
      table.insert(argv, tmp)
      local title = ("%s → Cursor Agent"):format(vim.fn.fnamemodify(bufctx.filepath, ":t"))
      open_side_term({ argv = argv, fresh = true, title = title })
    end, { desc = "Send buffer to Cursor Agent (side panel)", force = true })

    -- Keymaps for side chat
    vim.keymap.set("n", "<leader>ca", ":CursorAgent<CR>", { desc = "Cursor Agent: Toggle side chat" })
    vim.keymap.set("v", "<leader>ca", ":CursorAgentSelection<CR>", { desc = "Cursor Agent: Send selection (side)" })
    vim.keymap.set("n", "<leader>cA", ":CursorAgentBuffer<CR>", { desc = "Cursor Agent: Send buffer (side)" })
  end,
}
