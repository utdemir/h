function _h_init() {
  _h_workspace="${H_WORKSPACE:-"$HOME/workspace"}"
}

function _h_main() {
  _h_init
  local go="${H_GO:-"cd"}"

  if [[ "$_h_shell" == "zsh" ]]; then
    setopt local_options KSH_ARRAYS BASH_REMATCH
  fi

  local ghchr="[a-zA-Z0-9-]"

  case "$#" in
    0)
      local loc=""
    ;;
    1)
      if [[ -d "$_h_workspace/$1" ]]; then
        local loc="$1"
      elif [[ "$1" =~ ^($ghchr+)/($ghchr+)$ ]] ||
           [[ "$1" =~ ^github.com/($ghchr+)/($ghchr+)(.git)?/?$ ]] ||
           [[ "$1" =~ ^https://github.com/($ghchr+)/($ghchr+)(.git)?/?$ ]] ||
           [[ "$1" =~ ^git@github.com/($ghchr+)/($ghchr+)(.git)?/?$ ]]; then
        local user="${BASH_REMATCH[1]}"
        local repo="${BASH_REMATCH[2]}"
        local url="https://github.com/$user/$repo"
        local loc="github.com/$user/$repo"
      else
        echo "invalid-syntax" >&2
        return 1
      fi
    ;;
    2)
      local url="$1"
      local loc="$2"
    ;;
    *)
      echo "invalid-syntax" >&2
      return 1
  esac

  local target="$_h_workspace/$loc"
  if ! [[ -d "$target" ]]; then
    local tmpdir="$(mktemp -d)"
    git clone "$url" "$tmpdir"
    if ! [[ $? -eq 0 ]]; then
      echo "Error fetching \"$url\"" >&2
      rm -rf "$tmpdir"
      return 1
    fi
    mkdir -p "$(dirname "$target")"
    mv "$tmpdir" "$target"
  fi

  $go "$target"
}

function _h_get_repos() {
  find "$_h_workspace" \
    -maxdepth 4 -type d -name .git \
    -printf '%P\n' \
    | xargs dirname \
    | sort
}

function _h_get_completions() {
  _h_init
  entered="$1"
  rs="$(_h_get_repos)"
  if [[ -z "entered" ]]; then
    _h_get_repos
  else
    echo "$rs" | grep -E "(/|^)$entered"
  fi
}

function _h_complete_bash() {
  COMPREPLY=( )
  case "$COMP_CWORD" in
    1)
    cur="${COMP_WORDS[COMP_CWORD]}"
    while IFS= read -r line; do
        COMPREPLY+=("$line")
    done < <(_h_get_completions "$cur")
    COMPREPLY+=("$line" )
    declare -p COMPREPLY
    echo COMPREPLY
    ;;
  esac
}

function _h_complete_zsh() {
  while IFS= read -r line; do
    compadd -q "$line"
  done < <(_h_get_completions "$PREFIX")
}

function h_init_bash {
  _h_shell=bash
  function h() {
    _h_main "$@"
  }
  complete -o nospace -F _h_complete_bash h
}

function h_init_zsh {
  _h_shell=zsh
  function h() {
    _h_main "$@"
  }
  compdef _h_complete_zsh h
}
