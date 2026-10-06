#!/usr/bin/env python3
"""Writes res://data/crew/crew.tres (and the new crew members' NPC files)
from the plain lists below. Edit the lists and re-run:

    python3 tools/crew_data/make_crew.py

(You can also edit crew.tres directly in Godot's inspector; re-running this
script overwrites those edits.)

Situations: ANY, IN_FLIGHT, PARKED, NIGHT, DAY, HAS_JOB, NO_JOB, JUST_PAID.
Rooms: apartment, hallway, dispatch, galley, engine, cargo.
Poses: stand, sit, sleep, work, eat, read, dance, wave, lean.
Props: mug, wrench, book, cards, broom, clipboard, plate, guitar.
Lines can use {bunny}, {husband}, {company}, {cargo}, {place}.
"""
import os

ROOT = os.path.join(os.path.dirname(__file__), "..", "..")
ROOMS = {r: "res://scenes/hub/%s.tscn" % n for r, n in [
    ("apartment", "Apartment"), ("hallway", "Hallway"), ("dispatch", "Dispatch"),
    ("galley", "Galley"), ("engine", "EngineRoom"), ("cargo", "CargoBay")]}
SITUATIONS = ["ANY", "IN_FLIGHT", "PARKED", "NIGHT", "DAY", "HAS_JOB", "NO_JOB", "JUST_PAID"]

# (id, room, spot, pose, prop, situation, weight, needs_flag, [lines])
A = lambda *a: a

