# [ Info ]
# Zflex - Zsh plugin manager without bloat and skill issiu
# Created by: https://codeberg.org/xeks-happiness
# Licensed under: 0BSD License
# Inspired by: https://github.com/mattmc3/zsh_unplugged

# [ Sourcing, autoloading and setting default values for vars ]
# Standarized way of handling plugin directory,
# regardless of functionargzero and posixargzero,
# and with an option for a plugin manager to alter
# the plugin directory (i.e. set ZERO parameter)
# Allows using ${0:A:h} to get path of plugin
# https://zdharma-continuum.github.io/Zsh-100-Commits-Club/Zsh-Plugin-Standard.html
0="${${ZERO:-${0:#$ZSH_ARGZERO}}:-${(%):-%N}}"
0="${${(M)0:#/*}:-$PWD/$0}"

# Save location of this file in variable for easier use
typeset -g ZFLEX_HOME="${0:A:h}"

# Location where all repos managed by zflex is stored by default
typeset -gx ZFLEX_STORAGE="${ZFLEX_STORAGE:-$ZFLEX_HOME/storage/}"

# Add functions directory to $fpath
fpath+=("$ZFLEX_HOME/functions")

# Autoload functions from functions directory
autoload -Uz zflex _zflex_source
