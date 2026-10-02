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

typeset -gx ZFLEX_STORAGE="${ZFLEX_STORAGE:-$ZFLEX_HOME/storage/}"

# [ Main function of zflex ]
function zflex {
	autoload -Uz zrecompile
	local arg repos tags tag_as tag_from tag_from_dir tag_commit
	local clone_args=(-q --depth=1 --recursive --shallow-submodules)

	# Parse through tags, repos and their acceptable values and return 1 if anything is wrong
	for arg in "$@"; do
		case "$arg" in
				# Check if $arg is repo
			*/*)
				# Add repo to $repos array if it isn't present already in $repos array, skip otherwise
				(( ${repos[(Ie)$arg]} )) || repos+=("$arg")
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
						;;
				esac
				;;
		esac
	done

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
			$ZFLEX_HOME/scripts/update "$repos[@]"
			$ZFLEX_HOME/scripts/optimize
			;;
		*/*)
			$ZFLEX_HOME/scripts/clone "$tag_as" "$tag_from" "$tag_commit" "${repos[@]}"
			$ZFLEX_HOME/scripts/optimize
			;;
		*)
			print -Pu2 "%F{005}Zflex: %F{001}Unknown subcommand: $subcommand%f"
			return 1
			;;
	esac
}
