# Route events: the design list (1–167)

The developer's list of things that can happen on the road, as sent (round 10). It was cut off after #167; 168–250 are still to come. The playable data is `data/events/route_events.tres` (made from this list by `tools/route_events/import_route_events.py`); see `docs/ROUTE_EVENTS.md` for what's built.

A pool of events for the route-events director. Inspired by the spirit of Space Dandy, Red Dwarf, Star Trek, Cowboy Bebop and Hitchhiker's Guide — but every event here is original. Don't copy characters, names or jokes from those shows.

For Claude Code: convert these into the existing data/events/ format. Many events reuse props and systems that already exist (freighter flyby, convoys, junk, whales, jellyfish, ion storm, speed trap, comm portraits, RIDE bar). Events marked New mechanic need a small new system first.


## How the director should use this list


### Zones (space is mostly empty)


| Zone | Where | Event density |
|---|---|---|
| Deep space | Long empty stretches between systems | Sparse. One event every 3–5 minutes, plus long quiet gaps. Mostly sights and radio. |
| Traffic lanes | Within ~10 km of stations and jump gates | Busy. One event every 30–90 seconds. Traffic, construction, cops. |
| Station approach | Final 2–3 km before a ring | Busy, short. Docking-themed events. |
| Planet & moon orbit | Near planets and moons | Medium. Big scenic sights. |
| Weather zones | Placed storms and nebula pockets | Medium, themed to the weather. |
| Anywhere | Cab, cargo and radio events | Fill gaps everywhere; cheap to build. |


### Tags on every event


### Type

- Sight: look at it; no interaction.
- Encounter: someone calls on the comm and you choose a response (two or three choices).
- Hazard: gentle trouble: RIDE bar, cargo condition, fuel, visibility, radio. Never death, never combat.
- Opportunity: optional detour or action for a reward.
- Radio: audio and text only.
- Cab: happens inside the cockpit.
- Cargo: affects or involves the load.

Tone: Silly, Cute, Weird, Serious, Dangerous (always cozy-dangerous: a scare, a wobble, a fine, never a disaster).

Rarity: C common, U uncommon, R rare, L legendary (once per save, or close to it).

Build cost: Cheap (text, radio, HUD, sound only), Reuse (existing props recolored or rearranged), New (needs a new model or effect), New mechanic (needs a small new system).


### Director rules

- Never stack more than one Hazard at a time.
- Per-event cooldown so the same event doesn't repeat within 3 hauls (Common) or 10 hauls (Uncommon).
- Rare and Legendary events are rolled once per haul at most.
- Weather zones suppress unrelated weather events.
- Quiet is a feature: in deep space, allow stretches of 2–4 minutes with nothing but the radio.
- Story events (marked Story) are gated by story progress, never random early.
- Respect time of day (base shift) where noted.

## 1. Deep space (1–30)


