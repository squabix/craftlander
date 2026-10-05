# CRAFTLANDER

Fight, explore, and sail across dangerous islands with discovery around every corner. Harvest rare materials and craft special gear to help you as you battle menacing fantastical creatures, build up your ship, and conquer a high-stakes final boss in a compact first-person island adventure.

[Steam page](https://store.steampowered.com/app/5051720)

## My Story

I'm SQUABIX. At the time of release, I am a 17-year-old developer who started building CRAFTLANDER in November of 2025. My journey making games started in 2019 with the [Godot Game Engine](https://godotengine.org/) when I was 10 years old. I loved building worlds that could be experienced by anyone, and game development seemed like the ultimate creative outlet between designing and coding and drawing and 3D modeling. This project serves as a capstone to all of the 7 years of work I have put into game development so far. I learned so much along the way. I am so proud of this project and I hope that you enjoy!

## The Future
I plan to continue adding content and polish to the game. I also plan on packaging much of the game's code for the Godot Asset Store for anyone to use in their own projects.

## Running from source

CRAFTLANDER needs [Godot 4.7](https://godotengine.org/download) (Mobile renderer, Jolt Physics) and [Blender](https://www.blender.org/download/), because the models are `.blend` files that Godot imports directly. Set the Blender path under Editor Settings > FileSystem > Import > Blender before you open the project for the first time. The first import takes a minute.

Two things are left out of this repository on purpose:

- **Audio.** Godot will log missing-resource errors for `res://assets/sound/...` and the game runs silent. Add your own files at those paths to hear it.
- **Steam.** The game runs fine without Steam. To use Steam features, run the Steam client and copy Valve's `steam_api64.dll` (Windows), `libsteam_api.so` (Linux), or `libsteam_api.dylib` (macOS) from the [Steamworks SDK](https://partner.steamgames.com/downloads/list) into the matching folder under `addons/godotsteam/`. Until you do, the editor logs a GodotSteam extension error that is safe to ignore.

## License

CRAFTLANDER's source and art are released under the [MIT License](LICENSE). The game's sound effects and music are not part of this repository and are not covered by it, so a build from source runs silent unless you add your own audio under `assets/sound/`.

Third-party components keep their own licenses:

- [GodotSteam](https://godotsteam.com) and [Godot Controller Icons](https://github.com/rsubtil/controller_icons) (MIT, see their folders under `addons/`)
- [Acid](https://www.dafont.com/acid.font) by Acid Type, used for menu text
- [JHC Sineas](https://www.dafont.com/jhc-sineas.font) by Anwar Patihan, used for the HUD and compass. It is free for personal and commercial projects but may not be sold or redistributed as a standalone font.
