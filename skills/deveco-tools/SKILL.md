---
name: deveco-tools
description: DevEco/HDC tools for this HarmonyOS workspace: rerun, clean-rerun, build, install, launch, logs, device status, and recovery commands.
---

# DevEco Tools

Use this skill for DevEco Studio and HDC operations in this workspace.

For any request that touches building, installing, launching, rerunning, logging, or recovering the HarmonyOS app on a device, prefer this skill first.

This is a general-purpose tool pack, not just a rerun shortcut. It covers the common local-device workflow for this HarmonyOS app.

Note: the actual skill name is `deveco-tools`. Treat common shorthand variants like `dev crr` as aliases for `clean-rerun` so they still resolve to this skill.

## Trigger Phrases

Treat these as strong triggers for this skill:

- `rerun`
- `rr`
- `clean-rerun`
- `crr`
- `rebuild and run`
- `dev crr`
- `build install launch`
- `run on device`
- `install to phone`
- `open on phone`
- `device status`
- `logs`
- `hilog`
- `Debug app`
- `DevEco`
- `HDC`
- `restart the app`
- `dev`
- `重新运行`
- `清理后重跑`
- `重新构建并运行`
- `安装到手机`
- `在手机上打开`
- `查看设备状态`
- `看日志`
- `看 hilog`
- `重启应用`
- `连接设备`
- `设备恢复`
- `装机`
- `查设备`
- `查日志`
- `拉起`
- `安装并启动`
- `重启并运行`
- `跑到手机`

Also treat short Chinese intent phrases as strong triggers, such as `重新运行`, `安装`, `启动`, `日志`, `设备`, `恢复`, and `调试` when they refer to this workspace or app.

Also treat `dev` as a shorthand trigger for this skill when the surrounding context is about this workspace or device workflow.

If the user message includes one of these phrases, prefer this skill unless the request is clearly unrelated.

## Portable Entry Script

Prefer the bundled shell wrapper when you want commands to work without depending on the current PATH or hard-coded local tool locations.
Resolve the wrapper to an absolute path for the current machine, assign it to a local shell variable such as `DEVECO_TOOLS_SH`, and reuse that variable for all commands. Do not use relative paths like `./scripts/deveco-tools.sh` from the workspace root. Do not guess alternate locations first; if a command fails, verify the resolved absolute path before trying anything else:

```bash
DEVECO_TOOLS_SH="/resolved/absolute/path/to/deveco-tools.sh"
"$DEVECO_TOOLS_SH" detect
```

```bash
"$DEVECO_TOOLS_SH" <command>
```

The script auto-discovers the workspace root and the DevEco toolchain when possible, and it accepts environment overrides such as `DEVECO_HOME`, `HDC_BIN`, `HVIGORW_BIN`, `HVIGOR_NODE`, `WORKSPACE_ROOT`, `BUNDLE_NAME`, `MAIN_ABILITY`, and `HAP_PATH`.

When available, use the script as the default entry point for `rerun`, `install`, `launch`, `logs`, and other common operations.

If the script is available, prefer it over raw tool invocations because it resolves the workspace root and the DevEco toolchain automatically.

### Detect

Use `detect` when you need to see exactly which workspace and toolchain paths the script resolved:

```bash
"$DEVECHO_TOOLS_SH" detect
```

This is the best first command when moving the skill to another machine or when a tool lookup fails.

## Priority Rules

1. Prefer the smallest command that solves the request.
2. For app issues, check device status and logs before recovery commands.
3. For build issues, use `clean` only when incremental state looks stale.
4. Use destructive or heavy recovery steps only when the user asks for them or simpler steps failed.
5. If the user says `rerun`, perform build + install + launch.
6. If the user says `clean-rerun`, add clean before build.

## Scope

Use this skill when the user wants any of these actions:

- build the app
- install the app on a connected device
- launch the app
- rerun the app
- stop the app
- inspect device state or logs
- discover Hvigor tasks

Do not use this skill for unrelated shell work.

## Project Defaults

The script resolves these automatically when possible:

- Workspace root
- DevEco installation root
- HDC binary
- Hvigor entry

Workspace-specific logical defaults:

- Bundle name: resolved by the script or `BUNDLE_NAME`
- Main ability: resolved by the script or `MAIN_ABILITY`
- Signed HAP: resolved by the script or `HAP_PATH`

If these values change, update the skill before using it again.

## Command Map

