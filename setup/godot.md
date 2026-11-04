# Godot 4.7 setup

Karma targets **Godot 4.7** (GL Compatibility). The editor is free and needs no
installer beyond extracting the binary.

## Windows

1. Download `Godot_v4.7-stable_win64.exe.zip` from
   https://godotengine.org/download/windows/
2. Extract to a folder, e.g. `C:\Godot\`.
3. (Optional) Add that folder to `PATH` so `godot` resolves, or use the full path.
4. Open `project.godot` in the extracted editor and press **F5**, or run:
   ```powershell
   & "C:\Godot\Godot_v4.7-stable_win64_console.exe" --path C:\path\to\karmagame
   ```

## Linux / WSL2

```bash
# Ubuntu/Debian
sudo apt update
sudo apt install -y godot4   # if packaged; otherwise download the binary
```

Or download the Linux binary from https://godotengine.org/download/linux/ and run:

```bash
chmod +x Godot_v4.7-stable_linux.x86_64
./Godot_v4.7-stable_linux.x86_64 --path /path/to/karmagame
```

## macOS

Download the macOS build from https://godotengine.org/download/macos/, drag `Godot.app`
to `/Applications`, then run:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --path /path/to/karmagame
```

## Headless tests

```bash
godot --headless --path . -s addons/gdUnit4/bin/GdUnitCmdTool.gd -a tests --ignoreHeadlessMode
```

## Notes

- The repo already ships the gdUnit4 and godot-mcp-toolkit addons under `addons/`.
- No third-party runtime dependencies are required for the game itself.