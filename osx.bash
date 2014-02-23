#!/bin/bash

# Dockを自動的に隠す
defaults write com.apple.dock autohide -bool true

# Finder
# 拡張子を常に表示する
#defaults write -g AppleShowAllExtensions -bool true

# .DS_Storeを作らない
defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true

# 拡張子変更時に確認を求めない
defaults write com.apple.finder FXEnableExtensionChangeWarning -bool true

# スクリーンショットのprefixを変更する
defaults write com.apple.screencapture name "SS"
