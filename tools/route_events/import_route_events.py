#!/usr/bin/env python3
"""Builds data/events/route_events.tres from the design list.

The design list (docs/ROUTE_EVENTS_LIST.md) has every route event with its
tags. This script reads it, adds what each PLAYABLE event actually does
(the 3D thing, who calls, the lines, the effect: the OVERRIDES below), and
writes the event list the game uses.

CAREFUL: running it OVERWRITES data/events/route_events.tres. If you've
edited events in the Godot inspector, make the same change here first (or
don't run it again). It's mainly here for adding the rest of the list
(events 168-250) the same way:

    python3 tools/route_events/import_route_events.py

Then run Godot once (or tools/validate.sh) so it picks up the change.
"""

import os
import re

ROOT = os.path.normpath(os.path.join(os.path.dirname(__file__), "..", ".."))
LIST = os.path.join(ROOT, "docs", "ROUTE_EVENTS_LIST.md")
OUT = os.path.join(ROOT, "data", "events", "route_events.tres")

KIND = {"BIG_SHIP": 0, "CONVOY": 1, "WHALES": 2, "JELLYFISH": 3, "BILLBOARD": 4, "COMET": 5, "JUNK": 6,
        "DERELICT": 7, "DUCK": 8, "ION_STORM": 9, "NONE": 10, "SIGN": 11, "LONE_SHIP": 12}
ZONE = {"ANYWHERE": 0, "DEEP_SPACE": 1, "TRAFFIC_LANES": 2, "STATION_APPROACH": 3, "ORBIT": 4, "WEATHER": 5}
TYPE = {"Sight": 0, "Encounter": 1, "Hazard": 2, "Opportunity": 3, "Radio": 4, "Cab": 5, "Cargo": 6}
TONE = {"Silly": 0, "Cute": 1, "Weird": 2, "Serious": 3, "Dangerous": 4}
RARITY = {"C": 0, "U": 1, "R": 2, "L": 3}
BUILD = {"Cheap": 0, "Reuse": 1, "New": 2, "New mechanic": 3}
EFFECT = {"NONE": 0, "DEAD_AIR": 1, "STATIC": 2, "PINGS": 3, "NUDGE": 4, "SWAY": 5, "BUMPY": 6}
# Which zone each section of the list belongs to. Creatures and derelicts
# aren't zones in the list; they drift in the empty stretches.
SECTION_ZONE = {1: "DEEP_SPACE", 2: "TRAFFIC_LANES", 3: "STATION_APPROACH", 4: "ORBIT", 5: "WEATHER",
                6: "DEEP_SPACE", 7: "DEEP_SPACE"}
NPCS = {
    "wendell": "res://data/npcs/trucker_wendell.tres", "pip": "res://data/npcs/trucker_pip.tres",
    "gill": "res://data/npcs/tidewater_gill.tres", "dottie": "res://data/npcs/dispatch_morning.tres",
    "moe": "res://data/npcs/gasngo_moe.tres", "biscuit": "res://data/npcs/space_deputy.tres",
    "dusty": "res://data/npcs/truckstop_mechanic.tres", "jack": "res://data/npcs/bunny_jack.tres",
    "fern": "res://data/npcs/approach_fern.tres", "gus": "res://data/npcs/courier_gus.tres",
    "bev": "res://data/npcs/tourist_bev.tres", "ch19": "res://data/npcs/open_channel.tres",
}
SOUNDS = {"thunder": "res://audio/generated/big_engine.wav"}

BIG_SHIP_NAMES = ["NAVY LEISURE BARGE", "RETIREE CRUISE LINER", "DISCOUNT MATTRESS FREIGHTER",
                  "MUNICIPAL WASTE HAULER", "BULK SOUP CARRIER", "COLONY MOVING CO.", "OVERNIGHT PILLOW EXPRESS",
                  "REGIONAL CHEESE AUTHORITY", "SPARE PARTS & SONS", "THE SLIGHTLY LATE EXPRESS",
                  "FLOATING TIMESHARE (ASK US!)", "BULK BUBBLE WRAP CARRIER", "MOBILE DENTIST FLEET"]

