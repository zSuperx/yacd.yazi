# ya-cd.yazi

> _"ya-cd" or "yazi-d" or "yet another cd"_

Just some `cd`-based utilities for the Yazi file manager.

> [!NOTE]
> This plugin is only created/tested for Unix-like systems, so if you're a rare
> Windows + Yazi user, I apologize. However, contributions are always welcome.

## Features

I tend to add features as I find the need for them, but I'm always open to
suggestions.

### Clipboard `cd`

If your clipboard contains the path of a file or a directory, tells Yazi to
jump to that path!

```toml
# Example usage
[[mgr.prepend_keymap]]
desc = "Go to clipboard"
on = ["g", "v"]
run = "plugin ya-cd clipboard"
```

### Aoi Todo `cd`

This command swaps your directory with an "alternate" directory variable
(initially set to `~`). Good for jumping back to where you were previously.

It's pretty much exactly like the "jump back" mark in Vim, if that makes it
easier to explain (though that's a far more boring name). Hence, I recommend
using `''` as the keybind to run this.

```toml
# Example usage
[[mgr.prepend_keymap]]
desc = "Go to previous directory"
on = ["'", "'"]
run = "plugin ya-cd swap"
```
