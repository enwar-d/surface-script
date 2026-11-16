# Surface Script

Modular Roblox UI & Executor Suite with Infinite Yield commands.

## Folder Structure

```text
SurfaceScript/
├── init.client.lua              # Main entry point & dock/window controller
├── loader.lua                   # GitHub modular loader for executors
├── Core/
│   ├── Config.lua               # Colors, iOS spring timings & client settings persistence
│   ├── Theme.lua                # Glass UI vs Solid UI & background BlurEffect
│   ├── Icons.lua                # Custom 21-circle SVG logo & vector icons
│   └── Notifications.lua        # iOS top notification banner (Swipe up + X/Checkmark fill)
├── Commands/
│   ├── PlayerCommands.lua       # Infinite Yield LocalPlayer commands (Basic + Advanced)
│   ├── TargetCommands.lua       # Infinite Yield Target Player commands (Basic + Advanced)
│   └── ScriptDatabase.lua       # Universal & Place-ID scripts + remote JSON database
└── UI/
    ├── Components.lua           # Shared iOS Settings grouped-card component builder
    ├── ScriptsPage.lua          # Universal & Game-specific script cards with Confirm execution
    ├── PlayerPage.lua           # LocalPlayer commands tab (supports Basic & Advanced Mode)
    ├── PlayersPage.lua          # Target player actions & live server player list
    └── SettingsPage.lua         # Appearance, Advanced Mode, Reset to Default & Remove Script
```

## Executing with:
```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/enwar-d/surface-script/refs/heads/main/loader.lua"))()
```
