# Zap
[ -f "${XDG_DATA_HOME}/zap/zap.zsh" ] && source "${XDG_DATA_HOME}/zap/zap.zsh"

# Plugins
plug "zsh-users/zsh-autosuggestions"
plug "zap-zsh/supercharge"
plug "zsh-users/zsh-syntax-highlighting"

export STARSHIP_CONFIG="${XDG_CONFIG_HOME}/starship/starship.toml"

# Starship
eval "$(starship init zsh)"

# Load and initialise completion system
autoload -Uz compinit
compinit
export GHOSTTY_CONFIG_FILE="$HOME/.config/ghostty/config"

# bun completions
[ -s "/Users/caleb/.bun/_bun" ] && source "/Users/caleb/.bun/_bun"

# zoxide last so chpwd hook and compdef stay correct
[[ -f "${XDG_CONFIG_HOME}/zoxide/env.zsh" ]] && source "${XDG_CONFIG_HOME}/zoxide/env.zsh"
eval "$(zoxide init zsh)"
