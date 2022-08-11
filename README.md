# subtitles

Basic roblox subtitle system.

## usage

get the `.rbxmx` [from the latest release](https://github.com/devpty/rbx-subtitles/releases), import it, and move the contents of the inner folders to the appropriate locations (e.g. `subtitles/ReplicatedStorage/*` becomes `/ReplicatedStorage/*`)

## building from source

- `make place` to build a roblox place file (`.rbxlx`) with the library and a test environment
- `make model` to build a roblox model file (`.rbxmx`) with the needed components inside
- `make all` to do both
- `make clean` to remove the build files