- `build` -> build the signed HAP
- `clean` -> clear Hvigor cache and stale build state
- `package` -> create the app package when the user wants packaging rather than rerun
- `sign` -> sign the app package if the workflow requires it
- `install` -> install the signed HAP to the connected device
- `launch` -> start `EntryAbility`
- `stop` -> force-stop the bundle
- `rerun` -> build + install + launch
- `clean-rerun` -> clean + build + install + launch
- `logs` -> stream hilog for the connected device
- `tasks` -> list Hvigor tasks
- `device-status` -> check whether a target device is connected
- `shell` -> run a command on the connected device
- `uninstall` -> remove the bundle from the connected device
- `reboot` -> reboot the device when needed for recovery
- `app-info` -> inspect app or process state on device
- `dump` -> inspect ability or app state through the script entry
- `jpid` -> list debug-capable process IDs through the script entry
- `attach` -> attach to a debug process when debugging is needed
- `detach` -> detach from a debug process when debugging is done
- `appdebug` -> inspect or set waiting-debug status through the script entry
- `file-send` -> send files to the connected device
- `file-recv` -> pull files from the connected device
- `boot` -> reboot or change device boot mode
- `smode` -> recovery privilege mode through the script entry
- `tmode` -> transport mode through the script entry
- `hilog` -> inspect or stream device logs through the script entry
- `checkserver` -> connection compatibility check through the script entry
- `keygen` -> key recovery through the script entry
- `forward` -> port forwarding through the script entry
- `prune` -> remove old build cache files and unreferenced packages through the script entry
- `collectCoverage` -> generate coverage statistics reports through the script entry
- `bugreport` -> collect a full device bug report through the script entry
- `wait` -> wait for the device to become available through the script entry
- `tconn` -> connect to a device through the script entry
- `start-server` -> start the server through the script entry
- `kill-server` -> stop or restart the server through the script entry
- `mount` -> remount partitions through the script entry
- `fport-ls` -> list active port forwarding tasks through the script entry
- `fport-rm` -> remove a port forwarding task through the script entry

## Categories

### Build

`build`, `clean`, `package`, `sign`, `tasks`, `prune`, `collectCoverage`

### Device

`device-status`, `install`, `launch`, `stop`, `uninstall`, `shell`, `file-send`, `file-recv`

### Debug

`rerun`, `clean-rerun`, `logs`, `app-info`, `dump`, `jpid`, `attach`, `detach`, `appdebug`, `bugreport`, `forward`, `fport-ls`, `fport-rm`

### Recovery

`reboot`, `boot`, `smode`, `tmode`, `checkserver`, `keygen`, `wait`, `tconn`, `start-server`, `kill-server`, `mount`

## Common Flows

### Normal App Rerun

1. Check device availability.
2. Build the signed HAP.
3. Install the signed HAP with replace mode.
4. Launch `EntryAbility`.

### Clean App Rerun

1. Clean only if the build state is stale.
2. Build the signed HAP.
3. Install the signed HAP.
4. Launch `EntryAbility`.

### App Crash Diagnosis

1. Check `$DEVECO_TOOLS_SH device-status`.
2. Stream `$DEVECO_TOOLS_SH logs`.
3. Use `$DEVECO_TOOLS_SH dump` for app state.
4. Use `jpid` if a debug attach is needed.

### Device Recovery

1. Use `checkserver`.
2. Use `wait` or `tconn` if the device is reconnecting.
3. Use `force-stop` or `uninstall` only if the app state is broken.
4. Use `reboot`, `boot`, `smode`, or `tmode` only as a last resort.

### File Transfer

1. Use `file send` for host to device.
2. Use `file recv` for device to host.
3. Use `bugreport` when logs are not enough.

## Standard Build

Use the project build command:

```bash
"$DEVECO_TOOLS_SH" build
```

## Clean

Use clean when the user explicitly asks for a fresh build or when incremental state looks wrong:

```bash
"$DEVECO_TOOLS_SH" clean
```

If the build cache needs a deeper reset, prefer the smallest cleanup that solves the issue.

## Package and Sign

Use packaging commands only when the user wants output artifacts without necessarily launching the app.

- Packaging path: project/package tasks from Hvigor
- Signing path: sign task or signed HAP output, depending on the current build flow

If the user asks for the exact task names, check `$DEVECO_TOOLS_SH tasks` first.

## Build Flow Guide

Use the lightest build flow that matches the user's goal:

- `build` when the user needs a fresh app artifact for device install
- `package` when the user wants output packages only
- `sign` when the user needs a signed deliverable or the workflow explicitly requires it
- `clean` before rebuild only when the cache or incremental state is suspected to be stale

