class_name ChatterSet
extends Resource
## Some things ONE person might say over the comms in ONE situation. When
## that situation comes up, the game picks a line at random from all the
## sets for it (avoiding the line it just used).
##
## Lines can use {bunny}, {husband}, {base} and {currency}. Keep them short:
## the comm box is small (about 60 letters fit on one card; longer lines
## flip to a second card).


enum Situation {
	TAKEOFF,  ## A few seconds after leaving the base.
	IDLE,  ## Nothing's happening: small talk, every minute or two.
	APPROACH,  ## Getting close to the destination.
	BONK,  ## Somebody heard that.
	BOOST,  ## Somebody saw that.
	LOW_FUEL,  ## The low-fuel light just came on.
	DELIVERED,  ## Cargo dropped off.
}

## Who's talking (their name, voice and portrait come from this file).
@export var speaker: NPCData
## When they say it.
@export var situation: Situation = Situation.IDLE
## What they might say, one call per line.
@export var lines: PackedStringArray = PackedStringArray()