# What each playable event does. Anything not listed here stays in the list
# switched off (playable = false), with `needs` saying what's missing.
# Keys: numbers from the list. Events with "number": 0 are the original
# sights that aren't on the list.
OVERRIDES = {
    # --- 1. Deep space -----------------------------------------------------
    4: dict(kind="SIGN", texts=["LAST GAS FOR 40,000 KM|LAST GAS FOR 40,000 KM"], ahead=4500, side=(300, 700), height=(60, 200),
            speaker="wendell", lines=["'Last gas for forty thousand.' There's a pump right up the road. That sign's been lying since before you were born.",
                                      "Don't trust that sign, kid. Nobody's updated it since the Gas-N-Go opened."]),
    5: dict(effect="DEAD_AIR", secs=20),
    8: dict(effect="STATIC", secs=12, radio_from="JINGLE SAT",
            dj=["♪ SPARKLE-FRESH! SPARKLE-FRESH! THE MOON SOAP THAT LOVES YOU BACK! ♪",
                "♪ BUY ONE COMET, GET ONE COMET! ONLY AT COMET MART! ♪ (OFFER EXPIRED 62 YEARS AGO)",
                "♪ CRUNCHY! MUNCHY! ASTRO-NUGGETS! ...ASTRO-NUGGETS! ...ASTRO-NUGGETS! ♪"]),
    10: dict(effect="PINGS", secs=8, speaker="wendell",
             lines=["Hear that pinging? Space sand. Hull's seen worse.", "Little rocks. Big sky. Keep her steady, it'll pass."],
             replies=["Sounds like hail on a tin roof.", "My hull has a lot of opinions today.", "...ping."]),
    11: dict(number_id="comet", kind="COMET", log_id="comet", weight=1.0, cooldown=0, ahead=5000, side=(0, 0), height=(300, 900),
             effect="STATIC", secs=5, speaker="pip",
             lines=["Comet! Make a wish! I wished for a sandwich.", "Was that a comet? It was a comet! Did your radio do the sparkly thing too?"]),
    15: dict(kind="SIGN", texts=["▼ YOU ARE HERE ▼|YOU WERE HERE"], ahead=4500, side=(300, 700), height=(60, 200),
             speaker="jack", lines=["...thanks. Very helpful.", "Good to know."]),
    16: dict(story="story_echo_transponder", banner="TRANSPONDER MATCH: THIS RIG", effect="STATIC", secs=6,
             needs="The husband's story (M8) sets the story flag; until then it never happens."),
    22: dict(kind="LONE_SHIP", names=["PARKED · DO NOT DISTURB", "OFF DUTY (ASLEEP)"], speed=0.05, same_dir=True,
             ahead=2500, side=(150, 300), height=(-40, 40), speaker="wendell",
             lines=["zzz... hnnk... five more minutes, Marge... zzz", "...mm... I'm up. I'm up. ...zzz"],
             replies=["Sweet dreams, Wendell.", "(turn the radio down)", "...same, buddy. Same."]),
    26: dict(effect="NUDGE", secs=10, speaker="wendell",
             lines=["Feel that tug? Gravity eddy. Hold her steady, don't fight it.", "Current's pushing you sideways. Easy hands, kid."]),
    30: dict(dj=["Y'all still out there? Real quiet tonight.", "...anybody? Just me and the static? Cool. Cool cool cool. Here's a song.",
                 "If you can hear this, you're farther out than most. Hang in there, trucker."], weight=0.6),
    # --- 2. Traffic lanes --------------------------------------------------
    31: dict(number_id="big_ship", kind="BIG_SHIP", log_id="big_ship", weight=2.0, cooldown=0, ahead=4500, side=(0, 150),
             height=(260, 420), names=BIG_SHIP_NAMES, speaker="wendell",
             lines=["Whoa, look at the size of that one.", "Big ship crossing, kid. Let it by, it doesn't do brakes."]),
    33: dict(kind="LONE_SHIP", names=["SHELDON'S SLOW FREIGHT", "TORTOISE TRANSPORT · 12 KM/H"], speed=0.25, same_dir=True,
             ahead=2500, side=(60, 150), height=(-20, 20), log_id="slowpoke", speaker="wendell",
             lines=["Tortoise in the fast lane again. Go around, kid. He's been in that lane since Tuesday.",
                    "That's Sheldon. Don't honk. He'll just go slower."]),
    34: dict(kind="LONE_SHIP", names=["PIGEON POST · PRIORITY", "PIGEON POST · VERY PRIORITY"], speed=2.0,
             ahead=3000, side=(40, 90), height=(-10, 10), speaker="gus",
             lines=["COO-ROO! RRRK! MOVE IT, BUN! ROO-COO-ROO!", "PRRRT! COO! BRRRK-COO! (that's pigeon for 'sorry, late')"],
             replies=["Rude.", "Love you too, buddy.", "...pigeons."]),
    35: dict(kind="LONE_SHIP", names=["A-1 TOW · WE HAUL HAULERS", "TOW SHIP (+1 SAD RIG)"], speed=0.6,
             ahead=4000, side=(120, 220), height=(-20, 20)),
    40: dict(kind="CONVOY", names=["PROCESSION"], speed=0.4, tint=(0.6, 0.5, 0.95), ahead=4000, side=(150, 260),
             height=(-20, 20), speaker="wendell",
             lines=["Procession coming. Lights low, ease off. ...That's how we do it out here.",
                    "Slow ships, lights on. Somebody's last haul. Give 'em room, kid."],
             replies=["...", "Easing off.", "Safe travels, whoever you were."]),
    41: dict(kind="LONE_SHIP", names=["STUDENT DRIVER", "STUDENT DRIVER · PLEASE BE PATIENT"], speed=0.5, same_dir=True,
             weaving=True, ahead=2500, side=(30, 120), height=(-15, 15), log_id="student_driver", banner="STUDENT DRIVER AHEAD",
             speaker="dottie", lines=["Heads up hon, student driver on your lane. Give 'em room. We were all new once."]),
    42: dict(banner="MERGE AHEAD · EXPECT DELAYS", speaker="ch19",
             lines=["—moving yet? —nope. —how 'bout now? —still nope. —somebody's reading every single sign up there.",
                    "—who's doing the zipper merge wrong? —everybody. —everybody, great."],
             replies=["Classic gate merge.", "I brought snacks. I'm fine.", "Zipper merge, people. ZIPPER."]),
    45: dict(kind="LONE_SHIP", names=["BROKE DOWN · HAZARDS ON"], speed=0.03, same_dir=True, tint=(1.0, 0.5, 0.1),
             ahead=2500, side=(150, 260), height=(-20, 20), speaker="pip",
             lines=["Uh. Hi. Don't laugh. I boosted through a thruster. Again. Tow's coming. Probably."],
             replies=["Need a hand? ...I don't have a hand. I have a mitten.", "Tow's on its way, hang tight.",
                      "Again, Pip?"],
             needs="Sharing fuel for a tip and reputation (reputation comes later)."),
    46: dict(speaker="ch19",
             lines=["—you BUMPED me! —you were in MY lane! —there are no lanes, it's SPACE! —then why are there SIGNS?!",
                    "—that's a scratch. —that's a DENT. —that dent was there. —it was NOT there."],
             replies=["Grab some popcorn.", "Exchange insurance, nerds.", "(turn the radio up)"]),
    49: dict(kind="LONE_SHIP", names=["AD SHIP · MOON MILK · 30% LESS GRAVITY", "AD SHIP · NAP MOTEL · SLEEP IS GOOD",
                                      "AD SHIP · DR. SPRINKLE'S HULL PUTTY"], speed=0.4, ahead=4000, side=(200, 400),
             height=(20, 80), log_id="billboard"),
    52: dict(kind="LONE_SHIP", names=["REST STOP SHUTTLE · ZZZ", "DRIVERS' SHUTTLE · NAP EXPRESS"], speed=0.8,
             ahead=4000, side=(120, 220), height=(-20, 20)),
    53: dict(kind="BIG_SHIP", names=["ADMIRAL'S BIRTHDAY YACHT", "PARADE FLAGSHIP (CONFETTI ONLY)"], tint=(0.85, 0.85, 0.95),
             speed=0.6, ahead=5000, side=(0, 150), height=(260, 420), speaker="biscuit",
             lines=["Civilian traffic, please yield for the Admiral's birthday flotilla. ...He's turning 90. Wave if you want."],
             replies=["Happy birthday, Admiral.", "Yielding. Waving.", "Ninety. Respect."]),
    54: dict(banner="SIREN BEHIND YOU · EASE RIGHT", speaker="biscuit",
             lines=["Ambulance coming through! Ease right, folks. Thank you kindly."],
             replies=["Easing right.", "Go go go.", "Hope they're okay."],
             needs="The courtesy bonus for pulling over."),
    55: dict(systems=["tidewater"], speaker="wendell",
             lines=["Word on channel 19: Biscuit's parked in the bushes up ahead. Ease off, kid.",
                    "Smokey's out by the cannery today. Watch your speed."]),
    57: dict(speaker="bev",
             lines=["Excuse me, sugar, which way to the World's Biggest Donut? My map's upside down. Or I am.",
                    "Hi! Is this the scenic route? Everything's so... spacey."],
             replies=["Back that way. Can't miss it.", "Straight ahead, forever.", "Follow the beacons, hon."]),
    59: dict(effect="BUMPY", secs=10, banner="SPILL ON THE LANE", speaker="wendell",
             lines=["Ball bearings all over the lane. Gonna be a bumpy one, kid."]),
    61: dict(effect="NUDGE", secs=5, banner="FAST LANE ENDS · MERGE", speaker="dottie",
             lines=["Lane's ending, hon. Everybody's merging at once. Patience."]),
    # --- 3. Station approach -----------------------------------------------
    66: dict(speaker="fern",
             lines=["Approach to inbound rig: please hold for thirty seconds. ...Thank you for holding. Your call is important to us."],
             dj=["While you're holding out there, here's a song about waiting."],
             replies=["Holding.", "Is there hold music?", "I'll just float here."]),
    67: dict(kind="SIGN", texts=["NOW SERVING #47|PLEASE TAKE A NUMBER"], ahead=1500, side=(600, 900), height=(80, 200)),
    72: dict(banner="CUSTOMS SCAN... CLEAR", speaker="fern",
             lines=["Scanning... one rig, one tired driver, zero contraband. Welcome in.",
                    "Scan complete. You're clear. Your cab could use a vacuum."],
             replies=["Thanks.", "Rude, but fair.", "The crumbs are decorative."]),
    74: dict(speaker="fern",
             lines=["Ring's sticking again. Hang on. *CLANG* ...*CLANG* ...okay. Sorry about that."],
             replies=["Hit it again.", "Take your time.", "Percussive maintenance."]),
    76: dict(kind="LONE_SHIP", names=["AD BLIMP · SNOOZE PODS", "AD BLIMP · GALAXY GUMBALLS", "AD BLIMP · CALL YOUR MOTHER"],
             speed=0.15, ahead=1500, side=(600, 900), height=(150, 300)),
    77: dict(speaker="fern",
             lines=["Inbound rig, we've moved you to ring... oh. No. Same ring. Sorry. Long day."],
             replies=["Happens.", "Same ring. Got it.", "Want me to bring you a coffee?"]),
    82: dict(kind="SIGN", texts=["FUEL & FOO|EAT AT MAR E'S", "HOT  OFFEE|GOO  EATS", "TUCK TOP|OPEN 24 HOU S"],
             ahead=1500, side=(600, 900), height=(80, 200)),
    85: dict(night=True, speaker="fern",
             lines=["Approach control to inbound... you're cleared for... for... zzz... ...huh? Yes. Cleared. Hi."],
             replies=["Go back to sleep, Fern.", "Cleared. Thanks.", "Night shift's rough, huh."]),
    # --- 4. Planet and moon orbit -------------------------------------------
    87: dict(kind="JUNK", log_id="junk", ahead=4000, side=(0, 300), height=(-100, 100), speaker="wendell",
             lines=["Orbital junk belt. Weave easy, kid."]),
    102: dict(effect="STATIC", secs=8, radio_from="LOCAL AM 540",
              dj=["...and that's the tide report: high, then low, then high again. Back to polka.",
                  "...lost: one fishing hat. Answers to 'hat'. Call the cannery. Now, the polka hour.",
                  "...today's weather: space. Tomorrow's weather: also space."]),
    105: dict(kind="JUNK", ahead=4000, side=(300, 900), height=(-100, 200), speaker="gill",
              lines=["Old satellites up there. They used to tell the weather. Now they just... float. Mmh. Relatable."]),
    108: dict(kind="WHALES", size=3.0, systems=["tidewater"], ahead=7000, side=(1500, 3000), height=(-1200, -400),
              log_id="whale_breach", speaker="gill",
              lines=["...did one just jump OUT of the planet? Mmh. Showoff."]),
    # --- 5. Weather ---------------------------------------------------------
    111: dict(number_id="ion_storm", kind="ION_STORM", log_id="ion_storm", weather="ion", systems=["tidewater"], weight=0.8,
              cooldown=0, ahead=6000, side=(0, 600), height=(-100, 100), speaker="gill",
              lines=["Ion storm brewing out there. Your radio'll get crackly. Mine always is."]),
    116: dict(effect="PINGS", secs=10, weather="ice", speaker="gill",
              lines=["Hail. Ice hail. It's just frozen space, it won't hurt the cargo. Much."]),
    120: dict(effect="SWAY", secs=12, speaker="dottie",
              lines=["Gravity tide, hon. Just ride it like a boat."], replies=["Like a boat.", "I get seasick.", "Wheee."]),
    122: dict(effect="STATIC", secs=8, speaker="wendell",
              lines=["Sun's flickering again. Sunspot season. Radio's gonna be garbage for a bit."]),
    126: dict(sound="thunder", pitch=0.35, dj=["...was that thunder? Folks, there's no air out there. Sound can't... never mind. Next song."]),
    129: dict(effect="STATIC", secs=10, radio_from="FAR-OFF STATION",
              dj=["...coming to you live from somewhere you've never been. Weather's nice. Wish you were here.",
                  "...that was the number one song in a system you'll never visit. Goodnight, strangers."]),
    # --- 7. Derelicts, junk and salvage ------------------------------------
    156: dict(number_id="derelict", kind="DERELICT", log_id="derelict", weight=0.8, ahead=5000, side=(500, 900),
              height=(-200, 200), texts=["THE DOROTHY MAE", "LUCKY STRIKE VIII", "SPIRIT OF OCTOBER", "THE WANDERING TUESDAY"],
              speaker="wendell",
              lines=["That old hulk's still sending an automatic SOS. Nobody's been aboard in years. It just... keeps asking.",
                     "Derelict off the lane. Nobody's home. Probably."]),
    157: dict(number_id="junk", kind="JUNK", log_id="junk", weight=1.5, cooldown=0, zone="TRAFFIC_LANES", ahead=4000,
              side=(0, 300), height=(-100, 100), speaker="wendell",
              lines=["Junk on the road ahead. Somebody lost a load.", "Debris up ahead, kid. Easy through there."]),
    162: dict(kind="BILLBOARD", log_id="half_billboard", ahead=4000, side=(250, 600), height=(-50, 200),
              texts=["WE'RE SORRY ABOUT THE|", "IF FOUND, PLEASE RETURN TO|", "THE END IS|NEAR-ISH",
                     "YOU ARE NOT ALONE. YOU ARE|", "CONGRATULATIONS ON YOUR|"]),
    164: dict(kind="DERELICT", texts=["NO NAME ON THE HULL"], story="story_twin_rig", ahead=4000, side=(400, 700),
              height=(-100, 100), speaker="jack", lines=["...huh.", "...that's the same paint."],
              needs="The husband's story (M8) sets the story flag; until then it never happens."),
}

