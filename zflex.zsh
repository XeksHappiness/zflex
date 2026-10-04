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

# Location where all repos managed by zflex is stored
typeset -gx ZFLEX_STORAGE="${ZFLEX_STORAGE:-$ZFLEX_HOME/storage/}"

# [ Main function of zflex ]
function zflex {
	local arg tag_as tag_from tag_from_dir tag_commit
	local clone_args=(-q --depth=1 --recursive --shallow-submodules)

	# Parse through tags, repos and their acceptable values and return 1 if anything is wrong
	for arg in "$@"; do
		case "$arg" in
				# Check if $arg is repo
			*/*)
				# Add repo to $ZFLEX_REPOS array if it isn't present already in it, skip otherwise
				(( ${ZFLEX_REPOS[(Ie)$arg]} )) || ZFLEX_REPOS+=("$arg")
				;;

				# Check if $arg is tag
			*=*|*:*)
				case "$arg" in
						# Tag to choose if repo is used as zsh plugin, local package or etc
					as*)
						case "${arg#as?}" in
							plugin|package)
								tag_as="${arg#as?}"
								;;
							*)
								print -Pu2 "%F{005}Zflex: %F{001}Invalid value: $arg%f"
								return 1
								;;
						esac
						;;

						# Tag to choose from which remote to clone repo
					from*)
						case "${arg#from?}" in
							github|gitlab|bitbucked)
								tag_from_dir="${arg#from?}"
								tag_from="$tag_from_dir.com"
								;;
							codeberg)
								tag_from_dir="${arg#from?}"
								tag_from="$tag_from_dir.org"
								;;
							*)
								print -Pu2 "%F{005}Zflex: %F{001}Invalid value: $arg%f"
								return 1
								;;
						esac
						;;

						# Tag to pin repo to a specific commit by its commit sha
					commit*)
						tag_commit="${arg#commit?}"
						clone_args+=(--no-checkout)
						;;
					*)
						print -Pu2 "%F{005}Zflex: %F{001}Unknown tag: $arg%f"
						return 1
						;;
				esac
				;;
		esac
	done

	# TODO: Switch to ztyle instead of this mess later
	# Set $tag_as to $ZFLEX_DEFAULT_AS or "plugin" by default if "as=" tag wasn't used by user
	if [[ -n "$tag_as" ]] && [[ -n $ZFLEX_DEFAULT_AS ]]; then
		tag_as="$ZFLEX_DEFAULT_AS"
	else
		tag_as='plugin'
	fi

	# Set $tag_from to $ZFLEX_DEFAULT_FROM or "github" by default if "from=" tag wasn't used by user
	if [[ -n "$tag_from" ]] && [[ -n $ZFLEX_DEFAULT_FROM ]]; then
		tag_from="$ZFLEX_DEFAULT_FROM"
	else
		tag_from='github.com'
	fi

	case "$1" in
		update)
			shift
			$ZFLEX_HOME/scripts/update "$ZFLEX_REPOS[@]"
			$ZFLEX_HOME/scripts/optimize
			;;
		source)
			$ZFLEX_HOME/scripts/optimize
			_zflex_source "$ZFLEX_REPOS[@]"
			;;
		*/*)
			$ZFLEX_HOME/scripts/clone "$tag_as" "$tag_from" "$tag_commit" "$ZFLEX_REPOS[@]"
			$ZFLEX_HOME/scripts/optimize
			;;
		*)
			print -Pu2 "%F{005}Zflex: %F{001}Unknown subcommand: $1%f"
			return 1
			;;
	esac
}
