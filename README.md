# ya-cd.yazi

> _"ya-cd" or "yazi-d" or "yet another cd"_

Just some `cd`-based utilities for the Yazi file manager.

> [!NOTE]
> This plugin is only created/tested for Unix-like systems, so if you're a rare
> Windows + Yazi user, I apologize

## Features

### Clipboard `cd`

If your clipboard contains the path of a file or a directory, tells Yazi to jump to that path!

```toml
# Example usage
[[mgr.prepend_keymap]]
desc = "Go to clipboard"
on = ["g", "v"]
run = "plugin ya-cd clipboard"
```

### Aoi Todo `cd`

This command swaps your directory with an "alternate" directory variable (initially set to `~`). 
Good for jumping back to where you were previously.

It's pretty much exactly like the "jump back" mark in Vim, if that makes it easier to explain. 
Hence, I recommend using `''` as the keybind to run this.

```toml
# Example usage
[[mgr.prepend_keymap]]
desc = "Go to previous jump"
on = ["'", "'"]
run = "plugin ya-cd swap"
```
