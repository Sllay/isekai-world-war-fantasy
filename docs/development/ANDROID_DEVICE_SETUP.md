# Android Development Device Setup

- **Status:** Bootstrap checklist
- **Updated:** 2026-10-13

## Goal

Use a real Android device as the primary early client-development and performance-validation target without making the phone responsible for every heavy server/compiler workload.

## Required Apps

- Godot Android Editor from the official Godot distribution/Google Play listing;
- GABE (Godot Android Build Environment) when Gradle-based Android export/build is needed;
- a Git-capable workflow for obtaining repository revisions on the device.

Termux is optional. It is useful for Git/shell workflows, but the project must not require unsupported local Codex-on-Android behavior.

## Godot Baseline

Use the same stable Godot 4.7.x line selected by M1 proofs.

For Web-oriented client tests, keep the project compatible with the Compatibility renderer baseline.

## Repository Location

The Android Godot Editor and the chosen Git workflow must both be able to access the project checkout.

Avoid storing secrets in publicly/shared Android storage.

Do not track host-only heavy directories such as:

- Rust `target/`;
- `node_modules/`;
- local databases;
- Codex/MCP caches;
- generated profiling captures.

The root `.gitignore` protects these classes of files.

## First Device Proof

Once `client/project.godot` exists:

1. obtain the target Git revision on Android;
2. open `client/project.godot` in the Godot Android Editor;
3. confirm project imports complete;
4. run the minimal test scene;
5. confirm touch input works;
6. rotate the camera if the proof includes it;
7. record FPS/frame-time and obvious device-specific issues;
8. close/reopen the editor and confirm the project remains healthy;
9. pull a later revision and verify normal iteration works without manually reconstructing files.

## GABE

GABE is only required for workflows that need Gradle-based Android builds/plugins.

When needed:

1. install GABE on the same Android device;
2. install its Rootfs from inside GABE;
3. install Godot Android build templates;
4. enable **Gradle Build** in the Android export preset;
5. perform a test export/build.

Do not introduce Gradle-specific customization during the initial M1.2 scene proof unless a real requirement needs it.

## Mobile Performance Rule

The Android result is the source of truth for mobile-client performance.

Desktop/headless benchmarks are useful for regression detection but cannot approve a mobile performance budget.

For each meaningful benchmark record:

- exact Git commit;
- Godot version;
- renderer;
- device model/OS when sharing the result;
- scene/test scenario;
- average/low frame-time observations;
- memory where measurable;
- thermal/throttling notes for longer runs.

## MCP on Android

Direct live MCP control of the Android Godot editor is optional research, not a project dependency.

The supported bootstrap path is:

- Codex + MCP run on a connected development host;
- GitHub synchronizes changes;
- Android runs the exact revision for real-device validation.

If a later Android-local bridge is proven reliable, it can be added as a convenience workflow through a separate ADR without replacing this baseline.
