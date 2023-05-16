# Tmux session wizard

<img width="500" alt="tmux-session-wizard" src="https://user-images.githubusercontent.com/14043848/195257556-bc2cfe0a-a1c7-4e29-9741-776eaf0caa06.png">


One prefix key to rule them all (with [fzf](https://github.com/junegunn/fzf) & [zoxide](https://github.com/ajeetdsouza/zoxide)):
- Creating a new session from a list of recently accessed directories
- Naming a session after a folder/project
- Switching sessions
- Viewing current or creating new sessions in one popup

### Elevator Pitch

Tmux is powerful, yes, but why is creating/switching sessions (arguably its main feature) is so damn hard to do? To create a new session for a project you have to run `tmux new-session -s <session-name> -c <project-folder>`. What if you're inside tmux? Oh, wait you have to use `-d` followed by `tmux switch-client -t <session-name>`. Oh, wait again! What if you're outside tmux and you want to attach to an existing session? now you have to run `tmux attach -t <session-name>` instead. What if you can't remember whether you have a session for that project or not. Guess what? Now you have to run `tmux has-session -t <session-name>`. What if your project folder contains characters not accepted by tmux as a session name? What if you want to show a list of existing sessions? You run `tmux list-sessions`. What if you want to create a session for a project you've recently navigated to? What if, what if, what if.... HOW IS THAT BETTER THAN HAVING 20 TERMINAL WINDOWS OPEN?

What if you could use 1 prefix key to do all of this? Read on!

### Features

`prefix + T` (customisable) - displays a pop-up with [fzf](https://github.com/junegunn/fzf) which displays the existing sessions followed by recently accessed directories (using [zoxide](https://github.com/ajeetdsouza/zoxide)). Choose the session or the directory and voila! You're in that session. If the session doesn't exist, it will be created.

### Required
You must have [fzf](https://github.com/junegunn/fzf), [zoxide](https://github.com/ajeetdsouza/zoxide) installed and available in your path.

### Installation with [Tmux Plugin Manager](https://github.com/tmux-plugins/tpm) (recommended)

Add plugin to the list of TPM plugins in `.tmux.conf`:

```tmux
set -g @plugin '27medkamal/tmux-session-wizard'
```

Hit `prefix + I` to fetch the plugin and source it. That's it!

### Manual Installation

Clone the repo:

    $ git clone https://github.com/27medkamal/tmux-session-wizard ~/clone/path

Add this line to the bottom of `.tmux.conf`:

```tmux
run-shell ~/clone/path/tmux-session-wizard.tmux
```

Reload TMUX environment with `$ tmux source-file ~/.tmux.conf`, and that's it.

### Customisation

You can customise the prefix key by adding this line to your `.tmux.conf`:

```tmux
set -g @session-wizard 'T'
```

You can also customise the height and width of the tmux popup by adding the follwing lines to your `.tmux.conf`:

```tmux
set -g @session-wizard-height 40
set -g @session-wizard-width 80
```

### (Optional) Using the script outside of tmux

Run the following to download the script and add it to your path.
```bash
curl https://raw.githubusercontent.com/27medkamal/tmux-session-wizard/master/session-wizard.sh > /usr/local/bin/t && chmod u+x /usr/local/bin/t
```
You can then run `t` from anywhere to use the script. 

You can also run `t` with a relative or absolute path to a directory (similar to [zoxide](https://github.com/ajeetdsouza/zoxide)) to create a session for that directory. For example, `t ~/projects/my-project` will create a session named `my-project` and cd into that directory.

Also, depending on the terminal emulator you use, you can make it always start what that script.

### Inspiration
- ThePrimeagen's [tmux-sessionizer](https://github.com/ThePrimeagen/.dotfiles/blob/master/bin/.local/scripts/tmux-sessionizer)
- Josh Medeski's [t-smart-tmux-session-manager](https://github.com/joshmedeski/t-smart-tmux-session-manager)

### License

[MIT](LICENCE.md)
