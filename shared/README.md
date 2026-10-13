# Shared Contracts

Cross-runtime contracts shared conceptually by the Godot client and Rust server.

This directory is for schemas and generated/interchange definitions, not duplicated gameplay implementations.

## Intended contents

- protocol/message schemas;
- stable ID formats;
- data schemas;
- protocol/version constants;
- generated client/server bindings where appropriate;
- compatibility fixtures.

## Rule

Define a contract once, then generate/adapt bindings when practical.

Do not manually maintain two divergent definitions of the same network message or persisted data shape in GDScript and Rust.
