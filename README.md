# Flood Timelines Build System

A script-based alternative to Timelines for **Flood Escape 2** map makers. Define your map's events as readable Luau build scripts, organise them across files, and compile them into native Timelines objects with one click — no more hand-wrangling `Configuration` and `ObjectValue` instances in the Explorer.

> **Current Version:** v1.0.0

---

## Installation
1. Download the latest plugin file from the [Releases](https://github.com/myralune/ftbs/releases) page, **or** install it from the [Creator Store](https://create.roblox.com/store/asset/101426294063822/Flood-Timelines-Build-System).
2. Drag the .rbxm into studio, right click the folder and hit "Save as Local Plugin" ([or install via the Store](https://create.roblox.com/store/asset/101426294063822/Flood-Timelines-Build-System)), then restart Studio.
3. Open the **FTBS** toolbar button to toggle the plugin window.

Note: It is recommended to install via the [creator store](https://create.roblox.com/store/asset/101426294063822/Flood-Timelines-Build-System) as you will get automatic updates.

---

## Quick start

1. Click **New** in the plugin window to create a build script from the template. It's placed in your map and opened in the script editor.
2. Edit the `build` function to describe your timelines (see below).
3. Select the script (or your map) and click **Build** — or use the **Build** button in the Scripts tab.
4. A `Timelines` folder is generated inside your map, ready for the engine.

A build script is just a `ModuleScript` whose source begins with the header `--$ftbs01`.

---

## Writing a build script

Your script returns a `build` function. It's handed four constructors plus the active config table:

```lua
--$ftbs01

local map = script:FindFirstAncestorWhichIsA("Model") or workspace
local conf

function build(create, macro, folder, container, config)
	-- A timeline a conditional can branch to
	local onFail = create ("timeline", "Example_OnFail") {
		attributes = {},
	}

	create ("timeline", "Example_Main") {
		attributes = { Trigger_Button = 1 },

		create ("xframe", "Rise") {
			attributes = { XFrame_Function = "SetProperties", XFrame_Timestamp = 0 },
			target = map.Water,
		},

		create ("xframe", "Check") {
			attributes = { XFrame_Function = "Conditional", Conditional_Operator = "==" },
			target = map.Gate,

			-- branch to another timeline by handle (or by name string)
			create ("pointer", "Conditional_Timeline") {
				target = onFail,
			},
		},

		-- cosmetic grouping inside the timeline
		folder "Extras" {
			create ("xframe", "Decoration") {
				attributes = {},
				target = map.Decoration,
			},
		},
	}
end

return { build = build, map = map, conf = conf }
```

> The template includes a type-stub footer below the `build` function that gives you autocomplete for `create`, `macro`, `folder`, and `container`. Leave it in place.

### `create(type, name)(props)`

The core constructor. `type` is `"timeline"`, `"xframe"`, or `"pointer"`.

| Type | Bakes to | Notes |
|------|----------|-------|
| `timeline` | `Configuration` | Top-level event group. Returns a handle you can reference in pointers. |
| `xframe` | `ObjectValue` | A single keyframe/action. `target` becomes the `ObjectValue.Value`. |
| `pointer` | `ObjectValue` (child of an xframe) | A named link to another timeline; `target` is a handle or a timeline name string. |

`props` accepts:
- `attributes` : a table written verbatim as instance attributes (`XFrame_Function`, `Trigger_Button`, `Conditional_Operator`, etc.).
- `target` : for xframes, an `Instance` (the `.Value`); for pointers, a timeline handle or name.
- Nested `create`/`folder`/`container` calls as positional children.

### `folder(name)(children)` and `container(class, name)(children)`

Cosmetic nesting **inside** a timeline. `folder` is shorthand for `container("Folder", name)`. Use these to keep large timelines tidy in the Explorer — they don't affect engine behaviour.

### `macro(fn)`

Run a function that returns timelines or xframes, for procedural generation. Use it in the function body (to produce timelines) or inside a timeline (to produce xframes):

```lua
macro(function()
	local frames = {}
	for i = 1, 5 do
		frames[i] = create ("xframe", "Step" .. i) {
			attributes = { XFrame_Timestamp = i },
		}
	end
	return frames
end)
```

---

## Forks

Drop another build script (also headed `--$ftbs01`) **under** your main one and it becomes a *fork*. Every fork runs against the **same shared registry**, so:

- Timeline names are shared project-wide. You should keep them unique.
- A pointer in one file can reference a timeline defined in another by name.
- Forks bake into a folder path under `Timelines` mirroring their location beneath the main script (e.g. a fork at `Main/Sections/Drop` bakes into `Timelines/Sections/Drop`).

This lets you split a big map across multiple files without losing cross-references.

---

## Configurations

Define a `conf` table to build different variants of a map from one script. The plugin merges `$default` with whichever named configuration you pick at build time, and passes the result as the `config` argument:

```lua
conf = {
	["$default"] = { hardMode = false },

	["hard"] = {
		["$dispname"] = "Hard Mode",
		hardMode = true,
	},
}
```

```lua
function build(create, macro, folder, container, config)
	if config.hardMode then
		-- emit extra timelines / xframes
	end
end
```

When a script exposes multiple configurations, **Build** and **Queue** prompt you to choose one.

---

## The plugin window

| Tab | What it does |
|-----|--------------|
| **Scripts** | Lists every build script found in the place, with its map, available configs, and per-row **Queue** / **Build** buttons. Right-click a row for build, duplicate, delete, edit config, show in Explorer, and export. |
| **Queue** | Batch up multiple `(script, configuration)` pairs and build them together. Toggle which items are included, then **Build Selected**. |
| **Cheatsheet** | Quick reference for the build script API and attribute conventions. |
| **About** | Version, authors, and license. |

Toolbar actions: **New**, **Import**, **Export**, **Generate**, **Refresh**.

---

## Generating from existing Timelines

Already have a map with a built `Timelines` folder? Click **Generate**, pick the map, and the plugin reverse-engineers a build script from it:

- Each `Configuration` → `create ("timeline", …)`, each `ObjectValue` → `create ("xframe", …)` with relative `map.path.to.target` references.
- Pointer `ObjectValue`s → `create ("pointer", …)` referencing timelines by name.
- Group folders containing timelines become **fork modules**, nested to match the folder structure.

The result is parented to the map, selected, and opened for review.

> **Note:** configurations are compile-time only and can't be recovered from baked output, so the generated `conf` table is left empty. Always review generated scripts and back up the original `Timelines` folder before rebuilding.

---

## Import / Export

- **Import** — bring a `.ftbs.luau` build script in from your filesystem as a `ModuleScript`.
- **Export** — save a build script (and its forks) out to a Roblox model file.

---

## Building from source

The plugin is written in [Luau](https://luau.org/) using [Vide](https://github.com/centau/vide) for its reactive UI. Structure is as follows:

```
ftbseditor/
├── ftls-build-system.plugin.luau   -- plugin entry point
├── core/                            -- build, bake, codegen, discovery, queue
├── components/                      -- Vide UI (toolbar, viewport, panels, modal, …)
├── scripts/                         -- build script template + cheatsheet
└── vide/                            -- bundled Vide
```

You can view the source code on github, or drag and drop the .rbxm into studio to see it.

---

## License

Licensed under the [GNU General Public License v3.0](LICENSE).

## Authors

- **Contrastual** — author, maintainer, build system syntax
- **myralune** — author and maintainer
