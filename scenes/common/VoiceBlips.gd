class_name VoiceBlips
## The gibberish voices: which blip sound a character uses, and which note
## each letter plays. Every character talks in their own musical key and
## scale (set in their NPC data file), so their chatter sounds like a little
## tune of their own instead of random beeps: Chang Ma grumbles in C minor,
## Pip squeaks in A major, Sal croons the blues.
##
## Each letter always plays the same note of the scale (so the same word
## sounds the same every time), questions lift at the end, and shouting
## (a line ending in "!") goes up a little.


## The blip sounds (all tuned to the note A). See SfxSynth.make_voice.
const STREAMS := {
	"soft": preload("res://audio/generated/blip.wav"),
	"square": preload("res://audio/generated/voice_square.wav"),
	"reed": preload("res://audio/generated/voice_reed.wav"),
	"gruff": preload("res://audio/generated/voice_gruff.wav"),
	"chirp": preload("res://audio/generated/voice_chirp.wav"),
}
## The notes of each scale, in semitones up from the key's note.
const SCALES := {
	"major": [0, 2, 4, 7, 9, 12],  # Major pentatonic: sunny, can't sound wrong.
	"minor": [0, 3, 5, 7, 10, 12],  # Minor pentatonic: grumbly, mellow.
	"blues": [0, 3, 5, 6, 7, 10],  # Laid-back, a bit sleazy.
	"dreamy": [0, 2, 4, 6, 9, 11],  # Floaty (lydian): spacey people.
}
## The blip's own note: A, which is 9 semitones above C.
const BLIP_NOTE: int = 9


## The blip sound for a voice type ("soft" if it's unknown).
static func stream(kind: String) -> AudioStream:
	return STREAMS.get(kind, STREAMS["soft"])


## How much to speed up or slow down the blip for letter `index` of `text`
## (a pitch scale: 2 = an octave up).
## register: the speaker's voice_pitch (1 = around the blip's note).
## key: their key, 0 = C, 1 = C#, ... 11 = B.
static func pitch_scale(register: float, key: int, scale: String, text: String, index: int) -> float:
	var steps: Array = SCALES.get(scale, SCALES["major"])
	var letter := text.unicode_at(index) if index < text.length() else 0
	if letter >= 65 and letter <= 90:
		letter += 32  # Lower case: "A" sounds like "a".
	var degree := letter % (steps.size() - 1)
	# Questions lift over their last few letters.
	if text.strip_edges().ends_with("?") and index > text.length() - 6:
		degree += 2
	var note: int = steps[degree % steps.size()] + 12 * floori(degree / float(steps.size()))
	if text.strip_edges().ends_with("!"):
		note += 3
	# Put the scale in the octave around the speaker's register.
	var center := 12.0 * log(maxf(register, 0.05)) / log(2.0)  # Semitones from the blip's note.
	var root := float(key - BLIP_NOTE)
	root += 12.0 * roundf((center - root - 4.0) / 12.0)
	return pow(2.0, (root + note) / 12.0)