| # | Event | What happens | Tags |
|---|---|---|---|
| 1 | Waving spacesuit | An empty spacesuit drifts by, one arm waving slowly. It's on a spring. | Sight · Weird · U · New |
| 2 | Lone vending machine | A lit vending machine hums in the void. Fly through its little ring to buy a soda. | Opportunity · Silly · U · New |
| 3 | Hitchhiker | A critter on a tiny rock with a thumb out. Pick them up for chatter until the next station, plus a tip. | Encounter · Cute · U · New mechanic |
| 4 | Last-gas sign | Mile marker: "LAST GAS FOR 40,000 KM." There is gas in 2 km. | Sight · Silly · C · Reuse |
| 5 | Dead air | The radio cuts to silence for 20 seconds and the stars dim. Then everything comes back. Nobody mentions it. | Radio · Weird · R · Cheap |
| 6 | Message in a bottle | A tumbling bottle. Scan it to read a short note from a stranger. | Opportunity · Cute · U · New |
| 7 | Floating living room | A couch, a rug and a lamp, still switched on. | Sight · Weird · U · New |
| 8 | Jingle satellite | An old satellite singing a decades-old ad jingle on loop. It bleeds onto the radio. | Radio · Silly · U · Cheap |
| 9 | Rogue planet | A dark, wandering planet crosses far away, blotting out stars as it passes. | Sight · Serious · R · New |
| 10 | Micrometeoroid sprinkle | Tiny pings on the hull. Small hull wear, slight RIDE wiggle. | Hazard · Serious · C · Cheap |
| 11 | Comet tail crossing | You fly through sparkly dust; the radio shimmers. | Sight · Cute · C · Reuse |
| 12 | Picnic table | A picnic table with a still-steaming pie on it. Nobody around. | Sight · Weird · U · New |
| 13 | The eyeball | A huge drifting eyeball blinks at you once. | Sight · Weird · R · New |
| 14 | Space jogger | A critter in a spacesuit jogging on nothing. Waves. | Sight · Silly · U · New |
| 15 | You are here | A map sign with a "YOU ARE HERE" arrow pointing at empty space. | Sight · Silly · C · Reuse |
| 16 | Echo transponder | Your own rig's ID pings from somewhere ahead. It fades before you reach it. | Radio · Weird · R · Cheap · Story |
| 17 | Self-playing piano | A grand piano tumbles past, playing itself. | Sight · Weird · R · New |
| 18 | Ancient probe | An old golden probe broadcasting greetings in 50 languages (all gibberish). | Sight · Serious · R · New |
| 19 | Starfield smile | A patch of stars rearranges into a smiley face, then back. | Sight · Weird · R · Cheap |
| 20 | Dust bunnies | Literal glowing dust bunnies drift by. The bunny mutters "...cousins?" | Sight · Cute · U · New |
| 21 | Fog wall | A slow wall of fog with faint lights moving inside. | Sight · Weird · U · Reuse |
| 22 | Napping trucker | A parked rig with dim lights. Pass close and you hear snoring on the CB. | Sight · Cute · C · Reuse |
| 23 | Space tumbleweed | A ball of tangled cable rolls past. | Sight · Silly · C · New |
| 24 | Star krill | A swirl of tiny glowing krill circles the rig for a while. | Sight · Cute · U · New |
| 25 | Rest area | "Deep Space Rest Area, 2 km." A tiny pullout with one bench and a great view. Stop for a long-idle moment. | Opportunity · Cute · U · New |
| 26 | Gravity eddy | An invisible current nudges you sideways. Steady steering keeps the cargo happy. | Hazard · Serious · C · Cheap |
| 27 | Birthday balloons | Floating balloons. One says "HAPPY 400TH." | Sight · Cute · C · New |
| 28 | Cosmic string twang | A visible ripple passes; every sound pitches down for a moment. | Sight · Weird · R · New |
| 29 | Star fisherman | A critter fishing off a rock, line dropping into nothing. Catches a tiny star as you pass. | Sight · Cute · U · New |
| 30 | Long nothing | Nothing happens for a long stretch. Then the DJ: "Y'all still out there? Real quiet tonight." | Radio · Cute · C · Cheap |


## 2. Traffic lanes (31–65)


