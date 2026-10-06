class_name OverdriveCall
extends Resource
## One comm call while you push past boost's top speed (OVERDRIVE; see
## FlightSandbox._watch_overdrive). Each is made once per climb: when the
## speed passes `at_kmh`, or the hull strain passes `at_strain` (set one;
## leave the other at 0). Calm down below boost's top speed and they can
## all happen again next time.


@export_range(0.0, 20000.0, 50.0, "suffix:km/h") var at_kmh: float = 0.0
@export_range(0.0, 1.0, 0.05) var at_strain: float = 0.0
## Who calls (their name, voice and portrait).
@export var speaker: NPCData
@export_multiline var line: String = ""
