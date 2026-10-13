# Client

Godot 4.7.x client/presentation project.

This directory will contain `project.godot` and all runtime code/assets that must execute on the player device.

## Owns

- rendering and 2.5D presentation;
- camera;
- player input/touch controls;
- UI/UX;
- visual/audio effects;
- client interpolation/presentation;
- local test worlds;
- networking adapter to the authoritative server.

## Does not own

- canonical economy;
- canonical item custody;
- persistent world truth;
- authoritative population/ecology/war outcomes.

Those belong to `server/`.

## Baseline

- Godot 4.7.x stable line;
- GDScript-first;
- Compatibility renderer is the Web baseline;
- real Android testing from the beginning.
