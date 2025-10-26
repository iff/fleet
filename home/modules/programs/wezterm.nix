{ ... }:

{
  programs.wezterm = {
    enable = true;

    extraConfig = ''
      local wezterm = require 'wezterm'
      local act = wezterm.action
      local config = {}

      if wezterm.config_builder then
        config = wezterm.config_builder()
      end

      -- Terminal basics
      config.term = "wezterm"
      config.scrollback_lines = 5000

      -- Color scheme matching tmux
      config.colors = {
        foreground = '#abb1bb',
        background = '#232831',

        cursor_bg = '#abb1bb',
        cursor_fg = '#232831',
        cursor_border = '#abb1bb',

        selection_fg = '#232831',
        selection_bg = '#abb1bb',

        ansi = {
          '#232831', -- black
          '#bf616a', -- red
          '#a3be8c', -- green
          '#ebcb8b', -- yellow
          '#81a1c1', -- blue
          '#b48ead', -- magenta
          '#88c0d0', -- cyan
          '#abb1bb', -- white
        },
        brights = {
          '#7e8188', -- bright black
          '#bf616a', -- bright red
          '#a3be8c', -- bright green
          '#ebcb8b', -- bright yellow
          '#81a1c1', -- bright blue
          '#b48ead', -- bright magenta
          '#88c0d0', -- bright cyan
          '#abb1bb', -- bright white
        },

        tab_bar = {
          background = '#232831',
          active_tab = {
            bg_color = '#abb1bb',
            fg_color = '#232831',
            intensity = 'Bold',
          },
          inactive_tab = {
            bg_color = '#232831',
            fg_color = '#7e8188',
          },
          inactive_tab_hover = {
            bg_color = '#232831',
            fg_color = '#abb1bb',
          },
          new_tab = {
            bg_color = '#232831',
            fg_color = '#abb1bb',
          },
        },
      }

      -- Tab bar appearance
      config.use_fancy_tab_bar = false
      config.tab_bar_at_bottom = false
      config.tab_max_width = 32
      config.show_tab_index_in_tab_bar = true

      -- Pane borders matching tmux
      config.window_padding = {
        left = 0,
        right = 0,
        top = 0,
        bottom = 0,
      }

      config.inactive_pane_hsb = {
        saturation = 0.9,
        brightness = 0.8,
      }

      -- Font and rendering
      config.font = wezterm.font('ZedMono Nerd Font')
      config.font_size = 11.0
      config.front_end = "WebGpu"
      config.enable_tab_bar = true

      -- Window appearance
      config.window_close_confirmation = 'NeverPrompt'
      config.adjust_window_size_when_changing_font_size = false

      -- Leader key (F12, matching tmux prefix)
      config.leader = { key = 'F12', mods = ''', timeout_milliseconds = 1000 }

      config.keys = {
        -- Leader + ; for command palette (like tmux command-prompt)
        { key = ';', mods = 'LEADER', action = act.ActivateCommandPalette },

        -- Leader + d to detach (close current tab)
        { key = 'd', mods = 'LEADER', action = act.CloseCurrentTab{ confirm = true } },

        -- Leader + Backspace for new tab (like tmux new-window)
        { key = 'Backspace', mods = 'LEADER', action = act.SpawnTab 'CurrentPaneDomain' },

        -- Leader + Enter for horizontal split (like tmux)
        { key = 'Enter', mods = 'LEADER', action = act.SplitHorizontal{ domain = 'CurrentPaneDomain' } },

        -- Leader + Tab for vertical split (like tmux)
        { key = 'Tab', mods = 'LEADER', action = act.SplitVertical{ domain = 'CurrentPaneDomain' } },

        -- Leader + g to close tab with confirmation (like tmux kill-window)
        { key = 'g', mods = 'LEADER', action = act.CloseCurrentTab{ confirm = true } },

        -- Leader + Space to show tab navigator (like tmux session navigator)
        { key = 'Space', mods = 'LEADER', action = act.ShowTabNavigator },

        -- Leader + F12 activates direct mode for quick tab/pane selection
        -- Direct tab selection (F12 F12 n/e/i/o)
        { key = 'n', mods = 'LEADER|CTRL', action = act.ActivateTab(0) },
        { key = 'e', mods = 'LEADER|CTRL', action = act.ActivateTab(1) },
        { key = 'i', mods = 'LEADER|CTRL', action = act.ActivateTab(2) },
        { key = 'o', mods = 'LEADER|CTRL', action = act.ActivateTab(3) },

        -- Direct pane selection (F12 F12 h/,/.//)
        { key = 'h', mods = 'LEADER|CTRL', action = act.ActivatePaneByIndex(0) },
        { key = ',', mods = 'LEADER|CTRL', action = act.ActivatePaneByIndex(1) },
        { key = '.', mods = 'LEADER|CTRL', action = act.ActivatePaneByIndex(2) },
        { key = '/', mods = 'LEADER|CTRL', action = act.ActivatePaneByIndex(3) },

        -- Leader + . to toggle pane zoom (like tmux resize-pane -Z)
        { key = '.', mods = 'LEADER', action = act.TogglePaneZoomState },

        -- Leader + Y to move pane to new tab (like tmux break-pane)
        { key = 'Y', mods = 'LEADER|SHIFT', action = act.PaneSelect{ mode = 'MoveToNewTab' } },

        -- Leader + , to rename tab (like tmux rename-window)
        { key = ',', mods = 'LEADER', action = act.PromptInputLine{
          description = 'Enter new name for tab',
          action = wezterm.action_callback(function(window, pane, line)
            if line then
              window:active_tab():set_title(line)
            end
          end),
        }},

        -- Leader + a for copy mode (using wezterm's copy mode)
        { key = 'a', mods = 'LEADER', action = act.ActivateCopyMode },

        -- Additional useful bindings
        { key = 'c', mods = 'CTRL|SHIFT', action = act.CopyTo 'Clipboard' },
        { key = 'v', mods = 'CTRL|SHIFT', action = act.PasteFrom 'Clipboard' },
        { key = 'f', mods = 'CTRL|SHIFT', action = act.Search 'CurrentSelectionOrEmptyString' },
      }

      -- Copy mode key table with custom vim-like bindings matching tmux
      config.key_tables = {
        copy_mode = {
          { key = 'Escape', mods = 'NONE', action = act.CopyMode 'Close' },

          -- Custom movement matching tmux config
          { key = 'u', mods = 'NONE', action = act.CopyMode 'MoveUp' },
          { key = 'n', mods = 'NONE', action = act.CopyMode 'MoveLeft' },
          { key = 'i', mods = 'NONE', action = act.CopyMode 'MoveRight' },
          { key = 'e', mods = 'NONE', action = act.CopyMode 'MoveDown' },

          { key = 'm', mods = 'NONE', action = act.CopyMode 'MoveToStartOfLine' },
          { key = 'o', mods = 'NONE', action = act.CopyMode 'MoveToEndOfLineContent' },

          { key = 'h', mods = 'NONE', action = act.CopyMode 'PageDown' },
          { key = 'k', mods = 'NONE', action = act.CopyMode 'PageUp' },

          { key = 'h', mods = 'CTRL', action = act.CopyMode 'MoveToScrollbackBottom' },
          { key = 'k', mods = 'CTRL', action = act.CopyMode 'MoveToScrollbackTop' },

          { key = 'u', mods = 'CTRL', action = act.CopyMode 'MoveToStartOfLineContent' },
          { key = 'e', mods = 'CTRL', action = act.CopyMode 'MoveToEndOfLineContent' },

          -- Visual selection
          { key = 'v', mods = 'NONE', action = act.CopyMode{ SetSelectionMode = 'Cell' } },
          { key = 'V', mods = 'SHIFT', action = act.CopyMode{ SetSelectionMode = 'Line' } },

          -- Copy to clipboard
          { key = 'y', mods = 'NONE', action = act.Multiple{
            { CopyTo = 'ClipboardAndPrimarySelection' },
            { CopyMode = 'Close' },
          }},

          -- Search
          { key = '/', mods = 'NONE', action = act.Search 'CurrentSelectionOrEmptyString' },
        },

        search_mode = {
          { key = 'Escape', mods = 'NONE', action = act.CopyMode 'Close' },
          { key = 'Enter', mods = 'NONE', action = act.CopyMode 'PriorMatch' },
          { key = 'n', mods = 'CTRL', action = act.CopyMode 'NextMatch' },
          { key = 'p', mods = 'CTRL', action = act.CopyMode 'PriorMatch' },
          { key = 'u', mods = 'CTRL', action = act.CopyMode 'ClearPattern' },
        },
      }

      -- Tab title formatting
      wezterm.on('format-tab-title', function(tab, tabs, panes, config, hover, max_width)
        local title = tab.tab_index + 1 .. '  ' .. (tab.tab_title or tab.active_pane.title)

        if tab.is_active then
          return {
            { Background = { Color = '#abb1bb' } },
            { Foreground = { Color = '#232831' } },
            { Text = ' ' .. title .. ' ' },
          }
        else
          return {
            { Background = { Color = '#232831' } },
            { Foreground = { Color = '#7e8188' } },
            { Text = ' ' .. title .. ' ' },
          }
        end
      end)

      return config
    '';
  };
}
