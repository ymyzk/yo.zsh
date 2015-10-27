# YO_API_TOKEN is required.
# Get it from https://dev.justyo.co/

YO_API_URL='https://api.justyo.co/yo/'
YO_HISTORY_FILE="$HOME/.yo_zsh_history"

function sendyo() {
  local location text url username
  local -a usernames
  local request_command message response
  local -a success_usernames
  local -A opts
  local color_clear='\e[0m'
  local color_ok='\e[0;32m'
  local color_fail='\e[0;31m'
  local tmpfile=$(mktemp 2>/dev/null || mktemp -t yo_zsh)

  # Parse options
  zparseopts -D -A opts h -help l: -location: u: -url: t: -text:

  if [[ -n "${opts[(i)-h]}" ]] || [[ -n "${opts[(i)--help]}" ]]; then
    echo "usage: $0 [options] username ..."
    echo
    echo "Options:"
    echo "  --help, -h"
    echo "      Show help"
    echo "  --location {lat,lon}, -l {lat,lon}"
    echo "      Send Yo Location"
    echo "  --url {url}, -u {url}"
    echo "      Send Yo Link"
    echo "  --text {text}, -t {text}"
    echo "      Send Yo with Text"
    return 1
  fi

  if [[ -n "${opts[(i)-l]}" ]]; then
    location="$opts[-l]"
  fi
  if [[ -n "${opts[(i)--location]}" ]]; then
    location="$opts[--location]"
  fi

  if [[ -n "${opts[(i)-u]}" ]]; then
    url="$opts[-u]"
  fi
  if [[ -n "${opts[(i)--url]}" ]]; then
    url="$opts[--url]"
  fi

  if [[ -n "${opts[(i)-t]}" ]]; then
    text="$opts[-t]"
  fi
  if [[ -n "${opts[(i)--text]}" ]]; then
    text="$opts[--text]"
  fi

  for username in "$@"; do
    usernames+=($(echo $username | tr '[:lower:]' '[:upper:]'))
  done

  # Send
  for username in $usernames; do
    # Prepare request
    request_command="curl --silent --write-out %{http_code} --output ${tmpfile} -d api_token=$YO_API_TOKEN -d username=$username $YO_API_URL"

    if [[ -n "$location" ]]; then
      message="Yo Location! $location"
      request_command="$request_command -d 'location=$location'"
    elif [[ -n "$url" ]]; then
      message="Yo Link! $url"
      request_command="$request_command -d 'link=$url'"
    else
      message="Yo!"
    fi

    if [[ -n "$text" ]]; then
      message="$message with \"$text\""
      request_command="$request_command -d 'text=$text'"
    fi

    message="$message $username"

    # Send request
    printf "[....] $message"
    response=$(eval "$request_command")

    # Show result
    if [ $response = '200' ]; then
      printf "\r[ ${color_ok}OK${color_clear} ] $message\n"
      success_usernames=($success_usernames $username)
    else
      printf "\r[${color_fail}FAIL${color_clear}] $message\n"
      cat "$tmpfile"
      echo
    fi
  done

  if [ -e $tmpfile ]; then
    rm "$tmpfile"
  fi

  _sendyo_save_history $success_usernames
}

function _sendyo_load_history() {
  if [ ! -e $YO_HISTORY_FILE ]; then
    touch $YO_HISTORY_FILE
  fi
  _sendyo_usernames=(${(@f)"$(< $YO_HISTORY_FILE)"})
}

function _sendyo_save_history() {
  if [ -z "${_sendyo_usernames+x}" ]; then
    _sendyo_load_history
  fi
  # Update cache
  _sendyo_usernames=($_sendyo_usernames $@)
  # Remove duplicates and save to file
  echo $_sendyo_usernames | tr ' ' '\n' | awk '!a[$0]++' > $YO_HISTORY_FILE
}

function _sendyo_args() {
  if [ -z "${_sendyo_usernames+x}" ]; then
    _sendyo_load_history
  fi
  _describe 'yo_usernames' _sendyo_usernames
}

function _sendyo() {
  _arguments \
    '(-h --help)'{-h,--help}'[Show help]' \
    '(-l --location -u --url)'{-l,--location}'[Send Yo Location {lat,lon}]:coordinate:()' \
    '(-l --location -u --url)'{-u,--url}'[Send Yo Link]:url:_urls' \
    '(-t --text)'{-t,--text}'[Send Yo with Text]:text:()' \
    '*:args:_sendyo_args'
}

compdef _sendyo sendyo