# What the cheap and reuse events that aren't built yet are waiting for.
NEEDS = {
    19: "A star-pattern effect (the stars shuffle into a smile).",
    21: "A fog-wall set piece with lights moving inside.",
    51: "A quick side job (carry the letter, get a tip).",
    56: "A roadside stand and a small handling buff for the haul.",
    70: "Station lights that can put on a show.",
    75: "Station windows with little figures behind them.",
    81: "Station windows you can see inside.",
    92: "Gravity wells and slingshots (planned for M5).",
    98: "City lights on a planet's night side that can spell words.",
    109: "A sunrise lighting change when you cross into daylight.",
    113: "A HUD glitch effect (numbers flicker).",
    114: "A way for events to thicken the haze for a while.",
    115: "A HUD wobble for the compass and nav arrow.",
    118: "A muffle-and-slow effect for sound and motion.",
    119: "A way for events to shift the haze color.",
    127: "A Geiger counter sound and a belt you can fly around.",
    130: "The in-game clock (M6) and a slow-motion moment.",
    131: "A whale that follows the rig for a while.",
    132: "Things that can stick to the windshield.",
}

# The original sights that aren't on the list (number 0).
CLASSICS = [
    dict(id="convoy", title="Convoy", summary="A line of rigs going the other way, engine trails and funny names.",
         type="Sight", tone="Cute", rarity="C", build="Reuse", zone="TRAFFIC_LANES",
         kind="CONVOY", log_id="convoy", weight=2.0, cooldown=0, ahead=3500, side=(180, 260), height=(-30, 30), speaker="wendell",
         lines=["That's the Tuesday convoy. Wave!", "Convoy coming the other way. Flash 'em your lights."]),
    dict(id="billboard", title="Space billboard", summary="A giant billboard advertising something surreal.",
         type="Sight", tone="Silly", rarity="C", build="Reuse", zone="ANYWHERE",
         kind="BILLBOARD", log_id="billboard", weight=1.5, cooldown=0, ahead=4000, side=(250, 600), height=(-50, 200),
         texts=["MOON MILK|NOW WITH 30% LESS GRAVITY", "DR. SPRINKLE'S HULL PUTTY|IT'S ALSO A SNACK",
                "GAS-N-GO 47|CLEAN RESTROOMS · WARM JERKY", "SPACE MUTUAL INSURANCE|BECAUSE ASTEROIDS DON'T CALL AHEAD",
                "NAP MOTEL|SLEEP IS A GOOD IDEA", "GALAXY GUMBALLS|COLLECT ALL 9000", "SNOOZE PODS|SLEEP LIKE YOU MEAN IT",
                "TIDEWATER CANNERY|FRESH FROM THE VOID", "WIGGLE'S WORMHOLE WASH|IN ONE END, OUT THE OTHER",
                "HAVE YOU CALLED YOUR MOTHER?|SHE'S FINE. CALL ANYWAY.", "SPACE JERKY|MYSTERIOUSLY CHEWY SINCE FOREVER",
                "LOST: ONE RUBBER DUCK|VERY LARGE · ANSWERS TO DUCK", "DUSTY'S GARAGE|IF IT'S LOOSE, WE TIGHTEN IT",
                "MARGE'S DINER|NEBULA PIE · TURN AROUND · YOU KNOW YOU WANT TO", "DRIVE TIRED? DON'T.|PULL OVER · NAP · LIVE"]),
    dict(id="duck", title="The giant rubber duck", summary="A rubber duck the size of a station, slowly turning. Nobody knows why.",
         type="Sight", tone="Silly", rarity="U", build="Reuse", zone="DEEP_SPACE",
         kind="DUCK", log_id="duck", weight=0.6, ahead=5000, side=(600, 1200), height=(-200, 300), speaker="pip",
         lines=["Is that... a duck?", "Guys. GUYS. There's a duck."]),
    dict(id="whales", title="Space whales", summary="A pod of space whales swimming near the ocean planet, singing.",
         type="Sight", tone="Cute", rarity="C", build="Reuse", zone="ANYWHERE", systems=["tidewater"],
         kind="WHALES", log_id="whales", weight=2.5, cooldown=0, ahead=5000, side=(500, 1000), height=(-200, 200), speaker="gill",
         lines=["Whales off your side. Big ones. They like trucks.", "Mmh. Whales. Say hi. They won't say hi back. They're shy."]),
    dict(id="jellyfish", title="Jellyfish migration", summary="Cosmic jellyfish drifting across the lane. Drift through slow.",
         type="Sight", tone="Cute", rarity="C", build="Reuse", zone="DEEP_SPACE",
         kind="JELLYFISH", log_id="jellyfish", weight=1.5, ahead=4500, side=(0, 150), height=(-60, 60), speaker="dottie",
         lines=["Jellyfish migration on the lane, hon. Drift through slow, they don't sting."]),
    dict(id="ion_storm_violet", title="Ion storm (violet)", summary="An ion storm in a different color: violet and pink.",
         type="Hazard", tone="Serious", rarity="U", build="Reuse", zone="WEATHER", weather="ion",
         kind="ION_STORM", log_id="ion_storm", tint=(0.8, 0.4, 1.0), ahead=6000, side=(0, 600), height=(-100, 100), speaker="wendell",
         lines=["Purple storm up ahead. Those are the pretty ones. Still crackly."]),
    dict(id="ion_storm_amber", title="Ion storm (amber)", summary="An ion storm in a different color: warm amber.",
         type="Hazard", tone="Serious", rarity="U", build="Reuse", zone="WEATHER", weather="ion",
         kind="ION_STORM", log_id="ion_storm", tint=(1.0, 0.7, 0.25), ahead=6000, side=(0, 600), height=(-100, 100), speaker="dottie",
         lines=["Amber storm on your route, hon. Radio's gonna fuzz out. Sing to yourself."]),
    dict(id="great_migration", title="THE GREAT MIGRATION", summary="A jellyfish swarm four times the size.",
         type="Sight", tone="Cute", rarity="R", build="Reuse", zone="ANYWHERE",
         kind="JELLYFISH", log_id="great_migration", size=4.0, ahead=7000, side=(800, 1600), height=(-300, 400), speaker="gill",
         lines=["...is that the Great Migration? My grandma saw it once. Slow down. Look."]),
    dict(id="leviathan", title="LEVIATHAN POD", summary="Whales six times the size.",
         type="Sight", tone="Serious", rarity="R", build="Reuse", zone="ANYWHERE",
         kind="WHALES", log_id="leviathan", size=6.0, ahead=8000, side=(1800, 3000), height=(-400, 600), speaker="wendell",
         lines=["Kid. KID. Look off your side. Twenty years hauling and I never... wow."]),
    dict(id="ghost_ship", title="GHOST SHIP", summary="A see-through, flickering ship. You fly right through it.",
         type="Sight", tone="Weird", rarity="R", build="Reuse", zone="ANYWHERE",
         kind="DERELICT", log_id="ghost_ship", ghost=True, ahead=5000, side=(400, 800), height=(-150, 150),
         texts=["UNKNOWN VESSEL"], speaker="wendell",
         lines=["...you see that ship? ...No. Me neither. Let's just keep driving."]),
    dict(id="comet_storm", title="COMET STORM", summary="Seven comets at once.",
         type="Sight", tone="Cute", rarity="R", build="Reuse", zone="ANYWHERE",
         kind="COMET", log_id="comet_storm", copies=7, ahead=7000, side=(0, 2000), height=(400, 2000), speaker="pip",
         lines=["COMET STORM!! Everybody make a wish! I'm wishing for seven sandwiches!"]),
]