CREW = [
    {"id": "dottie", "npc": "res://data/npcs/dispatch_morning.tres", "visual": "res://scenes/hub/crew/DottieVisual.tscn",
     "role": "Dispatcher", "menu": "job_board", "post": "counter",
     "greetings": ["Morning, {bunny}. You look like you slept in your jacket again.", "Hey hon. Coffee's fresh-ish.",
                   "There she is. The pride of {company}.", "Hon. You eat today? Eat something."],
     "activities": [
        A("counter", "dispatch", "Counter", "stand", "clipboard", "ANY", 3.0, "", ["Dispatch, this is Dottie. Oh, it's you. Hi, hon."]),
        A("coffee", "galley", "Coffee", "stand", "mug", "ANY", 1.5, "", ["Third cup. Don't count, it's rude."]),
        A("stories", "galley", "CouchLeft", "sit", "", "IN_FLIGHT", 1.0, "", ["My stories are on. Two freighters, star-crossed. He's a tanker, she's refrigerated. Shh."]),
        A("machines", "dispatch", "MachineBank", "work", "", "ANY", 1.0, "", ["The dispatch computer's making the noise again. I hit it. Lovingly."]),
        A("snooze", "dispatch", "ChairNap", "sleep", "", "NIGHT", 2.0, "", ["Mmh... five more minutes... tell the client I'm in a meeting..."]),
        A("vending", "hallway", "Vending", "stand", "", "ANY", 1.0, "", ["This machine owes me four credits and an apology."]),
        A("solitaire", "galley", "TableNorth", "sit", "cards", "ANY", 0.8, "", ["Solitaire. Against myself. I'm losing."]),
        A("novel", "dispatch", "Chairs", "read", "book", "DAY", 1.0, "", ["A romance novel. Space pirate, heart of gold. Don't look at me like that."]),
     ],
     "talk": [
        ("ANY", "", 0, "", ["{company} sent another memo. 'Synergy.' I used it as a coaster."]),
        ("ANY", "", 0, "", ["Clem asked me what a manifest is. I said it's when you want something real bad.", "He's been staring at the cargo for an hour."]),
        ("ANY", "", 0, "", ["Digby fixed the toaster. Now it's faster than the rig."]),
        ("HAS_JOB", "", 0, "", ["That {cargo} in the back? Client says handle with care. Clients say that about everything."]),
        ("NO_JOB", "", 0, "", ["Board's got work if you want it, hon. Or don't. I'm not your mother. Eat something, though."]),
        ("JUST_PAID", "", 0, "", ["Payment cleared! I did a little dance. Nobody saw. Clem saw."]),
        ("IN_FLIGHT", "", 0, "", ["I like it when we're moving. The hum puts me right to sleep. Don't tell {company}."]),
        ("PARKED", "", 0, "", ["We're parked at {place}. I'm not getting off. Last time I got off I bought a timeshare."]),
        ("NIGHT", "", 0, "", ["Night shift's the best shift. Nobody calls. Except clients. And Sal."]),
        ("ANY", "glimmer_open", 0, "", ["Sal called again. He calls me 'sweetheart.' I call him 'sir' in a voice that means something else."]),
        ("ANY", "", 3, "dottie_mentioned_white", ["You know, {husband} used to bring me those little gas station donuts. Every haul.", "...Anyway. Coffee?"]),
        ("ANY", "", 5, "", ["Thirty years on dispatch, hon. You're my favorite driver. Don't let it go to your head."]),
     ]},
    {"id": "digby", "npc": "res://data/npcs/crew_digby.tres", "visual": "res://scenes/hub/crew/MoleVisual.tscn",
     "role": "Mechanic",
     "greetings": ["Mm. Captain.", "Oh. It's you. Good. The engine likes you.", "{bunny}. Watch your step, I've got parts everywhere.",
                   "Mornin'. Or night. Down here it's always engine o'clock."],
     "activities": [
        A("engine", "engine", "Engine", "work", "wrench", "ANY", 3.0, "", ["She's purring today. Hear that? No? Get closer. Closer.", "...That's close enough."]),
        A("bench", "engine", "Bench", "work", "wrench", "ANY", 2.0, "", ["Rebuilding a fuel injector. Or a toaster. Haven't decided."]),
        A("cot", "engine", "Cot", "sleep", "", "NIGHT", 2.0, "", ["Zzz... torque... zzz..."]),
        A("catnap", "engine", "Cot", "sleep", "", "ANY", 0.4, "", ["Mm? Not asleep. Resting my eyes. Engineers do that."]),
        A("lunch", "galley", "TableEast", "eat", "plate", "ANY", 1.0, "", ["Grub's on. Get it? Grub. I'm a mole.", "...I'll see myself out."]),
        A("arcade", "galley", "Arcade", "work", "", "ANY", 0.8, "", ["Asteroid Alley. High score's mine. Don't check that."]),
        A("pipes", "hallway", "MidHall", "work", "wrench", "ANY", 0.8, "", ["Pipe's knocking. Pipes don't knock unless they want something."]),
        A("forklift", "cargo", "ForkliftFix", "work", "wrench", "ANY", 0.6, "", ["Clem drove the forklift into the wall again. Wall's fine. Forklift's sulking."]),
     ],
     "talk": [
        ("ANY", "", 0, "", ["Ship's older than me and in better shape. Don't tell her I said that. She's vain."]),
        ("ANY", "", 0, "", ["Every rattle's a word, you know. That one means 'more grease.'", "They all mean 'more grease.'"]),
        ("ANY", "", 0, "", ["Goggles? Habit. Used to dig tunnels for a living. Engines are just tunnels for fire."]),
        ("IN_FLIGHT", "", 0, "", ["Engine's happiest out here. Like a dog with its head out the window. A two-ton dog."]),
        ("PARKED", "", 0, "", ["Parked. Good. Gives me time to tighten everything you loosened."]),
        ("HAS_JOB", "", 0, "", ["That {cargo}'s heavy. I can feel it in the bearings. I feel everything in the bearings."]),
        ("JUST_PAID", "", 0, "", ["Paid? Buy oil. Good oil. The kind in the gold can."]),
        ("NIGHT", "", 0, "", ["Can't sleep. Too quiet. I need the hum."]),
        ("ANY", "", 3, "digby_mentioned_white", ["{husband} did the wiring on that dash himself. Messy. Works perfect.", "I never touch it."]),
        ("ANY", "", 5, "", ["I don't say this to many people. But you drive her gentle. She notices."]),
     ]},
    {"id": "clem", "npc": "res://data/npcs/crew_clem.tres", "visual": "res://scenes/hub/crew/DonkeyVisual.tscn",
     "role": "Cargo hand",
     "greetings": ["Mornin', boss!", "Hiya, {bunny}! I polished your door handle!", "Boss! I learned a new knot! ...I forgot it.",
                   "Hey hey! {company} forever!"],
     "activities": [
        A("forklift", "cargo", "Forklift", "work", "", "ANY", 2.5, "", ["Loadin' and unloadin'. Mostly loadin'. Sometimes I forget which."]),
        A("counting", "cargo", "Clipboard", "read", "clipboard", "HAS_JOB", 2.0, "", ["Countin' the {cargo}. I got to seven.", "Then I got to seven again."]),
        A("crate", "cargo", "OnCrate", "sit", "", "NO_JOB", 1.5, "", ["Empty back. Feels like a big hug with nobody in it."]),
        A("sandwich", "galley", "TableSouth", "eat", "plate", "ANY", 1.5, "", ["Hay sandwich. Want half? It's mostly hay."]),
        A("sweeping", "hallway", "Broom", "work", "broom", "ANY", 1.0, "", ["Sweepin'. Space gets in everywhere. Space dust. It's in my ears."]),
        A("payday", "galley", "Middle", "dance", "", "JUST_PAID", 2.0, "", ["Payday dance! Join in! Left hoof, right hoof, wiggle!"]),
        A("couch", "galley", "CouchRight", "sleep", "", "NIGHT", 1.5, "", ["Hhhnnk... mama... the crates are singin'..."]),
        A("stars", "hallway", "AirlockWindow", "stand", "", "IN_FLIGHT", 1.0, "", ["Lookit all them stars. You think they got deliveries too?"]),
        A("plant", "apartment", "Window", "stand", "", "DAY", 0.5, "", ["Oh! Boss! I was just waterin' your plant. It looked thirsty. It's plastic? Huh."]),
     ],
     "talk": [
        ("ANY", "", 0, "", ["{company} sent me a pin for five years of service. I been here two. I'm not tellin' 'em."]),
        ("ANY", "", 0, "", ["My mama says hi. She don't know you. She says hi to everybody."]),
        ("ANY", "", 0, "", ["Did you know cargo is just stuff that's goin' somewhere? Same as us, kinda."]),
        ("HAS_JOB", "", 0, "", ["The {cargo} is real quiet today. I sang it a song just in case."]),
        ("NO_JOB", "", 0, "", ["Back's empty. I'm practicin' liftin' air. Gettin' real good at it."]),
        ("IN_FLIGHT", "", 0, "", ["I love when we're flyin'. My ears go all floaty."]),
        ("PARKED", "", 0, "", ["We're at {place}! Can I get a souvenir? Just a little one. A keychain. Two keychains."]),
        ("JUST_PAID", "", 0, "", ["We got paid! Does that mean I get paid? I get paid in sandwiches, right?"]),
        ("ANY", "", 2, "", ["Dottie says you're the best driver she ever had. Except one. She don't say who. She gets quiet."]),
        ("ANY", "", 4, "", ["Boss? Thanks for keepin' me on. I know I'm slow. But I'm careful slow."]),
     ]},
]

