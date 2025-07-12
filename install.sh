#!/bin/bash

# Настройки языка
set_language() {
  clear
  echo -e "\033[1;36mВыберите язык / Select language:\033[0m"
  options=("Русский" "English")

  local current=0
  while true; do
    for i in "${!options[@]}"; do
      if [ $i -eq $current ]; then
        echo -e "\033[1;32m➤ ${options[i]}\033[0m"
      else
        echo "  ${options[i]}"
      fi
    done

    read -rsn1 key
    case "$key" in
    $'\x1b') # Escape sequence
      read -rsn2 -t 0.1 key
      case "$key" in
      '[A') current=$(((current - 1 + ${#options[@]}) % ${#options[@]})) ;;
      '[B') current=$(((current + 1) % ${#options[@]})) ;;
      esac
      ;;
    '') # Enter key
      LANG_CHOICE=$current
      break
      ;;
    esac
    clear
    echo -e "\033[1;36mВыберите язык / Select language:\033[0m"
  done

  case $LANG_CHOICE in
  0) # Русский
    MSG_FONTS="Установка шрифтов..."
    MSG_RESOLUTION="Выберите разрешение монитора:"
    MSG_REFRESH="Выберите частоту обновления:"
    MSG_HYPRLOCK="Установка Hyprlock"
    MSG_GRUB="Установить тему GRUB?"
    MSG_GRUB_RES="Выберите разрешение для темы GRUB:"
    MSG_COMPLETE="Установка завершена успешно!"
    OPT_1K="1k (1920x1080)"
    OPT_2K="2k (2560x1440)"
    OPT_60Hz="60Hz"
    OPT_144Hz="144Hz"
    OPT_YES="Да"
    OPT_NO="Нет"
    ;;
  1) # English
    MSG_FONTS="Installing fonts..."
    MSG_RESOLUTION="Select monitor resolution:"
    MSG_REFRESH="Select refresh rate:"
    MSG_HYPRLOCK="Installing Hyprlock"
    MSG_GRUB="Install GRUB theme?"
    MSG_GRUB_RES="Select resolution for GRUB theme:"
    MSG_COMPLETE="Installation completed successfully!"
    OPT_1K="1k (1920x1080)"
    OPT_2K="2k (2560x1440)"
    OPT_60Hz="60Hz"
    OPT_144Hz="144Hz"
    OPT_YES="Yes"
    OPT_NO="No"
    ;;
  esac
}

# Функция для отображения меню
show_menu() {
  local prompt="$1"
  shift
  local options=("$@")
  local current=0

  while true; do
    clear
    echo -e "\033[1;36m$prompt\033[0m"
    for i in "${!options[@]}"; do
      if [ $i -eq $current ]; then
        echo -e "\033[1;32m➤ ${options[i]}\033[0m"
      else
        echo "  ${options[i]}"
      fi
    done

    read -rsn1 key
    case "$key" in
    $'\x1b') # Escape sequence
      read -rsn2 -t 0.1 key
      case "$key" in
      '[A') current=$(((current - 1 + ${#options[@]}) % ${#options[@]})) ;;
      '[B') current=$(((current + 1) % ${#options[@]})) ;;
      esac
      ;;
    '') # Enter key
      return $current
      ;;
    esac
  done
}

# Установка шрифтов
install_fonts() {
  clear
  echo -e "\033[1;34m$MSG_FONTS\033[0m"

  FONT_TMP_DIR=$(mktemp -d)

  # CaskaydiaCove Nerd Font
  echo -e "\033[1;33m• CaskaydiaCove Nerd Font...\033[0m"
  if wget -q --show-progress -P "$FONT_TMP_DIR" https://github.com/ryanoasis/nerd-fonts/releases/download/v3.0.2/CascadiaCode.zip; then
    unzip -q "$FONT_TMP_DIR/CascadiaCode.zip" -d "$FONT_TMP_DIR/CaskaydiaCove"
  else
    echo -e "\033[1;31mОшибка загрузки / Download error\033[0m"
    exit 1
  fi

  # Font Awesome 6
  echo -e "\033[1;33m• Font Awesome 6...\033[0m"
  if wget -q --show-progress -P "$FONT_TMP_DIR" https://github.com/FortAwesome/Font-Awesome/releases/download/6.4.0/fontawesome-free-6.4.0-desktop.zip; then
    unzip -q "$FONT_TMP_DIR/fontawesome-free-6.4.0-desktop.zip" -d "$FONT_TMP_DIR/FontAwesome6"
  else
    echo -e "\033[1;31mОшибка загрузки / Download error\033[0m"
    exit 1
  fi

  FONT_DIR="/usr/share/fonts/truetype/custom"
  sudo mkdir -p "$FONT_DIR"
  sudo cp -r "$FONT_TMP_DIR/CaskaydiaCove/"*.ttf "$FONT_DIR/"
  sudo cp "$FONT_TMP_DIR/FontAwesome6/otfs/Font Awesome 6 Free-Regular-400.otf" "$FONT_DIR/"
  sudo cp "$FONT_TMP_DIR/FontAwesome6/otfs/Font Awesome 6 Free-Solid-900.otf" "$FONT_DIR/"

  echo -e "\033[1;33m• Обновление кэша шрифтов / Updating font cache...\033[0m"
  sudo fc-cache -fv

  rm -rf "$FONT_TMP_DIR"
  echo -e "\033[1;32m✓ Шрифты установлены / Fonts installed\033[0m"
  sleep 1
}

# Выбор разрешения монитора
select_resolution() {
  show_menu "$MSG_RESOLUTION" "$OPT_1K" "$OPT_2K"
  local choice=$?

  if [ $choice -eq 0 ]; then
    config_dir="1k@60"
  else
    show_menu "$MSG_REFRESH" "$OPT_60Hz" "$OPT_144Hz"
    local hz_choice=$?
    [ $hz_choice -eq 0 ] && config_dir="2k@60" || config_dir="2k@144"
  fi

  echo -e "\033[1;32m✓ Выбрано: $config_dir / Selected: $config_dir\033[0m"
  sleep 1
}

# Установка Hyprlock
install_hyprlock() {
  clear
  echo -e "\033[1;34m$MSG_HYPRLOCK\033[0m"

  if ! command -v hyprlock &>/dev/null; then
    echo -e "\033[1;33m• Установка Hyprlock / Installing Hyprlock...\033[0m"
    sudo pacman -S --needed hyprlock
  fi

  if [ -d "conf/hyprlock" ]; then
    echo -e "\033[1;33m• Копирование конфигураций / Copying configs...\033[0m"
    mkdir -p "$HOME/.config/hypr"
    cp -r "conf/hyprlock/"* "$HOME/.config/hypr/"
    echo -e "\033[1;32m✓ Hyprlock настроен / Hyprlock configured\033[0m"
  else
    echo -e "\033[1;31mПапка conf/hyprlock не найдена / conf/hyprlock not found\033[0m"
  fi
  sleep 1
}

# Установка темы GRUB
install_grub() {
  show_menu "$MSG_GRUB" "$OPT_YES" "$OPT_NO"
  local choice=$?

  if [ $choice -eq 0 ]; then
    show_menu "$MSG_GRUB_RES" "$OPT_1K" "$OPT_2K"
    local res_choice=$?
    [ $res_choice -eq 0 ] && grub_dir="conf/grub/1k" || grub_dir="conf/grub/2k"

    if [ -d "$grub_dir" ]; then
      echo -e "\033[1;33m• Установка темы GRUB / Installing GRUB theme...\033[0m"
      (cd "$grub_dir" && sudo ./install.sh)
      echo -e "\033[1;32m✓ GRUB тема установлена / GRUB theme installed\033[0m"
    else
      echo -e "\033[1;31mДиректория не найдена / Directory not found\033[0m"
    fi
  fi
  sleep 1
}

# Основной процесс
main() {
  set_language

  # Последовательное выполнение шагов
  install_fonts
  select_resolution
  install_hyprlock
  install_grub

  clear
  echo -e "\033[1;32m$MSG_COMPLETE\033[0m"
}

main