| # | Event | What happens | Tags |
|---|---|---|---|
| 31 | Freighter flyby variants | New labels and colors for the existing capital-ship flyby ("Navy Leisure Barge," "Retiree Cruise Liner"). | Sight · Silly · C · Reuse |
| 32 | Join the convoy | A convoy of haulers. Flash your lights to join; riding in the convoy steadies the RIDE bar. | Opportunity · Cute · U · New mechanic |
| 33 | Slowpoke | A tortoise in a tiny ship doing a crawl in the fast lane. | Sight · Silly · C · Reuse |
| 34 | Courier cut-off | A pigeon courier cuts you off, yelling gibberish. | Encounter · Silly · C · Reuse |
| 35 | Tow ship | A tow ship hauling a broken rig. The driver waves. | Sight · Cute · C · Reuse |
| 36 | Construction zone | Floating orange cones, a reduced speed limit, and a flagger with a STOP/SLOW sign. | Hazard · Silly · C · New |
| 37 | Wide load | A whole house being hauled with an "OVERSIZE LOAD" banner. Pass carefully. | Hazard · Silly · U · New |
| 38 | Ice cream ship | Plays its jingle. Flag it down to buy a cone. | Opportunity · Cute · U · New |
| 39 | Wedding procession | Ships with streamers and cans trailing. Honk to congratulate and get a small tip. | Encounter · Cute · U · New mechanic (horn) |
| 40 | Funeral procession | Slow dark ships, lights on. Tradition is to dim your lights and ease off. The bunny goes quiet. | Sight · Serious · U · Reuse · Story-adjacent |
| 41 | Student driver | A ship with a "STUDENT DRIVER" sign weaving all over. | Hazard · Silly · C · Reuse |
| 42 | Gate merge jam | Traffic backed up at a jump-gate merge. Everyone chats on the CB. | Hazard · Silly · U · Reuse |
| 43 | Robot hitchhiker | A robot holding a cardboard sign: "ANYWHERE BUT HERE." | Encounter · Silly · U · New |
| 44 | Tourist bus | A space bus full of tourists photographing you. | Sight · Cute · C · New |
| 45 | Breakdown on the shoulder | A rig with hazard lights and a dead thruster. Share fuel for a tip and reputation, or pass. | Encounter · Cute · C · Reuse |
| 46 | Fender-bender | Two ships bumped; the drivers argue on open comm. Traffic slows to rubberneck. | Radio · Silly · U · Reuse |
| 47 | Escaped space cows | Space cows drift across the lane after a spill. Weave through; the farmer apologizes. | Hazard · Silly · U · New |
| 48 | Drag race | A hot-rodder challenges you to race to the next marker. Win credits; risk the cargo. | Opportunity · Silly · U · New mechanic |
| 49 | Billboard ship | A mobile billboard with a rotating ad. | Sight · Silly · C · Reuse |
| 50 | Inflatable hot dog | A parade float shaped like a giant hot dog. | Sight · Silly · U · New |
| 51 | One letter | A frantic mail courier asks you to carry one letter to the next station. | Opportunity · Cute · C · Cheap |
| 52 | Trucker shuttle | A shuttle of sleepy truckers heading to a rest stop. They wave. | Sight · Cute · C · Reuse |
| 53 | Military escort | A flotilla passes; the radio asks civilians to yield. Pull over until it's gone. | Hazard · Serious · U · Reuse |
| 54 | Ambulance | Siren behind you. Pull over to let it pass for a courtesy bonus. | Encounter · Serious · C · Reuse |
| 55 | Trap warning | A passing trucker flashes lights: "Biscuit's in the bushes up ahead." | Radio · Silly · C · Cheap |
| 56 | Roadside tune-up | A mechanic stand: "THRUSTER TUNE-UP 50¢." Small handling buff for this haul. | Opportunity · Silly · U · New |
| 57 | Lost tourist | A lost tourist asks for directions. Point them right or wrong. | Encounter · Silly · C · Cheap |
| 58 | Car carrier | A hauler carrying twelve tiny spaceships. | Sight · Cute · C · New |
| 59 | Spilled ball bearings | A glittering spill of ball bearings. Bumpy ride. | Hazard · Silly · C · Reuse |
| 60 | Horn salute | Pass a rig and honk; it honks back. | Encounter · Cute · C · New mechanic (horn) |
| 61 | Lane ends | "FAST LANE ENDS." Everyone merges at once. | Hazard · Silly · C · Reuse |
| 62 | Dancing traffic robot | A traffic robot waving glow sticks to the beat of your radio. | Sight · Silly · U · New |
| 63 | Bell hauler | A rig hauling a giant bell that bongs on every bump. | Sight · Silly · U · New |
| 64 | Pizza drone flock | A swarm of pizza delivery drones crosses the lane like birds. | Sight · Cute · C · New |
| 65 | The rival | A recurring rival trucker racing you to the same station. Friendly trash talk. | Encounter · Silly · U · New mechanic |


## 3. Station approach (66–85)