# (id, title, situation, weight, needs_flag, roles, find)
# roles: (crew, room, spot, pose, prop, [lines])
# find: (item, room, spot, owner, reward, [thanks]) or None
EVENTS = [
    ("card_night", "CARD NIGHT IN THE GALLEY", "ANY", 1.0, "", [
        ("dottie", "galley", "TableNorth", "sit", "cards", ["Read 'em and weep, boys.", "...What's a flush again?"]),
        ("digby", "galley", "TableEast", "sit", "cards", ["I'm bluffin'. Or am I. I am."]),
        ("clem", "galley", "TableSouth", "sit", "cards", ["Is it bad if all my cards are the same? ...Is it good?"])], None),
    ("coffee_broke", "THE COFFEE MACHINE BROKE", "ANY", 1.0, "", [
        ("digby", "galley", "Coffee", "work", "wrench", ["Coffee machine's dead. Somebody poured soup in it.", "...Clem."]),
        ("dottie", "galley", "TableNorth", "sit", "", ["No coffee. I'm running on spite now, hon."]),
        ("clem", "galley", "Middle", "stand", "", ["I thought it was a soup machine! It looked hungry!"])], None),
    ("lost_wrench", "DIGBY LOST HIS LUCKY WRENCH", "ANY", 1.0, "", [
        ("digby", "engine", "Engine", "stand", "", ["My lucky wrench. Gone. Can't fix a thing without it.", "Well, I can. But I won't."])],
        ("Digby's lucky wrench", "hallway", "LostWrench", "digby", 60, ["My wrench! Where was it? ...The hallway? I've never been to the hallway.", "Here. Gas money. Don't spend it on gas."])),
    ("movie_night", "MOVIE NIGHT IN THE GALLEY", "IN_FLIGHT", 1.0, "", [
        ("dottie", "galley", "CouchLeft", "sit", "", ["Shh. This is the part where the freighter says 'I love you' in Morse code."]),
        ("clem", "galley", "CouchRight", "sit", "", ["I'm not cryin'. My eyes are just sweatin'."]),
        ("digby", "galley", "TableEast", "eat", "plate", ["Seen it. The engine dies at the end. Spoilers."])], None),
    ("clem_birthday", "IT'S CLEM'S BIRTHDAY!", "ANY", 0.5, "", [
        ("clem", "galley", "Middle", "dance", "", ["It's my birthday! I'm thirty-one! Or nineteen! Mama lost the papers!"]),
        ("dottie", "galley", "TableNorth", "sit", "", ["Digby baked a cake. In the engine. It's... warm."]),
        ("digby", "galley", "Stove", "work", "", ["Cake's done when the smoke detector says so."])], None),
    ("lost_clipboard", "DOTTIE CAN'T FIND HER CLIPBOARD", "ANY", 1.0, "", [
        ("dottie", "dispatch", "Counter", "stand", "", ["Has anyone seen my clipboard? It has everything on it. EVERYTHING, hon."])],
        ("Dottie's clipboard", "cargo", "FindBetweenCrates", "dottie", 40, ["My clipboard! Bless you. I was about to start remembering things myself."])),
    ("karaoke", "KARAOKE IN THE GALLEY", "ANY", 0.8, "glimmer_open", [
        ("clem", "galley", "Middle", "dance", "", ["This one's called 'Hauling My Heart Across the Stars.' I wrote it! It's mostly the word 'haul'!"]),
        ("dottie", "galley", "CouchLeft", "sit", "", ["He's been practicing all week. Clap, hon. Clap for him."]),
        ("digby", "galley", "Arcade", "stand", "", ["I'm not singing. I'm guarding the arcade. From joy."])], None),
    ("engine_hiccup", "THE ENGINE'S MAKING A FUNNY NOISE", "IN_FLIGHT", 1.0, "", [
        ("digby", "engine", "Engine", "work", "wrench", ["Hear that? Ka-chunk... ka-chunk. She's hungry. Or sad. Either way, more grease."]),
        ("clem", "engine", "Drum", "lean", "", ["Is she gonna be okay? I brought her a blanket."])], None),
    ("lost_cap", "CLEM LOST HIS {company} CAP", "ANY", 1.0, "", [
        ("clem", "cargo", "Crates", "stand", "", ["My cap! My {company} cap! I can't work without it, boss. It's the uniform!"])],
        ("Clem's cap", "galley", "FindUnderTable", "clem", 30, ["My cap! You found it! I'm gonna wear it so hard."])),
    ("quiet_night", "EVERYONE'S ASLEEP", "NIGHT", 1.5, "", [
        ("dottie", "dispatch", "ChairNap", "sleep", "", ["...zzz... dispatch... hold please... zzz..."]),
        ("digby", "engine", "Cot", "sleep", "", ["...zzz... the bearings... zzz..."]),
        ("clem", "galley", "CouchRight", "sleep", "", ["...zzz... crates... singin'..."])], None),
]