def slug(name):
    return re.sub(r"[^a-z0-9]+", "_", name.lower()).strip("_")


def read_list():
    events = []
    section = 0
    for line in open(LIST, encoding="utf-8"):
        heading = re.match(r"^## (\d+)\. ", line)
        if heading:
            section = int(heading.group(1))
            continue
        row = re.match(r"^\| (\d+) \| (.+?) \| (.+?) \| (.+?) \|$", line.strip())
        if not row or section == 0:
            continue
        tags = [t.strip() for t in row.group(4).split("·")]
        build = "Cheap"
        mechanic = ""
        story = False
        for tag in tags[3:]:
            if tag.startswith("New mechanic"):
                build = "New mechanic"
                found = re.search(r"\((.+)\)", tag)
                mechanic = found.group(1) if found else ""
            elif tag in BUILD:
                build = tag
            elif tag.startswith("Story"):
                story = True
        events.append(dict(number=int(row.group(1)), title=row.group(2), summary=row.group(3), type=tags[0],
                           tone=tags[1], rarity=tags[2], build=build, mechanic=mechanic, story_tag=story,
                           zone=SECTION_ZONE.get(section, "ANYWHERE")))
    return events


def needs_for(event):
    if event["build"] == "New mechanic":
        what = event["mechanic"] or "a small new game system"
        return "A small new system first (%s), and its own look." % what if event["mechanic"] else "A small new game system, and its own look."
    if event["build"] == "New":
        return "A new 3D model or effect."
    return "A small hook in the game (see the summary) that isn't there yet."