| # | Event | What happens | Tags |
|---|---|---|---|
| 66 | Holding pattern | Approach control asks you to circle for 30 seconds. The DJ fills the time. | Hazard · Silly · C · Cheap |
| 67 | Docking queue | Ships lined up outside the ring. A sign: "NOW SERVING #47." | Sight · Silly · C · Reuse |
| 68 | Crate catch | Dock workers playing catch with a crate in the open bay. | Sight · Cute · C · New |
| 69 | Window washers | Little bots squeegeeing the station windows. | Sight · Cute · C · New |
| 70 | Light show | The station is throwing itself a birthday light show. | Sight · Cute · U · Reuse |
| 71 | Fireworks | Fireworks over the station for a holiday. | Sight · Cute · R · New |
| 72 | Customs scan | A scan beam sweeps over your rig on approach. | Sight · Serious · C · Cheap |
| 73 | Space pigeons | Pigeons nesting on the antenna scatter as you arrive. | Sight · Silly · C · New |
| 74 | Stuck hangar door | The door jams. A mechanic bangs it with a wrench over comm. | Hazard · Silly · U · Cheap |
| 75 | Kids at the window | Kids waving from a viewport. | Sight · Cute · C · Reuse |
| 76 | Ad blimp | An advertising blimp circling the station. | Sight · Silly · C · Reuse |
| 77 | Wrong ring | Traffic control apologizes and reassigns you to a different ring. | Hazard · Silly · U · Cheap |
| 78 | Protest flotilla | Little ships with signs: "MORE NAPS FOR HAULERS." | Sight · Silly · U · New |
| 79 | Garbage barge | A garbage barge leaving, trailed by squawking space gulls. | Sight · Silly · C · New |
| 80 | Lost suitcase | A suitcase drifting from the station. Return it for a tip. | Opportunity · Cute · U · New |
| 81 | Gravity test | Through the windows, everything inside floats for a second. | Sight · Silly · U · Reuse |
| 82 | Broken neon | A station sign with missing letters spells something funny. | Sight · Silly · C · Cheap |
| 83 | Food truck | A food truck ship parked by the ring, grill smoking. Buy a snack. | Opportunity · Cute · U · New |
| 84 | Welcome drone | First visit to a new system: a drone brings you a flower garland. | Encounter · Cute · R · New |
| 85 | Sleepy controller | Night shift only. The approach controller dozes off mid-sentence. | Radio · Cute · U · Cheap |


## 4. Planet and moon orbit (86–110)


| # | Event | What happens | Tags |
|---|---|---|---|
| 86 | Space elevator | A cable rising from the planet with cars crawling up it. | Sight · Serious · U · New |
| 87 | Debris belt | A band of orbital junk to weave through. | Hazard · Serious · C · Reuse |
| 88 | Weather satellite | A satellite turns and snaps your photo. | Sight · Silly · C · New |
| 89 | Face moon | A moon with a billionaire's giant face carved into it. | Sight · Silly · R · New |
| 90 | Aurora | Aurora dancing over the planet's night side. | Sight · Cute · U · New |
| 91 | Ring gap | Fly through a gap in a sparkling ice ring. | Opportunity · Cute · U · New |
| 92 | Slingshot window | A glowing marker shows a perfect slingshot path for free speed. | Opportunity · Serious · C · Reuse |
| 93 | Orbital farm | Greenhouses full of glowing crops. | Sight · Cute · U · New |
| 94 | Rocket launch | A rocket rises from the surface and passes you. | Sight · Serious · U · New |
| 95 | Meteor shower below | Meteors burning up in the atmosphere under you. | Sight · Cute · U · New |
| 96 | Orbital hotel | A hotel with a swimming pool visible under a glass dome. | Sight · Cute · U · New |
| 97 | Drive-in moon | A moon with a drive-in movie screen. Tune the radio to hear the movie. | Opportunity · Cute · R · New |
| 98 | City-light ad | The night side's city lights spell out an advertisement. | Sight · Silly · R · Cheap |
| 99 | Terraformer | A machine puffing clouds onto a bare moon. | Sight · Serious · U · New |
| 100 | Moon volcano | A volcano erupting a glittering plume into space. | Sight · Serious · U · New |
| 101 | One-house moon | A tiny moon with one house and a mailbox. | Sight · Cute · U · New |
| 102 | Local station | A planet's local radio station bleeds onto your dial. | Radio · Cute · C · Cheap |
| 103 | Rope-bridge moons | Two moons almost touching, joined by a rope bridge. | Sight · Silly · R · New |
| 104 | Planet sneeze | A geyser of clouds bursts off the planet. | Sight · Weird · R · New |
| 105 | Satellite graveyard orbit | Rows of retired satellites like tombstones. | Sight · Serious · U · Reuse |
| 106 | Wedding chapel | "Little Chapel of the Void," with a neon heart. | Sight · Silly · U · New |
| 107 | Planet-sized SALE | Tugboats pulling a planet-sized "SALE" banner. | Sight · Silly · R · New |
| 108 | Whale breach | Tidewater only: a whale breaches out of the ocean world into low orbit. | Sight · Cute · R · Reuse |
| 109 | Golden hour | You cross the terminator into sunrise. Warm light floods the cab; the DJ goes quiet. | Sight · Cute · U · Cheap |
| 110 | Laundry day | A moon base with laundry drifting on a line. | Sight · Silly · U · New |