Avoid running extra build stages unless the user asked for them or the current step depends on their output.

## Install

Install the signed HAP with replace mode:

```bash
"$DEVECO_TOOLS_SH" install
```

## Launch

Launch the app's main ability:

```bash
"$DEVECO_TOOLS_SH" launch
```

## Stop

Force-stop the bundle when the process is stale or the UI needs a hard refresh:

```bash
"$DEVECO_TOOLS_SH" stop
```

## Device Status

Check whether the device is available:

```bash
"$DEVECO_TOOLS_SH" device-status
```

If no target is listed, stop and ask the user to connect or authorize the device.

## Logs

Stream device logs when diagnosing runtime issues:

```bash
"$DEVECO_TOOLS_SH" logs
```

If the user asks for runtime diagnostics, prefer logs before trying more invasive recovery steps.

For targeted diagnosis, prefer searching the log output for the bundle name, ability name, or failure keyword the user mentioned.

## Server Check

Use `checkserver` when HDC behavior looks inconsistent or the host and daemon may be out of sync:

```bash
"$DEVECO_TOOLS_SH" checkserver
```

This is a low-risk diagnostic step and is safe to run before deeper recovery.

## Key Management

Use `keygen` only when HDC pairing or authorization appears broken:

```bash
"$DEVECO_TOOLS_SH" keygen <FILE>
```

Do not regenerate keys casually if the current pairing works.

## Forwarding

Use port forwarding only when a workflow needs host-to-device or device-to-host routing:

```bash
"$DEVECO_TOOLS_SH" forward <localnode> <remotenode>
```

Use forwarding for debugger tunneling or local service access when the user explicitly needs it.

## Shell

Run a shell command on the connected device when the user needs device-side inspection:

```bash
"$DEVECO_TOOLS_SH" shell <COMMAND>
```

Use shell for targeted checks such as package presence, process state, storage, or app data inspection.

## Dump

Use `dump` when the user wants ability-level state, launch status, or a fast runtime snapshot:

```bash
"$DEVECO_TOOLS_SH" dump
```

Prefer dump over guesswork when the app is installed but behavior is unclear.

## JPID

Use `jpid` when the user needs the debug process PID or when preparing for attach-based debugging:

```bash
"$DEVECO_TOOLS_SH" jpid
```

## Attach and Detach

Use attach/detach only for debug sessions:

```bash
"$DEVECO_TOOLS_SH" attach
```

```bash
"$DEVECO_TOOLS_SH" detach
```

If the user is not actively debugging, do not attach by default.

## App Debug

Use appdebug when waiting-debug behavior needs to be checked or controlled:

```bash
"$DEVECO_TOOLS_SH" appdebug
```

This is a niche debugging tool. Only use it when the user explicitly needs it or when a debugger cannot attach normally.

## Uninstall

Remove the app from the connected device when the user wants a clean reinstall or the install state is broken:

```bash
"$DEVECO_TOOLS_SH" uninstall
```

If the user wants to preserve data, ask before using an uninstall path.

## Reboot

Use reboot only when the device or system state is clearly stuck and simpler recovery steps failed:

```bash
"$DEVECO_TOOLS_SH" reboot
```

Reboot is a last-resort recovery step, not part of normal rerun.

## App Info

If the user asks whether the app is running or needs process inspection, inspect the device state before changing anything.

  - use `dump` for ability state
  - use `shell` for process and storage inspection
  - use `logs` for runtime errors

Prefer observation first, then recovery.

## File Transfer

Use file transfer commands when the user needs to move artifacts, logs, or test data between host and device.

Send a file to the device:

```bash
"$DEVECO_TOOLS_SH" file-send <local> <remote>
```

Receive a file from the device:

```bash
"$DEVECO_TOOLS_SH" file-recv <remote> <local>
```

If the user asks for sync-style transfer or mode-specific handling, use the script entry instead of inventing new ones.

## Boot and Recovery

Use boot and transport commands only for recovery or device maintenance:

```bash
"$DEVECO_TOOLS_SH" reboot
```

```bash
"$DEVECO_TOOLS_SH" boot
```

```bash
"$DEVECO_TOOLS_SH" smode -r
```

```bash
"$DEVECO_TOOLS_SH" tmode usb
```

Do not use these commands during normal app work unless the user explicitly requests device recovery.

## Tasks

List available Hvigor tasks when the user asks what build actions are supported:

```bash
"$DEVECO_TOOLS_SH" tasks
```