def q(text):
    return '"' + text.replace("\\", "\\\\").replace('"', '\\"') + '"'


def plist(items):
    return "PackedStringArray(" + ", ".join(q(t) for t in items) + ")"


def write_crew():
    ext = ['[ext_resource type="Script" path="res://data/crew/CrewRoster.gd" id="s_roster"]',
           '[ext_resource type="Script" path="res://data/crew/CrewMember.gd" id="s_member"]',
           '[ext_resource type="Script" path="res://data/crew/CrewActivity.gd" id="s_activity"]',
           '[ext_resource type="Script" path="res://data/crew/CrewLine.gd" id="s_line"]',
           '[ext_resource type="Script" path="res://data/crew/ShipEvent.gd" id="s_event"]']
    subs = []
    counter = [0]

    def sub(lines):
        counter[0] += 1
        name = "R_%d" % counter[0]
        subs.append('[sub_resource type="Resource" id="%s"]\n%s\n' % (name, "\n".join(lines)))
        return 'SubResource("%s")' % name

    def activity(id_, room, spot, pose, prop, situation, weight, flag, lines, crew=""):
        body = ['script = ExtResource("s_activity")', "id = " + q(id_)]
        if crew:
            body.append("crew = " + q(crew))
        body += ["room = " + q(ROOMS[room]), "spot = " + q(spot), "pose = " + q(pose)]
        if prop:
            body.append("prop = " + q(prop))
        body.append("lines = " + plist(lines))
        if situation != "ANY":
            body.append("situation = %d" % SITUATIONS.index(situation))
        if weight != 1.0:
            body.append("weight = %s" % weight)
        if flag:
            body.append("needs_flag = " + q(flag))
        return sub(body)

    members = []
    for i, c in enumerate(CREW):
        ext.append('[ext_resource type="Resource" path="%s" id="npc_%d"]' % (c["npc"], i))
        ext.append('[ext_resource type="PackedScene" path="%s" id="vis_%d"]' % (c["visual"], i))
        acts = [activity(*a) for a in c["activities"]]
        talks = []
        for situation, flag, friends, sets, lines in c["talk"]:
            body = ['script = ExtResource("s_line")', "lines = " + plist(lines)]
            if situation != "ANY":
                body.append("situation = %d" % SITUATIONS.index(situation))
            if flag:
                body.append("needs_flag = " + q(flag))
            if friends:
                body.append("min_friendship = %d" % friends)
            if sets:
                body.append("sets_flag = " + q(sets))
            talks.append(sub(body))
        body = ['script = ExtResource("s_member")', "id = " + q(c["id"]), 'npc = ExtResource("npc_%d")' % i,
                'visual = ExtResource("vis_%d")' % i, "role = " + q(c["role"]),
                'activities = Array[ExtResource("s_activity")]([%s])' % ", ".join(acts),
                'small_talk = Array[ExtResource("s_line")]([%s])' % ", ".join(talks),
                "greetings = " + plist(c["greetings"])]
        if c.get("menu"):
            body += ["menu = " + q(c["menu"]), "post_activity = " + q(c["post"])]
        members.append(sub(body))
    events = []
    for id_, title, situation, weight, flag, roles, find in EVENTS:
        role_refs = [activity(id_, room, spot, pose, prop, "ANY", 1.0, "", lines, crew)
                     for crew, room, spot, pose, prop, lines in roles]
        body = ['script = ExtResource("s_event")', "id = " + q(id_), "title = " + q(title)]
        if situation != "ANY":
            body.append("situation = %d" % SITUATIONS.index(situation))
        if weight != 1.0:
            body.append("weight = %s" % weight)
        if flag:
            body.append("needs_flag = " + q(flag))
        body.append('roles = Array[ExtResource("s_activity")]([%s])' % ", ".join(role_refs))
        if find:
            item, room, spot, owner, reward, thanks = find
            body += ["find_item = " + q(item), "find_room = " + q(ROOMS[room]), "find_spot = " + q(spot),
                     "find_owner = " + q(owner), "find_reward = %d" % reward, "find_thanks = " + plist(thanks)]
        events.append(sub(body))
    text = ['[gd_resource type="Resource" script_class="CrewRoster" format=3]', ""] + ext + [""] + subs + [
        "[resource]", 'script = ExtResource("s_roster")',
        'crew = Array[ExtResource("s_member")]([%s])' % ", ".join(members),
        'events = Array[ExtResource("s_event")]([%s])' % ", ".join(events), ""]
    with open(os.path.join(ROOT, "data", "crew", "crew.tres"), "w") as f:
        f.write("\n".join(text))