## 5. Weather (111–130)


| # | Event | What happens | Tags |
|---|---|---|---|
| 111 | Ion storm variants | New colors and intensities for the existing ion storm. | Hazard · Serious · C · Reuse |
| 112 | Solar flare | The screen brightens and the radio drops out. Duck behind a rock for a small bonus. | Hazard · Dangerous · U · New |
| 113 | Static storm | HUD numbers glitch and flicker. | Hazard · Weird · U · Cheap |
| 114 | Dust storm | Visibility shrinks as the fog thickens. | Hazard · Serious · C · Reuse |
| 115 | Magnetic storm | The compass tape spins and the nav arrow wobbles. | Hazard · Serious · U · Cheap |
| 116 | Ice hail | Ice pellets plink off the hull. | Hazard · Serious · C · Reuse |
| 117 | Plasma rain | Glowing streaks falling past the rig. | Sight · Weird · U · New |
| 118 | Calm pocket | Inside a quiet nebula pocket, sound muffles and everything slows. | Sight · Cute · U · Cheap |
| 119 | Rainbow nebula | The fog slowly cycles through colors. | Sight · Cute · U · Reuse |
| 120 | Gravity tide | The rig rises and falls gently, like a boat. | Hazard · Cute · U · Cheap |
| 121 | Rock lightning | Lightning arcs between asteroids. | Sight · Dangerous · U · New |
| 122 | Sunspot season | The sun flickers; truckers chatter about it on the CB. | Radio · Serious · U · Cheap |
| 123 | Spore fog | Glowing spores dust the windshield. Hit the wipers. | Cab · Cute · U · New mechanic (wipers) |
| 124 | Cosmic wind | A particle stream you can ride for free speed. | Opportunity · Serious · U · New |
| 125 | Snow nebula | Snowflakes stick to the windshield. | Cab · Cute · U · New |
| 126 | Space thunder | You hear thunder. The DJ points out that's impossible. | Radio · Weird · R · Cheap |
| 127 | Radiation belt | The counter clicks fast; go around or punch through quickly. | Hazard · Dangerous · U · Cheap |
| 128 | Aurora curtain | Fly through a curtain of light that washes the cab in color. | Sight · Cute · U · New |
| 129 | Skip signal | A station from another system comes in for a few minutes. | Radio · Cute · U · Cheap |
| 130 | Time pocket | The clock jumps five minutes and everything goes slow-motion for a moment. | Hazard · Weird · R · Cheap |


## 6. Creatures (131–155)


