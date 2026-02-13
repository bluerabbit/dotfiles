local wezterm = require 'wezterm'
local config = wezterm.config_builder()

-- 終了させるときに確認ダイアログを出さない
config.window_close_confirmation = "NeverPrompt"
config.automatically_reload_config = true
config.use_ime = true

-- 見た目
config.window_padding = { left = '0', right = '0', top = '0', bottom = '0' }
config.command_palette_font_size = 18.0
config.window_frame = { font_size = 14 }

-- 非フォーカスペインの背景色設定
config.inactive_pane_hsb = { saturation = 0.8, brightness = 0.2 }
config.enable_scroll_bar = true
config.line_height = 0.85
config.color_scheme = 'MaterialDesignColors'
config.colors = {
	selection_bg = "#CCCC33",
	selection_fg = "#111111",
	cursor_bg = "#00FF00",
	cursor_fg = "#000000",
	cursor_border = "#00FF00",
	scrollbar_thumb = "#AAAAAA",
	compose_cursor = 'silver',
}

-- brew install --cask font-jetbrains-mono-nerd-font
-- config.font = wezterm.font("JetBrainsMono Nerd Font")
config.font = wezterm.font("JetBrainsMono")
config.font_size = 15.0
config.adjust_window_size_when_changing_font_size = true

-- タイトルバーの削除
config.window_decorations = "RESIZE"
-- タブバーと背景を同じ色
config.window_background_gradient = { colors = { "#000000" } }
-- タブバーの+を消す
config.show_new_tab_button_in_tab_bar = false

config.quick_select_patterns = {
    -- 数字3桁 + '-' から始まる文字列にマッチ
    "\\b\\d{3}-\\S*", -- 123-abc
    -- 日付形式
    "\\b\\d{4}-\\d{2}-\\d{2}\\b", -- 2021-01-01
}

-- === wezterm.on ===

-- 起動時に画面を最大化
wezterm.on("gui-startup", function()
  local _, _, window = wezterm.mux.spawn_window({})
  window:gui_window():maximize()
end)

-- タブ
wezterm.on("format-tab-title", function(tab, tabs, panes, config, hover, max_width)
  local background = "#555555" -- 非アクティブタブの背景色（灰色）
  local foreground = "#ffffff" -- 非アクティブタブの文字色（白）
  local intensity = "Normal" -- 非アクティブタブのフォントスタイル

  if tab.is_active then
    background = "#000000" -- アクティブタブの背景色（黒）
    foreground = "#ffffff" -- アクティブタブの文字色（白）
    intensity = "Bold" -- アクティブタブのフォントスタイルを太字に
  end

  local title = "⌘" .. tab.tab_index + 1 .. " " .. (tab.active_pane.title or "Unknown")
  return {
    { Background = { Color = background } },
    { Foreground = { Color = foreground } },
    { Attribute = { Intensity = "Normal" } }, -- フォントのスタイルを設定
    { Text = title },
  }
end)

-- workspaceの表示
wezterm.on('update-right-status', function(window, pane)
  local current_workspace = window:active_workspace()
  local all_workspaces = wezterm.mux.get_workspace_names()

  local formatted_workspaces = {}
  for _, workspace in ipairs(all_workspaces) do
    if workspace == current_workspace then
      table.insert(formatted_workspaces, wezterm.format({
        { Background = { Color = "#696969" } }, -- アクティブ背景色（灰色）
        { Foreground = { Color = "#ffffff" } }, -- アクティブ文字色（白）
        { Text = "  " .. workspace .. "  " }, -- 前後にスペースを追加
      }))
    else
      table.insert(formatted_workspaces, wezterm.format({
        { Background = { Color = "#3c3c3c" } }, -- 非アクティブ背景色
        { Foreground = { Color = "#d0d0d0" } }, -- 非アクティブ文字色
        { Text = "  " .. workspace .. "  " }, -- 前後にスペースを追加
      }))
    end
  end

  -- ワークスペースを右側に並べて表示
  window:set_right_status(wezterm.format({
    { Foreground = { Color = "#d0d0d0" } }, -- 全体の文字色
    { Background = { Color = "#3c3c3c" } }, -- 全体の背景色
    { Text = table.concat(formatted_workspaces, " ") }, -- ワークスペースをスペースで区切り
  }))
end)

