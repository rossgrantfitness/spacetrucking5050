class_name NPCData
extends Resource
## One person on the base: who they are and what they say. Each person gets
## their own .tres file in this folder; their look is a model scene chosen in
## the room where they stand.


## Their name, shown on the dialogue box.
@export var display_name: String = "Somebody"
## What kind of animal they are. The placeholder comm portrait draws a
## face for: raccoon, owl, walrus, hamster, pig, cat, crocodile, bunny,
## otter, sloth, dog
## (anything else gets plain round ears).
@export var species: String = "raccoon"
## Their gibberish voice: 1 = normal pitch, higher = squeakier, lower = deeper.
@export_range(0.4, 2.5, 0.05) var voice_pitch: float = 1.0
## What their voice sounds like: soft (round), square (8-bit beep), reed
## (nasal kazoo), gruff (low and raspy), chirp (birdy). See VoiceBlips.gd.
@export_enum("soft", "square", "reed", "gruff", "chirp") var voice_type: String = "soft"
## The musical key they talk in (0 = C, 2 = D, 4 = E, 5 = F, 7 = G, 9 = A, 11 = B).
@export_range(0, 11) var voice_key: int = 9
## Their scale: major (sunny), minor (grumbly), blues (laid-back), dreamy (floaty).
@export_enum("major", "minor", "blues", "dreamy") var voice_scale: String = "major"
## What they say when you talk to them, one box per line, if none of their
## `conversations` fits. Lines can use {bunny}, {husband}, {base} and
## {currency} (see res://data/world_names.tres).
@export var lines: PackedStringArray = PackedStringArray(["..."])
## Things they say depending on the story so far (the first that fits wins).
## See Conversation.gd.
@export var conversations: Array[Conversation] = []


## The conversation to use right now, or null (then they say `lines`).
func pick_conversation() -> Conversation:
	for conversation in conversations:
		if conversation != null and conversation.matches():
			return conversation
	return null


@export_group("Comm portrait")

## Their name on the comm portrait while flying (short, it's tiny).
@export var comm_name: String = ""
## Main fur (or feather, or scale) color for the placeholder portrait.
@export var fur_color: Color = Color(0.6, 0.6, 0.65)
## One accent color: their headset, hat or collar.
@export var accent_color: Color = Color(1.0, 0.4, 0.7)