| # | Event | What happens | Tags |
|---|---|---|---|
| 131 | Whale calf | A space whale calf follows the rig for a while, then swims home. | Sight · Cute · U · Reuse |
| 132 | Windshield jelly | One jellyfish from a migration sticks to the windshield, then lets go. | Cab · Cute · U · Reuse |
| 133 | Space gulls | Gulls chase the rig hoping for snacks. | Sight · Silly · C · New |
| 134 | Rock-hugging squid | A giant squid wrapped around an asteroid. | Sight · Weird · U · New |
| 135 | Crystal moths | Moths flutter toward your headlights. | Sight · Cute · C · New |
| 136 | Asteroid turtle | A "rock" wakes up, yawns, and swims away. | Sight · Cute · R · New |
| 137 | Manta formation | Stellar mantas gliding in formation alongside you. | Sight · Cute · U · New |
| 138 | Hull kitten | A tiny space kitten on your hull wants in. Let it in and it becomes a cab pet. | Encounter · Cute · R · New mechanic |
| 139 | Cloud sheep | A herd of fluffy cloud-sheep drifting by. | Sight · Cute · U · New |
| 140 | Windshield starfish | A starfish clings to the cockpit glass. | Cab · Cute · U · New |
| 141 | Space barnacles | Barnacles slowly grow on your hull; get them washed at a station. | Hazard · Silly · U · New mechanic |
| 142 | Void eel | A long shiny eel slithers past. | Sight · Weird · U · New |
| 143 | The big eye | A huge eye opens inside a nebula, watches, then closes. | Sight · Serious · R · New |
| 144 | Snail trail | A space snail's glowing trail crosses the lane. Steering slides on it. | Hazard · Silly · U · New |
| 145 | Firefly words | Fireflies briefly spell a word. | Sight · Cute · R · Cheap |
| 146 | Space bees | Bees pollinating a floating field of flowers. | Sight · Cute · U · New |
| 147 | Comet pup | A tiny comet with eyes follows you to the station. | Sight · Cute · R · New |
| 148 | Water bears | A colony of microscopic-turned-huge water bears waving. | Sight · Cute · U · New |
| 149 | Space geese | Geese in V formation honk as they pass. | Sight · Silly · C · New |
| 150 | Satellite octopus | An octopus playing with satellites like toys. | Sight · Silly · U · New |
| 151 | Jelly cube | A gelatinous cube drifts by with a lost shoe inside. | Sight · Weird · U · New |
| 152 | Meteor ladybugs | Ladybugs riding a meteor. | Sight · Cute · C · New |
| 153 | Moon-eater | Far away, a giant shadow nibbles a dead moon. | Sight · Serious · R · New |
| 154 | Glowworm asteroid | A hollow asteroid lit from inside by glowworms. | Sight · Cute · U · New |
| 155 | Pufferfish | A space pufferfish inflates when you get close. Bonk risk. | Hazard · Silly · C · New |


## 7. Derelicts, junk and salvage (156–175)


| # | Event | What happens | Tags |
|---|---|---|---|
| 156 | Auto-SOS derelict | A derelict blinking an automated SOS. Nobody's been aboard for years. | Sight · Serious · U · Reuse |
| 157 | Junk spill variants | New mixes for the existing junk spill. | Hazard · Silly · C · Reuse |
| 158 | Household junk cloud | A fridge, a toilet and a bicycle tumbling together. | Hazard · Silly · C · New |
| 159 | Lost cargo crate | A crate marked FRAGILE. Scan it, then deliver it to its owner for a reward. | Opportunity · Serious · U · New mechanic |
| 160 | Ghost cruise liner | A derelict liner with ballroom music still playing. | Sight · Weird · R · New |
| 161 | Shipwreck figurehead | An old wreck with a carved figurehead on the bow. | Sight · Serious · U · New |
| 162 | Half-message billboard | A wrecked billboard with a strange half-finished message. | Sight · Weird · U · Cheap |
| 163 | Empty escape pod | An escape pod with nobody in it, and a note. | Sight · Serious · R · New |
| 164 | The twin rig | A derelict rig of the same model as yours, in the same paint. | Sight · Serious · L · Reuse · Story |
| 165 | Satellite graveyard | A field of dead satellites. | Sight · Serious · U · Reuse |
| 166 | Forgotten statue | A huge statue of some hero nobody remembers. | Sight · Serious · U · New |
| 167 | Clean cut | A ship sliced perfectly in half, lights still on in both halves. | Sight · Weird · R · New |
