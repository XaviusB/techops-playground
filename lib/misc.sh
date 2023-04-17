
function log() {
  local level=${1?}
  shift
  local code
  local line
  code=''
  line="[$(date '+%F %T')] $level: $*"
  if [ -t 2 ]; then
    case "$level" in
    INFO) code=36 ;;
    DEBUG) code=35 ;;
    WARN) code=33 ;;
    ERROR) code=31 ;;
    *) code=37 ;;
    esac
    echo -e "\e[${code}m${line} \e[94m(${FUNCNAME[1]})\e[0m"
  else
    echo "$line"
  fi >&2
}

function wait_for_url() {
  local url
  local "${@}"
  url=${url:?need value url}
  log INFO "Waiting for ${url} to be ready"
  code=""
  set +e
  while [ "${code}" != "200" ]; do
    code=$(curl -s -o /dev/null -I -w "%{http_code}" "${url}")
    echo -n "."
    sleep 1
  done
  set -e
  echo "."
}
