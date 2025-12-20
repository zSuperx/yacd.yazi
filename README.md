# yacd.yazi

> _"yacd" or "yazi-d" or "yet another cd"_

Just some `cd`-based utilities for the Yazi file manager.

> [!NOTE]
> This plugin is only created/tested for Unix-like systems, so if you're a rare
> Windows + Yazi user, I apologize. However, contributions are always welcome.

## Setup

One way or another, create a directory named `yacd.yazi/` with this repo's
`main.lua` into your `~/.config/yazi/plugins/` directory. Then, add a
`require("yacd").setup()` to your `init.lua`.

For example, if using Nix + Home Manager, the below will suffice:
```nix
{
  programs.yazi = {
    enable = true;

    plugins = {
      yacd = pkgs.fetchFromGitHub {
        owner = "zSuperx";
        repo = "yacd.yazi";
        rev = "...";
        hash = "...";
      };
    };

    initLua = ''
      require("yacd").setup()
    '';
  };
}
```

## Features

I tend to add features as I find the need for them, but I'm always open to
suggestions. That being said, below are the features that have been implemented
so far!

### Clipboard `cd`

If your clipboard contains the path of a file or a directory, tells Yazi to
jump to that path!

```toml
# Example usage
[[mgr.prepend_keymap]]
desc = "Go to clipboard"
on = ["g", "v"]
run = "plugin yacd clipboard"
```

### Vim-like marks

As the name suggests, allows the setting of marks with `yacd set_mark`
(currently only `a-z` are supported). 

Marks can be jumped to with `yacd goto_mark`.

Both commands will display a which-key-like popup asking which mark to
set/follow.

In addition to marks `a-z`, the `'` mark is automatically set whenever a direct
`cd` occurs. This is great for returning to where you last jumped to!

_(Marks will be preserved after Yazi quits, and restored on next run)_

```toml
# Example usage
[[mgr.prepend_keymap]]
desc = "Go to mark"
on = ["'"]
run = "plugin yacd goto_mark"

[[mgr.prepend_keymap]]
desc = "Set mark"
on = ["m"]
run = "plugin yacd set_mark"
```