def q(text):
    return '"' + text.replace("\\", "\\\\").replace('"', '\\"') + '"'


def strings(items):
    return "PackedStringArray(" + ", ".join(q(s) for s in items) + ")"


def main():
    events = []
    for row in read_list():
        extra = OVERRIDES.get(row["number"])
        event = dict(id=slug(row["title"]), number=row["number"], title=row["title"], summary=row["summary"],
                     type=row["type"], tone=row["tone"], rarity=row["rarity"], build=row["build"], zone=row["zone"])
        if extra is None:
            event["playable"] = False
            event["needs"] = NEEDS.get(row["number"], needs_for(row))
            if row["story_tag"]:
                event["story"] = "story_" + slug(row["title"])
        else:
            event.update(extra)
            if "number_id" in extra:
                event["id"] = extra["number_id"]
        events.append(event)
    for classic in CLASSICS:
        event = dict(number=0)
        event.update(classic)
        events.append(event)
    write(events)
    playable = sum(1 for e in events if e.get("playable", True))
    print("%s: %d events (%d playable)" % (OUT, len(events), playable))


def write(events):
    speakers = sorted({e["speaker"] for e in events if e.get("speaker")})
    sounds = sorted({e["sound"] for e in events if e.get("sound")})
    lines = ['[gd_resource type="Resource" script_class="RouteEventList" format=3]', "",
             '[ext_resource type="Script" path="res://data/events/RouteEventList.gd" id="1_list"]',
             '[ext_resource type="Script" path="res://data/events/EventData.gd" id="2_event"]']
    for who in speakers:
        lines.append('[ext_resource type="Resource" path="%s" id="npc_%s"]' % (NPCS[who], who))
    for sound in sounds:
        lines.append('[ext_resource type="AudioStream" path="%s" id="sound_%s"]' % (SOUNDS[sound], sound))
    names = []
    for i, e in enumerate(events):
        name = "Event_%d_%s" % (i, e["id"])
        names.append(name)
        lines += ["", '[sub_resource type="Resource" id="%s"]' % name, 'script = ExtResource("2_event")']
        lines.append("id = %s" % q(e["id"]))
        lines.append("number = %d" % e["number"])
        lines.append("title = %s" % q(e["title"]))
        lines.append("summary = %s" % q(e["summary"]))
        lines.append("type = %d" % TYPE[e["type"]])
        lines.append("tone = %d" % TONE[e["tone"]])
        lines.append("build = %d" % BUILD[e["build"]])
        if not e.get("playable", True):
            lines.append("playable = false")
        if e.get("needs"):
            lines.append("needs = %s" % q(e["needs"]))
        lines.append("zone = %d" % ZONE[e.get("zone", "ANYWHERE")])
        lines.append("rarity = %d" % RARITY[e["rarity"]])
        if "weight" in e:
            lines.append("weight = %s" % float(e["weight"]))
        if "cooldown" in e:
            lines.append("cooldown_hauls = %d" % e["cooldown"])
        if e.get("systems"):
            lines.append("systems = %s" % strings(e["systems"]))
        if e.get("night"):
            lines.append("night_only = true")
        if e.get("story"):
            lines.append("story_flag = %s" % q(e["story"]))
        if e.get("weather"):
            lines.append("weather = %s" % q(e["weather"]))
        lines.append("kind = %d" % KIND[e.get("kind", "NONE")])
        if e.get("log_id"):
            lines.append("log_id = %s" % q(e["log_id"]))
        if "size" in e:
            lines.append("size = %s" % float(e["size"]))
        if "copies" in e:
            lines.append("copies = %d" % e["copies"])
        if e.get("ghost"):
            lines.append("ghost = true")
        if "ahead" in e:
            lines.append("ahead = %s" % float(e["ahead"]))
        if "side" in e:
            lines.append("side_offset = Vector2(%s, %s)" % tuple(float(v) for v in e["side"]))
        if "height" in e:
            lines.append("height_offset = Vector2(%s, %s)" % tuple(float(v) for v in e["height"]))
        if e.get("texts"):
            lines.append("texts = %s" % strings(e["texts"]))
        if e.get("names"):
            lines.append("ship_names = %s" % strings(e["names"]))
        if e.get("tint"):
            lines.append("tint = Color(%s, %s, %s, 1)" % tuple(e["tint"]))
        if "speed" in e:
            lines.append("speed_scale = %s" % float(e["speed"]))
        if e.get("weaving"):
            lines.append("weaving = true")
        if e.get("same_dir"):
            lines.append("same_direction = true")
        if e.get("speaker"):
            lines.append('speaker = ExtResource("npc_%s")' % e["speaker"])
        if e.get("lines"):
            lines.append("lines = %s" % strings(e["lines"]))
        if e.get("replies"):
            lines.append("replies = %s" % strings(e["replies"]))
        if e.get("dj"):
            lines.append("dj_lines = %s" % strings(e["dj"]))
        if e.get("radio_from"):
            lines.append("radio_from = %s" % q(e["radio_from"]))
        if e.get("banner"):
            lines.append("banner = %s" % q(e["banner"]))
        if e.get("sound"):
            lines.append('sound = ExtResource("sound_%s")' % e["sound"])
        if "pitch" in e:
            lines.append("sound_pitch = %s" % float(e["pitch"]))
        if e.get("effect"):
            lines.append("effect = %d" % EFFECT[e["effect"]])
            lines.append("effect_seconds = %s" % float(e["secs"]))
    lines += ["", "[resource]", 'script = ExtResource("1_list")',
              'events = Array[ExtResource("2_event")]([' + ", ".join('SubResource("%s")' % n for n in names) + "])", ""]
    with open(OUT, "w", encoding="utf-8") as out:
        out.write("\n".join(lines))


if __name__ == "__main__":
    main()
