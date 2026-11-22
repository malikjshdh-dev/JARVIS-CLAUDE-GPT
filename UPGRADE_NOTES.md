# J.A.R.V.I.S. ULTIMATE v4 source upgrade

This is an additive upgrade from the supplied v3 source. Existing UI, Groq/Fish Audio, MCP, skills, WhatsApp/Spotify flows, memory, reminders, notes, file tools, and existing native capabilities are retained.

## v4 Shizuku integration

- Adds official Shizuku API and provider dependencies (13.1.5) from Maven Central.
- Registers the official `ShizukuProvider` in the generated Android manifest.
- Adds native `shizukuStatus` diagnostics: binder availability, Jarvis authorization, backend UID and whether the backend identity is ADB, root, or other.
- Adds an explicit `requestShizukuPermission` native method; authorization is requested only when the user asks.
- Exposes `shizuku_status` and `shizuku_request_access` as Jarvis tools.
- Adds Shizuku status to the existing Android capability report.
- CI validates that the Shizuku dependency, provider, and bridge methods are present.

## Important scope boundary

This version integrates Shizuku discovery and user authorization. It does **not** yet run arbitrary shell commands or implement a Shizuku UserService. Those need a separate, narrowly allowlisted service with explicit user-facing actions; this build intentionally does not expose unrestricted privileged command execution to the AI. Shizuku ADB identity is not root and cannot access other apps' private data.

## How to use after building and installing

1. Keep Shizuku running.
2. Open the rebuilt Jarvis APK.
3. Ask Jarvis: `check Shizuku status`.
4. If it reports connected but not authorized, explicitly ask Jarvis to request Shizuku access and approve the Android prompt.
5. Ask for status again to confirm authorization.

## Verification

JavaScript and shell syntax are checked in CI. The Android build and runtime behavior still require the GitHub Actions APK build and a device test on the OPPO Reno 13.

## Sources

Implementation follows the official Shizuku API README: https://github.com/RikkaApps/Shizuku-API. Version 13.1.5 is the latest version listed in the official repository changelog at the time this source was prepared.
