#!/bin/bash
SHELL_NAME=$(basename "$SHELL")

add_to_path() {
  local shell_config_file="$1"

  # shellcheck disable=SC2016
  if grep -Fxq 'export PATH="$HOME/local/bin:$PATH"' "$shell_config_file"; then
    echo "PATH already set in $shell_config_file"
  else
    # shellcheck disable=SC2016
    echo 'export PATH="$HOME/local/bin:$PATH"' >> "$shell_config_file"
    echo "Added PATH to $shell_config_file"
  fi
}


case "$SHELL_NAME" in
  zsh)
    CONFIG_FILE="$HOME/.zshrc"
    ;;
  bash)
    CONFIG_FILE="$HOME/.bash_profile"
    ;;
  *)
    echo "Unsupported shell: $SHELL_NAME"
    echo "Add $HOME/local/bin to PATH manually."
    exit 1
    ;;
esac

add_to_path "$CONFIG_FILE"

echo "PATH configured."
