#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  deveco-tools.sh <command> [args]

  dev <command> [args]

Short aliases:
  rr, crr, ds, lg, b, c, i, la, st, t

Commands:
  detect          Print resolved workspace and toolchain paths
  build           Build the signed HAP
  b               Alias for build
  clean           Clean Hvigor state
  c               Alias for clean
  package         Build package artifacts only
  sign            Sign the app package if needed
  install         Install the signed HAP to the connected device
  i               Alias for install
  launch          Start EntryAbility
  la              Alias for launch
  stop            Force-stop the bundle
  st              Alias for stop
  rerun           Build, install, and launch
  rr              Alias for rerun
  clean-rerun     Clean, build, install, and launch
  crr             Alias for clean-rerun
  device-status   List connected targets
  ds              Alias for device-status
  logs            Stream hilog
  lg              Alias for logs
  tasks           List Hvigor tasks
  t               Alias for tasks
  shell           Run a command on the device
  uninstall       Uninstall the bundle from the device
  dump            Inspect app/ability state
  jpid            List debug-capable process IDs
  attach          Attach debugger support command
  detach          Detach debugger support command
  appdebug        Inspect or set waiting-debug state
  file-send       Send a file to the device
  file-recv       Receive a file from the device
  bugreport       Collect a device bug report
  checkserver     Check HDC server compatibility
  prune           Remove stale Hvigor cache and unreferenced packages
  collectCoverage Generate coverage reports
  forward         Create a port forward
  fport-ls        List active forwards
  fport-rm        Remove a forward
  wait            Wait for a device to become available
  tconn           Connect to a device by key or TCP address
  start-server    Start the HDC server
  kill-server     Stop or restart the HDC server
  reboot          Reboot the device
  boot            Reboot or change boot mode
  smode           Toggle daemon root mode
  tmode           Switch transport mode
  keygen          Generate HDC keys
  mount           Remount partitions

Environment overrides:
  DEVECO_HOME     DevEco Studio installation root
  HDC_BIN         Path to hdc binary
  HVIGOR_NODE     Path to node binary used by hvigorw.js
  HVIGORW_BIN     Path to hvigorw.js
  WORKSPACE_ROOT  HarmonyOS workspace root
  BUNDLE_NAME     App bundle name
  MAIN_ABILITY    Main ability name
  HAP_PATH        Signed HAP path
EOF
}