-- ショートカットキー設定
local act = wezterm.action

-- リーダーキーは Ctrl-t
config.leader = { key = "t", mods = "CTRL", timeout_milliseconds = 1000 }
config.keys = {
  -- 検索
	{ key = 'f', mods = 'SUPER', action = act.Multiple { act.ClearSelection, act.Search { CaseInSensitiveString = '' } }},

  -- 単語移動
  { key = "LeftArrow", mods = "ALT", action = act.SendKey { key = "b", mods = "META" } },
  -- 単語移動
  { key = "RightArrow", mods = "ALT", action = act.SendKey { key = "f", mods = "META" } },
  -- 単語削除
  { key = "Backspace", mods = "ALT", action = act.SendKey { key = "w", mods = "CTRL" } },
  -- Cmd + w でペインを閉じる
  { key = "w", mods = "CMD", action = wezterm.action.CloseCurrentPane({ confirm = true }) },
  -- ⌘+Shift + でフォントサイズを大きくする
  { key = "+", mods = "CMD|SHIFT", action = wezterm.action.IncreaseFontSize },
  -- Cmd+Shift+Pでコマンドパレットを表示
  { key = 'P', mods = 'CMD|SHIFT', action = wezterm.action.ActivateCommandPalette },

  -- Ctrl-t → h を押すと左右分割
  { key = "h", mods = "LEADER", action = act.SplitPane { direction = "Right" } },
  -- ⌘ → d を押すと左右分割
  { key = "d", mods = "SUPER", action = act.SplitPane { direction = "Right" } },
  -- Ctrl-t → space を押すと上下分割
  { key = " ", mods = "LEADER", action = act.SplitPane { direction = "Down" } },
  -- Ctrl+t → o でペインを変更
  { key = "o", mods = "LEADER", action = act.ActivatePaneDirection 'Next' },

  -- Ctrl-t → w でWorkspaceランチャーを開く
  { key = "w", mods = "LEADER", action = act.ShowLauncherArgs { flags = "FUZZY|WORKSPACES" } },
  -- Ctrl+t → n で次のWorkspaceに移動
  { key = "n", mods = "LEADER", action = act.SwitchWorkspaceRelative(1) },
  -- Ctrl+t → p で前のWorkspaceに移動
  { key = "p", mods = "LEADER", action = act.SwitchWorkspaceRelative(-1) },
  -- Ctrl-t → c を押すとworkspaceの作成
  {
    key = "c",
    mods = "LEADER",
    action = wezterm.action_callback(function(window, pane)
      local new_workspace = "workspace_" .. os.time()
      window:perform_action(wezterm.action.SwitchToWorkspace{workspace = new_workspace}, pane)
    end),
  },
  -- Ctrl-t → , workspaceの名前変更
  {
    key = ",",
    mods = "LEADER",
    action = act.PromptInputLine({
      description = "(wezterm) Set workspace title:",
      action = wezterm.action_callback(function(win, pane, line)
        if line then
          wezterm.mux.rename_workspace(wezterm.mux.get_active_workspace(), line)
        end
      end),
    })
  },
  -- LEADER + [ でコピーモードを開始
  { key = "[", mods = "LEADER", action = act.ActivateCopyMode },
  -- LEADER + y でペースト
  { key = "y", mods = "LEADER", action = act.PasteFrom("Clipboard") },
  -- LEADER + ] でペースト
  { key = "]", mods = "LEADER", action = act.PasteFrom("Clipboard") },
  -- ScrollToPrompt
  { key = 'UpArrow', mods = 'SHIFT', action = act.ScrollToPrompt(-1) },
  { key = 'DownArrow', mods = 'SHIFT', action = act.ScrollToPrompt(1) },
}

