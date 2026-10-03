extends Node
## The "signal bus": a shared noticeboard for game-wide announcements.
##
## Instead of every system needing to know about every other system, a script
## can announce something with `Events.settings_changed.emit()`, and anything
## that cares can listen with `Events.settings_changed.connect(my_function)`.
## Neither side needs to know the other exists.
##
## Add new signals here as features need them. (The @warning_ignore lines just
## tell Godot "yes, these are emitted from OTHER scripts, that's the point".)


## Emitted after the player changes an option (like invert Y) in Settings.
@warning_ignore("unused_signal")
signal settings_changed