## Maintenance

Use maintenance commands when the user explicitly asks for cleanup or diagnostic reporting:

```bash
"$DEVECO_TOOLS_SH" prune
```

```bash
"$DEVECO_TOOLS_SH" collectCoverage
```

`prune` is for cache hygiene and package cleanup. `collectCoverage` is only for test or instrumentation workflows where coverage data exists.

Do not run maintenance commands as part of a normal rerun unless the user requested them.

## Device Management

Use these commands when you need to manage the device connection itself, not the app:

```bash
"$DEVECO_TOOLS_SH" wait
```

```bash
"$DEVECO_TOOLS_SH" tconn <key-or-address>
```

```bash
"$DEVECO_TOOLS_SH" start-server
```

```bash
"$DEVECO_TOOLS_SH" kill-server
```

Use `wait` when the device is booting or reconnecting. Use `tconn` for TCP-paired devices. Use `start` and `kill` only when HDC itself needs recovery.

## Recovery and Privilege

Use these commands only when the device is in a broken state and the user accepts recovery steps:

```bash
"$DEVECO_TOOLS_SH" mount
```

```bash
"$DEVECO_TOOLS_SH" smode -r
```

`target mount` is for partition remounting. `smode -r` adjusts daemon privilege for recovery scenarios.

## Port Forwarding Details

Prefer `fport` for a single route, `fport ls` to inspect active routes, and `fport rm` to remove one when a tunnel is no longer needed.

```bash
"$DEVECO_TOOLS_SH" fport-ls
```

```bash
"$DEVECO_TOOLS_SH" fport-rm <taskstr>
```

## Bug Report

Use bug reports when the user needs a full device snapshot for diagnosis:

```bash
"$DEVECO_TOOLS_SH" bugreport <FILE>
```

This is heavier than logs and should be used when logs are not enough.

## Installation Variants

If the workflow requires shared bundles or data-preserving cleanup, prefer the matching HDC option rather than a destructive fallback:

- `install -s` for shared bundle scenarios
- `uninstall -k` to remove the app while keeping data and cache

Only use these when the user specifically asks for those semantics.

## Rerun

For a normal rerun:

1. Check device availability.
2. Build the signed HAP.
3. Install the signed HAP with `-r`.
4. Launch `EntryAbility`.

If the app is already running but not refreshed, force-stop it first and then launch again.

If the user says only `rerun`, interpret it as this full flow.

## Clean Rerun

Use clean rerun only when the user explicitly asks for it or incremental state looks stale:

1. Clean caches if requested.
2. Build the signed HAP.
3. Install the signed HAP.
4. Launch `EntryAbility`.

## Failure Handling

- If build fails, report the failing command and the first useful error line.
- If install fails, verify the HAP path and the device connection, then retry once.
- If launch fails, force-stop the bundle and retry launch once.
- If the device is missing, stop and ask the user to connect it.
- If the issue looks like a device-side state problem, check logs and app state before uninstalling.
- If build artifacts look stale but the failure is unclear, use `clean` instead of random file deletion.
- If debugging is requested, use `jpid` and `dump` before forcing a restart.
- If file transfer fails, verify the source path, target path, and device connection before retrying.
- If the device recovery commands are needed, tell the user why they are necessary before running them.
- If HDC itself behaves strangely, run `checkserver` before escalating to reboot or key regeneration.
- If the device connection is unstable, use `wait` or `tconn` before retrying app actions.
- If forwarding behaves oddly, inspect with `fport ls` before recreating tunnels.

## Output Contract

When reporting back, keep it short and ordered:

1. Build result.
2. Install result.
3. Launch result.
4. Any blocking error, with the exact command that failed.

For a successful rerun, use:

`rerun complete: build succeeded, app installed, app launched on device.`

## Non-Goals

Do not use this skill for:

- build-only packaging
- unrelated shell commands
- modifying app code
- device cleanup unless the user asks for it
- destructive device operations unless they are necessary and the user has accepted the recovery step
- automatic debug attach sessions unless the user asked for interactive debugging
- recovery commands during normal app iteration unless the device is stuck or explicitly needs maintenance
- arbitrary key regeneration or forwarding setup when the user did not request it
- coverage generation without test or instrumentation context
- using heavy recovery commands before trying logs, checkserver, or wait/reconnect steps

## Example Triggers

- `rerun`
- `clean-rerun`
- `launch`
- `install`
- `stop`
- `logs`
- `tasks`

## Version

Version: 2.6.0
