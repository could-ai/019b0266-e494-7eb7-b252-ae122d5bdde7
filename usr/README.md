# MC Java Launcher

Minecraft Java Edition Launcher for Android with support for specific versions.

## Features

- Supports Android 10 (API 29) and above
- Languages: Korean and English (configurable in settings)
- Supported Minecraft versions: 1.21, 1.21.1, 1.21.10, 1.0 (Alpha 1.0.0), 1.19, 1.19.1, 1.16.5, 1.16
- Automatic installation of all supported versions on first run
- Play modes: Singleplayer only without login, Single + Multiplayer with Microsoft account
- Memory settings in MB (default 1024MB)
- Game UI: Touch controls compatible with PojavLauncher
- Additional features: Resource packs, mods (Forge/Fabric), maps, shaders
- Main screen button: "게임 파일 열기" to open .minecraft folder

## Note

This is a Flutter UI implementation. Actual Minecraft launching requires integration with PojavLauncher or similar native code for JVM execution on Android.