script_dir() {
  local src="${BASH_SOURCE[0]}"
  while [[ -h "$src" ]]; do
    local dir
    dir="$(cd -P "$(dirname "$src")" && pwd)"
    src="$(readlink "$src")"
    [[ $src != /* ]] && src="$dir/$src"
  done
  cd -P "$(dirname "$src")" && pwd
}

find_workspace_root() {
  local dir="${1:-$(pwd)}"
  while [[ "$dir" != "/" ]]; do
    if [[ -f "$dir/AppScope/app.json5" && -f "$dir/entry/build-profile.json5" ]]; then
      printf '%s\n' "$dir"
      return 0
    fi
    dir="$(dirname "$dir")"
  done
  return 1
}

detect_deveco_home() {
  if [[ -n "${DEVECO_HOME:-}" && -d "${DEVECO_HOME:-}" ]]; then
    printf '%s\n' "$DEVECO_HOME"
    return 0
  fi
  local candidates=(
    "/Applications/DevEco-Studio.app/Contents"
    "$HOME/Applications/DevEco-Studio.app/Contents"
  )
  local c
  for c in "${candidates[@]}"; do
    [[ -d "$c" ]] && { printf '%s\n' "$c"; return 0; }
  done
  return 1
}

resolve_hdc_bin() {
  if [[ -n "${HDC_BIN:-}" && -x "${HDC_BIN:-}" ]]; then
    printf '%s\n' "$HDC_BIN"
    return 0
  fi
  local home
  home="$(detect_deveco_home)"
  local candidate="$home/sdk/default/openharmony/toolchains/hdc"
  [[ -x "$candidate" ]] && { printf '%s\n' "$candidate"; return 0; }
  return 1
}

resolve_hvigorw_bin() {
  if [[ -n "${HVIGORW_BIN:-}" && -f "${HVIGORW_BIN:-}" ]]; then
    printf '%s\n' "$HVIGORW_BIN"
    return 0
  fi
  local home
  home="$(detect_deveco_home)"
  local candidate="$home/tools/hvigor/bin/hvigorw.js"
  [[ -f "$candidate" ]] && { printf '%s\n' "$candidate"; return 0; }
  return 1
}

resolve_hvigor_node() {
  if [[ -n "${HVIGOR_NODE:-}" && -x "${HVIGOR_NODE:-}" ]]; then
    printf '%s\n' "$HVIGOR_NODE"
    return 0
  fi
  local home
  home="$(detect_deveco_home)"
  local candidate="$home/tools/node/bin/node"
  [[ -x "$candidate" ]] && { printf '%s\n' "$candidate"; return 0; }
  return 1
}

resolve_or_empty() {
  local fn="$1"
  if "$fn" >/dev/null 2>&1; then
    "$fn"
  else
    printf '\n'
  fi
}

workspace_root="${WORKSPACE_ROOT:-}"
if [[ -z "$workspace_root" ]]; then
  if ! workspace_root="$(find_workspace_root "$(pwd)")"; then
    workspace_root="$(find_workspace_root "$(script_dir)")" || true
  fi
fi

if [[ -z "$workspace_root" ]]; then
  echo "Unable to resolve workspace root. Set WORKSPACE_ROOT or run from the HarmonyOS workspace." >&2
  exit 1
fi

bundle_name="${BUNDLE_NAME:-com.uzero.bmpdf.hm}"
main_ability="${MAIN_ABILITY:-EntryAbility}"
hap_path="${HAP_PATH:-$workspace_root/entry/build/default/outputs/default/entry-default-signed.hap}"
command_lock_dir="$workspace_root/.deveco-tools.lock"

hdc="$(resolve_hdc_bin)"

acquire_command_lock() {
  local waited=0
  while ! mkdir "$command_lock_dir" 2>/dev/null; do
    sleep 1
    waited=$((waited + 1))
    if (( waited >= 300 )); then
      echo "Timed out waiting for another DevEco command to finish." >&2
      return 1
    fi
  done
  trap 'rmdir "$command_lock_dir" >/dev/null 2>&1 || true' EXIT INT TERM
}

release_command_lock() {
  trap - EXIT INT TERM
  rmdir "$command_lock_dir" >/dev/null 2>&1 || true
}

with_command_lock() {
  acquire_command_lock || return 1
  local status=0
  if "$@"; then
    status=0
  else
    status=$?
  fi
  release_command_lock
  return $status
}

run_build() {
  local node hvigorw
  node="$(resolve_hvigor_node)"
  hvigorw="$(resolve_hvigorw_bin)"
  (cd "$workspace_root" && "$node" "$hvigorw" \
    --mode module \
    -p module=entry@default \
    -p product=default \
    -p buildMode=release \
    -p requiredDeviceType=phone \
    assembleHap \
    --analyze=normal \
    --parallel \
    --incremental \
    --daemon)
}

run_clean() {
  (cd "$workspace_root" && run_hvigor_task clean)
}

run_package() {
  (cd "$workspace_root" && run_hvigor_task assembleApp)
}

run_sign() {
  (cd "$workspace_root" && run_hvigor_task SignApp)
}

run_install() {
  "$hdc" install -r "$hap_path"
}

run_launch() {
  "$hdc" shell aa start -b "$bundle_name" -a "$main_ability"
}

run_stop() {
  "$hdc" shell aa force-stop "$bundle_name"
}

run_rerun() {
  acquire_command_lock || return 1
  local status=0
  if run_build; then
    if run_install; then
      sleep 1
      if run_launch; then
        :
      else
        status=$?
      fi
    else
      status=$?
    fi
  else
    status=$?
  fi
  release_command_lock
  return $status
}

run_clean_rerun() {
  acquire_command_lock || return 1
  local status=0
  if run_clean; then
    if run_build; then
      if run_install; then
        sleep 1
        if run_launch; then
          :
        else
          status=$?
        fi
      else
        status=$?
      fi
    else
      status=$?
    fi
  else
    status=$?
  fi
  release_command_lock
  return $status
}

run_hvigor_task() {
  local task="$1"
  local node hvigorw
  node="$(resolve_hvigor_node)"
  hvigorw="$(resolve_hvigorw_bin)"
  shift
  (cd "$workspace_root" && "$node" "$hvigorw" "$task" "$@")
}

cmd="${1:-}"
shift || true

case "$cmd" in
  dev)
    cmd="${1:-}"
    shift || true
    ;;
  b) cmd="build" ;;
  c) cmd="clean" ;;
  i) cmd="install" ;;
  la) cmd="launch" ;;
  st) cmd="stop" ;;
  rr) cmd="rerun" ;;
  crr) cmd="clean-rerun" ;;
  ds) cmd="device-status" ;;
  lg) cmd="logs" ;;
  t) cmd="tasks" ;;
esac

case "$cmd" in
  detect)
    cat <<EOF
workspace_root=${workspace_root}
deveco_home=$(resolve_or_empty detect_deveco_home)
hdc_bin=$(resolve_or_empty resolve_hdc_bin)
hvigor_node=$(resolve_or_empty resolve_hvigor_node)
hvigorw_bin=$(resolve_or_empty resolve_hvigorw_bin)
bundle_name=${bundle_name}
main_ability=${main_ability}
hap_path=${hap_path}
EOF
    ;;
  build)
    with_command_lock run_build
    ;;
  clean)
    with_command_lock run_clean
    ;;
  package)
    with_command_lock run_package
    ;;
  sign)
    with_command_lock run_sign
    ;;
  install)
    with_command_lock run_install
    ;;
  launch)
    with_command_lock run_launch
    ;;
  stop)
    with_command_lock run_stop
    ;;
  rerun)
    run_rerun
    ;;
  clean-rerun)
    run_clean_rerun
    ;;
  device-status)
    "$hdc" list targets
    ;;
  logs)
    "$hdc" hilog "$@"
    ;;
  tasks)
    (cd "$workspace_root" && run_hvigor_task tasks)
    ;;
  shell)
    "$hdc" shell "$@"
    ;;
  uninstall)
    "$hdc" uninstall "$bundle_name"
    ;;
  dump)
    "$hdc" shell aa dump "$@"
    ;;
  jpid)
    "$hdc" jpid
    ;;
  attach)
    "$hdc" shell aa attach "$@"
    ;;
  detach)
    "$hdc" shell aa detach "$@"
    ;;
  appdebug)
    "$hdc" shell aa appdebug "$@"
    ;;
  file-send)
    "$hdc" file send "$@"
    ;;
  file-recv)
    "$hdc" file recv "$@"
    ;;
  bugreport)
    "$hdc" bugreport "$@"
    ;;
  checkserver)
    "$hdc" checkserver
    ;;
  prune)
    (cd "$workspace_root" && run_hvigor_task prune)
    ;;
  collectCoverage)
    (cd "$workspace_root" && run_hvigor_task collectCoverage)
    ;;
  forward)
    "$hdc" fport "$@"
    ;;
  fport-ls)
    "$hdc" fport ls
    ;;
  fport-rm)
    "$hdc" fport rm "$@"
    ;;
  wait)
    "$hdc" wait
    ;;
  tconn)
    "$hdc" tconn "$@"
    ;;
  start-server)
    "$hdc" start
    ;;
  kill-server)
    "$hdc" kill
    ;;
  reboot)
    "$hdc" shell reboot
    ;;
  boot)
    "$hdc" target boot "$@"
    ;;
  smode)
    "$hdc" smode "$@"
    ;;
  tmode)
    "$hdc" tmode "$@"
    ;;
  keygen)
    "$hdc" keygen "$@"
    ;;
  mount)
    "$hdc" target mount
    ;;
  ""|-h|--help|help)
    usage
    ;;
  *)
    echo "Unknown command: $cmd" >&2
    usage >&2
    exit 1
    ;;
esac
