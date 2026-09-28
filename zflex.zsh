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

typeset -gx ZFLEX_STORAGE="${ZFLEX_PLUGIN_DIR:-$ZFLEX_HOME/storage/}"

# [ Main function of zflex ]
function zflex {
	autoload -Uz zrecompile
	local arg tags repos found_as_tag tag_as tag_from tag_from_dir tag_commit repo repo_dir confirmation initfiles file
	local clone_args=(-q --depth=1 --recursive --shallow-submodules)
	local subcommand="$1"
	shift

	# [ Parsing ]
	# Add all repos written before "as=" in to repos array
	# Add all tags written starting from "as=" in to tags array
	for arg in "$@"; do
		if (( found_as_tag )); then
			tags+=("$arg")
		elif [[ $arg == as=* ]]; then
			found_as_tag=1
			tags+=("$arg")
		elif [[ $arg == */* ]]; then
			repos+=("$arg")
		fi
	done

	# Parse through tags and set their corresponding variables
	# in to their acceptable values and return 1 anything is wrong
	for arg in "$tags"; do
		case "$arg" in
				# Tag to choose if repo is used as zsh plugin, local package or etc
			as=*)
				case "${arg#as=}" in
					plugin|package)
						tag_as="${arg#as=}"
						;;
					*)
						print -Pu2 "%F{005}Zflex: %F{001}Invalid value of tag: %F{003}as=%F{001}${arg#as=}"
						return 1
						;;
				esac
				;;

				# Tag to choose from which remote to clone repo
			from=*)
				case "${arg#from=}" in
					github|gitlab|bitbucked)
						tag_from_dir="${arg#from=}"
						tag_from="$tag_from_dir.com"
						;;
					codeberg)
						tag_from_dir="${arg#from=}"
						tag_from="$tag_from_dir.org"
						;;
					*)
						print -Pu2 "%F{005}Zflex: %F{001}Invalid value of tag: %F{003}from=%F{001}${arg#from=}"
						return 1
						;;
				esac
				;;

				# Tag to pin repo to a specific commit by its commit sha
			commit=*)
				tag_commit="${arg#commit=}"
				clone_args+=(--no-checkout)
				;;

			*)
				;;
		esac
	done

	# Set $tag_from to $ZFLEX_DEFAULT_FROM or "github" by default if "from=" tag wasn't used by user
	if [[ -z "$tag_from" ]] && [[ -n $ZFLEX_DEFAULT_FROM ]]; then
		tag_from="$ZFLEX_DEFAULT_FROM"
	else
		tag_from='github.com'
	fi

	# Set $tag_as to $ZFLEX_DEFAULT_AS or "plugin" by default if "as=" tag wasn't used by user
	if [[ -z "$tag_as" ]] && [[ -n $ZFLEX_DEFAULT_AS ]]; then
		tag_as="$ZFLEX_DEFAULT_AS"
	else
		tag_as='plugin'
	fi

	case "$subcommand" in
		clone)
			# Check if at least one repo was provided and return 1 other wise
			if ! (( $#repos )); then
				print -Pu2 '%F{005}Zflex: %F{001}No repos are found%f'
				return 1
			fi

			for repo in "${(j::)repos}"; do
				# Default remote repo is going to be cloned
				# from github if "from=" tag wasn't used
				# NOTE: It is not necessarily needed to used like
				# ${repo:h}/${repo:t} But I still do for readability
				repo_dir="$ZFLEX_STORAGE/$tag_as/$tag_from_dir/${repo:h}/${repo:t}"

				# Check if given repo have been cloned already
				{ if [[ ! -d "$repo_dir" ]]; then
						print -P "%F{005}Zflex: %F{003}Cloning %F{004}${repo:t}...%f"

						# Clone from destination chosen in $tag_from
						git clone ${clone_args[@]} "https://$tag_from/${repo:h}/${repo:t}" "$repo_dir"

						# Pin repo to specific commit sha if it is provided and
						# only one repo have been passed
						if [[ -n "$tag_commit" ]]; then
							git -C $repo_dir fetch -q origin "$tag_commit"
							git -C $repo_dir checkout -q "$tag_commit"
						fi
				fi } &
			done
			wait
			;;
		source)
			if ! (( $#repos )); then
				print -Pn '%F{005}Zflex: %F{003}Source all installed plugins? [%F{002}Y%F{003}/%F{001}n%F{003}]: %f'
				read -r confirmation
				case "$confirmation" in
					n|N)
						print "Aborted"
						return
						;;
					y|Y|''|*)
						for repo in $ZFLEX_STORAGE/plugin/**/*/.git(/); do
							# Get list of initfiles availible in repo and source first one
							initfiles=($repo/*.{plugin.zsh,zsh-theme,zsh,sh}(N))
							if (( $+functions[zsh-defer] )); then
								zsh-defer source $initfiles[1]
							else
								source $initfiles[1]
								zle && zle -M "Sourced ${repo:t}"
							fi
						done
						return
						;;
				esac
			else
				for repo in $ZFLEX_STORAGE/plugin/*/${repo:h}/${repo:t}/.git(/); do
					# Get list of initfiles availible in repo and source first one
					initfiles=(${repo:h}/*.{plugin.zsh,zsh-theme,zsh,sh}(N))
					if (( $+functions[zsh-defer] )); then
						zsh-defer source $initfiles[1]
					else
						source $initfiles[1]
						zle && zle -M "Sourced ${repo:t}"
					fi
				done
			fi
			;;
		update)
			for repo in $ZFLEX_STORAGE/**/*/.git(/); do
				print -P "%F{005}Zflex: %F{003}Updating...%f"
				git -C "$repo" pull --ff --recurse-submodules --depth=1 --rebase --autostash &> /dev/null &
			done
			wait
			;;
		*)
			print -Pu2 "%F{005}Zflex: %F{003}Unknown subcommand %F{001}$subcommand%f"
			;;
	esac

	# Peace of code which (re)compiles .zsh and .zsh-theme files of plugin repos
	if [[ $tag_as == 'plugin' ]]; then
		for file in $ZFLEX_STORAGE/**/*.zsh{,-theme}(N); do
			zrecompile -pq "$file"
		done
	fi
}