-- Copy モード用のキーバインド
-- https://wezfurlong.org/wezterm/copymode.html
config.key_tables = {
  copy_mode = {
    -- Emacsライクの移動
    -- Ctrl+b で後ろへ1文字
    { key = 'b', mods = 'CTRL', action = act.CopyMode('MoveLeft') },
    -- Ctrl+f で前へ1文字
    { key = 'f', mods = 'CTRL', action = act.CopyMode('MoveRight') },
    -- Ctrl+p で前の行へ
    { key = 'p', mods = 'CTRL', action = act.CopyMode('MoveUp') },
    -- Ctrl+n で次の行へ
    { key = 'n', mods = 'CTRL', action = act.CopyMode('MoveDown') },
    -- Ctrl+a で行頭へ
    { key = 'a', mods = 'CTRL', action = act.CopyMode('MoveToStartOfLine') },
    -- Ctrl+e で行末へ
    { key = 'e', mods = 'CTRL', action = act.CopyMode('MoveToEndOfLineContent') },

    -- 矢印キーの移動
    { key = 'LeftArrow', mods = 'NONE', action = act.CopyMode('MoveLeft') },
    { key = 'RightArrow', mods = 'NONE', action = act.CopyMode('MoveRight') },
    { key = 'UpArrow', mods = 'NONE', action = act.CopyMode('MoveUp') },
    { key = 'DownArrow', mods = 'NONE', action = act.CopyMode('MoveDown') },

    -- Tabで単語移動
    { key = 'Tab', mods = 'NONE',  action = act.CopyMode 'MoveForwardWord' },
		{ key = 'Tab', mods = 'SHIFT', action = act.CopyMode 'MoveBackwardWord' },

    -- Ctrl-v でページスクロール
    { key = 'v', mods = 'CTRL', action = act.CopyMode { MoveByPage = 0.3 }, },
    -- Ctrl+Shift + v でページスクロール
    { key = 'v', mods = 'CTRL|SHIFT', action = act.CopyMode { MoveByPage = -0.3 }, },
    
    -- Ctrl+Space 選択モード
    { key = ' ', mods = 'CTRL', action = act.CopyMode { SetSelectionMode = 'Cell' } },
    -- Ctrl-w コピーしてコピーモードを抜ける
    { key = 'w', mods = 'CTRL', action = act.Multiple { act.CopyTo("ClipboardAndPrimarySelection"), act.CopyMode("Close") } },
    -- Enter コピーしてコピーモードを抜ける
    { key = 'Enter', mods = 'NONE', action = act.Multiple { act.CopyTo("ClipboardAndPrimarySelection"), act.CopyMode("Close") } },
    -- Ctrl-q コピーモードを抜ける
    { key = 'q', mods = 'NONE', action = act.CopyMode('Close') },
    -- Ctrl-k コピーモードを抜ける
    { key = 'k', mods = 'CTRL', action = act.CopyMode('Close') },
  },
  search_mode = {
    -- Ctrl + n で次の一致項目に移動（Emacsライク）
    { key = 'n', mods = 'CTRL', action = act.CopyMode('NextMatch') },
    -- Ctrl + p で前の一致項目に移動（Emacsライク）
    { key = 'p', mods = 'CTRL', action = act.CopyMode('PriorMatch') },
    -- 上下矢印で次/前の一致項目に移動
    { key = 'UpArrow', mods = 'NONE', action = act.CopyMode('PriorMatch') },
    { key = 'DownArrow', mods = 'NONE', action = act.CopyMode('NextMatch') },
    -- Tabで次の一致、Shift+Tabで前の一致に移動
    { key = 'Tab', mods = 'NONE', action = act.CopyMode('NextMatch') },
    { key = 'Tab', mods = 'SHIFT', action = act.CopyMode('PriorMatch') },
    -- 左右矢印でカーソルを移動
    { key = 'LeftArrow', mods = 'NONE', action = act.CopyMode('MoveLeft') },
    { key = 'RightArrow', mods = 'NONE', action = act.CopyMode('MoveRight') },

    -- Enterキーで選択をコピーしてモードを終了
    { key = 'Enter', mods = 'NONE', action = act.Multiple { act.CopyTo("ClipboardAndPrimarySelection"), act.CopyMode("Close") } },
    -- Escキーで検索モードを終了
    { key = 'Escape', mods = 'NONE', action = act.CopyMode('Close') },
    -- Ctrl+c で検索モードをキャンセル
    { key = 'c', mods = 'CTRL', action = act.CopyMode('Close') },
  },
}

config.mouse_bindings = {
  {
    -- 左クリック3回でカーソル位置のコマンド出力を選択
    event = { Down = { streak = 3, button = "Left" } },
    action = wezterm.action.SelectTextAtMouseCursor("SemanticZone"),
    mods = "NONE",
  },
}

return config