# (file, name, species, voice pitch, (voice type, key 0=C..11=B, scale), comm name, fur, accent, lines)
NPCS = [
    ("crew_digby.tres", "Digby", "mole", 0.7, ("gruff", 0, "minor"), "DIGBY · ENGINE", "Color(0.42, 0.32, 0.28, 1)", "Color(0.85, 0.65, 0.2, 1)",
     ["Mm. Engine's fine. You're fine. Everything's fine. Go away. Nicely."]),
    ("crew_clem.tres", "Clem", "donkey", 0.85, ("reed", 7, "major"), "CLEM · CARGO", "Color(0.5, 0.48, 0.5, 1)", "Color(1, 0.45, 0.1, 1)",
     ["Hiya, boss!"]),
]


def write_npcs():
    for file_name, name, species, pitch, voice, comm, fur, accent, lines in NPCS:
        text = ['[gd_resource type="Resource" script_class="NPCData" format=3]', "",
                '[ext_resource type="Script" path="res://data/npcs/NPCData.gd" id="1_npc"]', "",
                "[resource]", 'script = ExtResource("1_npc")', "display_name = " + q(name),
                "species = " + q(species), "voice_pitch = %s" % pitch,
                "voice_type = " + q(voice[0]), "voice_key = %d" % voice[1], "voice_scale = " + q(voice[2]), "lines = " + plist(lines),
                "comm_name = " + q(comm), "fur_color = " + fur, "accent_color = " + accent, ""]
        with open(os.path.join(ROOT, "data", "npcs", file_name), "w") as f:
            f.write("\n".join(text))


write_npcs()
write_crew()
print("wrote data/crew/crew.tres and the crew NPC files")
