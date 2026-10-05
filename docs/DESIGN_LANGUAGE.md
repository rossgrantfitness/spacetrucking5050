# Space Truckin' 5050: Design Language & Inspiration

*Oct 5, 2026 · by Ross Grant (the developer). Saved here as sent, formatted
for the repo. Binding for art, UI, characters, sound and tone, alongside
`CLAUDE.md` and `CHARACTER_BIBLE.md`.*

## Vision

Space Truckin' 5050 is a cozy PSX-style space trucking sim: a burnt-out
bunny hauls cargo across a surreal galaxy with heavy music on the radio. It
looks like Mega Man Legends, flies through a universe built like Halo,
feels like Cowboy Bebop, and sounds and dreams like Heavy Metal.

**Logline.** A 35-year-old lop-eared bunny, tired of all of it, drives the
rig she inherited from her late husband through a weird, beautiful galaxy,
one delivery at a time.

**Tone words.** Cozy. Cute. Chill. Tired. Weird. Loud when the radio's on.

## Design pillars

1. **Cozy first.** Safety, abundance, softness.
2. **A trucking game first.** The drive is the joy: cruising, radio, gizmos, getting paid, upgrading. No combat.
3. **Toy-like critters, monumental machines.** Small, soft, rounded characters against huge, hard, brutalist industry.
4. **Strict PSX, warm not creepy.** Wobbly vertices, warped textures, dither, low resolution, but saturated color and neon instead of horror gray.
5. **Mundane plus surreal.** Truck stops, toll booths and radio ads make a fully surreal universe feel like home.
6. **Everything is buyable.** Money drives progression, up to buying the delivery company itself.

## The four core inspirations

Each core inspiration owns one layer of the game: Mega Man Legends owns the
characters, Halo owns the hardware, Cowboy Bebop owns the mood, and Heavy
Metal owns the sound and the strangeness.

| Inspiration | Owns | What we take | What we leave |
|---|---|---|---|
| Mega Man Legends (PS1, 1997) | Characters and charm | Toy-like proportions: big heads, big boots, mitten hands. Clean flat color blocks. Painted faces that swap expressions. A home that is also a vehicle (the Flutter airship). Blue-collar diggers and mechanics. Sunny optimism even in ruins. | Combat, dungeons, lock-on. Its kid-adventure innocence: our lead is a tired adult. |
| Halo (2001 onward) | Hardware and scale | Brutalist, slab-sided human ships: rectangular hulls, recessed bays, exposed ribbing, kilometers long. Industrial military-utility stencils and numbers. Huge structures with tiny figures. The "workhorse" feel of the UNSC fleet. | War, soldiers, aliens as enemies, weapons. Specific ship designs and names. |
| Cowboy Bebop (anime, 1998) | Mood and story | A rundown ship as a home. Broke, tired professionals doing jobs to pay for fuel and food. Melancholy under the jokes; a past that surfaces slowly. Episodic structure. Music as identity. A lived-in, used-future solar system. | Gunfights and bounty violence. The noir crime plots. |
| Heavy Metal (magazine and 1981 film) | Sound, strangeness, the cosmic | Hard rock and metal as the soul of space. Surreal, psychedelic, Moebius-style landscapes. Blue-collar heroes: the "Harry Canyon" cab driver is a working stiff in a future city. The opening, a classic car descending from orbit, is pure space-trucker energy. Saturated airbrushed color. | Sex, gore and violence. All of it. |

**The formula.** Mega Man Legends critters, living in a Cowboy Bebop life,
driving through a Halo-scale galaxy, with Heavy Metal blasting on the radio.

## Visual design language

The whole look rests on one contrast: soft, round, colorful critters inside
hard, square, enormous machines, all rendered like a 1998 PlayStation game
that is happy instead of haunted.

### Shape language

| Subject | Shapes | Inspired by |
|---|---|---|
| Characters | Round, chunky, toy-like; big heads, mittens, boots | Mega Man Legends, Animal Crossing, Tail Concerto |
| Giant ships and stations | Slabs, bricks, right angles, ribbing, recessed bays | Halo, Homeworld, EVE Online, Chris Foss paintings |
| The player's rig | A wedge cab on a heavy chassis; a truck, not a fighter | Mega Man Legends' Flutter, Alien's Nostromo, real semi trucks |
| Surreal space | Organic, flowing, psychedelic: jellyfish, whales, nebula curls | Heavy Metal, Moebius, Space Dandy |

### Color

- **Space:** pure black to deep navy, crisp white stars, oversized swirly planets.
- **Machines:** dark plating with safety orange, hazard yellow and black stripes, faded invented logos.
- **Neon:** green, purple, cyan and orange signs and screens, lighting the dark interiors.
- **Characters:** warm, slightly faded primaries (Mega Man Legends colors pulled 15% toward gray).
- **Each solar system:** one signature fog color, such as purple for home and teal for Tidewater.

### PSX rendering

- Vertex wobble, affine texture warping, ordered dither, low internal resolution, nearest-neighbor textures.
- Large faces split into grids so huge ships don't tear.
- Distance fog tinted per system; it hides pop-in the way Silent Hill's fog did, but colorful instead of gray.
- Fixed-camera pre-rendered interiors, as in Final Fantasy VII and VIII.

### Light

Neon in the dark: interiors are dark blue-gray, lit by glowing panels and
signs, like a late-night truck stop in Blade Runner's city or Akira's
Neo-Tokyo, but warm. Space is lit by one big sun per system, with golden
hours when you cross a planet's terminator.

### Scale

The bunny never grows; the world does. Tiny critters, huge hangar doors with
small doors cut into them, and kilometer-long ships you overtake for half a
minute. Halo's ring and Final Fantasy VII's Midgar plate are the reference
for "small person, gigantic structure."

### UI and type

- Chunky pixel fonts, segmented bars, blinking icons, numbers that tick rather than glide.
- Most readouts live in the cockpit as physical instruments; the HUD stays small and in the corners.
- References: Star Fox 64 comm portraits, the green monochrome cockpit screens of late-90s PS1 space games, Jet Set Radio's graffiti energy for logos and signs.

## Characters

Every character is a Mega Man Legends-style toy with a Cowboy Bebop-style
life: chunky, colorful and cute on the outside, tired, broke and a little
sad on the inside. The full rules live in the Character Design Bible
(`CHARACTER_BIBLE.md`).

### The bunny

A 35-year-old lop-eared bunny in a Rock N Roll trucker cap, open utility
vest and giant work boots, cigarette drooping, eyes half-lidded. She
inherited the rig from her late husband. She stays steady; the world
changes around her.

| Trait | Reference |
|---|---|
| Lazy cool, a past she doesn't talk about | Spike Spiegel (Cowboy Bebop) |
| Tired adult running a ship to make ends meet | Jet Black (Cowboy Bebop) |
| Burnt-out pilot hiding grief behind sarcasm | Porco Rosso (Studio Ghibli) |
| Working stiff in a sci-fi city who just wants to finish the shift | Harry Canyon (Heavy Metal) |
| Blue-collar crew grumbling about pay and bonuses | Parker and Brett (Alien) |
| Slob space worker, oddly lovable | Dave Lister (Red Dwarf) |
| Mechanic who keeps an old rig flying | Roll Caskett (Mega Man Legends) |
| Rabbit pilot in a cockpit | Peppy Hare (Star Fox 64) |

### The cast so far

| Character | Species | Role |
|---|---|---|
| Dottie | — | Home dispatch; sends the first job |
| Marge | Owl | Runs the truck stop diner; first client (nebula pies) |
| Dusty | Beaver | Garage: repairs and upgrades |
| Lily | Frog | Fuel pumps at the truck stop |
| Pip | Cheek-pouched critter | Arcade lounge regular |
| Wendell | Tusked, mustached critter | Fixture in a diner booth |
| Gill | Otter | Owns Tidewater Cannery; Marge's cousin |
| Moe | Sloth | Runs the Gas-N-Go 47 drive-through, very slowly |
| Deputy Biscuit | Hound | Space cop running speed traps |
| Sketch concepts | Crocodile, pig, cat | Slick client or company boss; grumpy dispatch clerk; hallway neighbor |

**Cast references.** Animal Crossing villagers for one-note warmth,
Futurama's Planet Express crew for a workplace family, Cowboy Bebop's
one-episode strangers for odd clients, and Star Fox 64's crew for radio
banter.

## Ships and machines

Machines are working equipment, never warships: they look heavy, practical,
patched and enormous, like Halo's human fleet repainted as construction
gear.

### The player's rig

A space semi truck, not a fighter jet: a chunky cab on a long chassis,
hazard-striped struts around the windshield, and a cockpit full of fiddly
instruments and toys. It is her home as much as the Bebop was Spike's and
the Flutter was Mega Man's.

| Element | Reference |
|---|---|
| Ship as a lived-in home | Bebop (Cowboy Bebop), Flutter (Mega Man Legends), Serenity (Firefly) |
| Blue-collar hauler with a grumpy crew | Nostromo (Alien), Red Dwarf |
| Truck cab feel, gauges, CB radio | American and Euro Truck Simulator, 1970s trucker films |
| Hazard-striped cockpit framing | Late-90s PS1 space games |
| Ship silhouette | Arwing (Star Fox 64), X-wing (Rogue Squadron) |

### Giant freighters

Original "flying brick" designs with invented companies and faded liveries:

| Ship | Look | Reference |
|---|---|---|
| Stack ship | Kilometer of stacked containers, one engine pod clamped on the back | Halo's civilian freighters, EVE Online's Caldari freighters |
| Ore crawler | Yellow construction-equipment ship with gantry cranes eating an asteroid | Homeworld's resource collectors |
| Ice tug | Small tug towing a comet chunk many times its size | The Expanse's Canterbury |
| Hab brick | Residential block with lit windows, gardens, laundry lines | Halo's colony ships, Chris Foss paintings |
| Mega-tanker | Spine of giant spherical tanks | Real LNG tankers |
| Garbage scow | Rusty open barge trailed by space gulls | Planetes, WALL-E |
| Rig carrier | Mothership carrying dozens of trucks | Car-carrier trucks |
| Moving truck stop | A Gas-N-Go bolted onto a slow freighter | Pure invention |

**Making them feel huge.** Lit windows with tiny silhouettes, EVA workers
on catwalks, running lights, the cab going dark when one blocks the sun, and
a hull long enough to fill the window edge to edge.

## Places

Every place is either a cozy pocket (warm, neon, cluttered, small-scale
life) or a monument (vast, quiet, industrial), and the game moves between
the two.

| Place | What it is | References |
|---|---|---|
| Home base | A huge old starship where she rents a small apartment; dispatch and hangar inside | The Citadel's wards (Mass Effect), Bebop's living room, Animal Crossing's town hall |
| Truck stop | Neon concourse with diner, fuel, garage, arcade, job board under a giant window | Roadside diners, Twin Peaks' Double R, Jet Set Radio's neon, the cantina in Star Wars |
| Tidewater Cannery | Industrial teal-system cannery with silos, conveyors and a neon fish sign | Real fish canneries, Ghibli's working towns |
| Gas-N-Go 47 | Drive-through gas station in space | Texas highway gas stations, Futurama's roadside stops |
| Giant ship interiors | Hab brick atrium, stack-ship cargo avenue, ore-crawler refinery hall | Final Fantasy VII's Midgar, Halo's Pillar of Autumn hallways, Blade Runner interiors |
| Open space | Mostly empty, with oddities, traffic near stations and planets | Space Dandy's planets, Outer Wilds' solar system, Freelancer's trade lanes, Moebius landscapes |

### Fixed-camera interiors

Interiors use Final Fantasy VIII-style fixed camera shots on pre-rendered
backgrounds. Big-ship interiors use two to three times as many shots as the
truck stop, at least a third of them extreme wide, with the bunny a few
pixels tall. Reference shots: Midgar's plate seen from the slums, Halo's
control-room approach, the Nostromo's long corridors, and Resident Evil's
mansion for how fixed cameras build atmosphere.

### Open space

Space is mostly empty, and the emptiness is part of the mood. Activity
clusters near stations and planets: traffic, construction, cops,
billboards. Deep space gets lonely oddities: a floating vending machine, a
self-playing piano, a lighthouse with no rock. The 250 route events in
ROUTE_EVENTS_250.md (in the repo: `docs/ROUTE_EVENTS_LIST.md`, 1-167 so
far) fill this world.

## Sound and radio

The radio is the soul of the drive, and it leans hard into electronica,
hard rock, metal and hip hop, the way Heavy Metal's soundtrack made rock the
voice of space and Cowboy Bebop made music its identity.

### Radio

- Up to 20 stations, each with a DJ, a vibe, and fake ads for surreal products, as in GTA and Rebel Galaxy Outlaw.
- Launch with five or six: Subspace FM (drum and bass), KRSH 666 (metal), Asteroid Rock (hard rock), Orbit 808 (hip hop), Cozy Coil (lo-fi), and the mystery numbers station.
- Mechanics: night-only stations, regional stations that fade with distance, a pirate station the cops shut down, a custom station that plays the player's own files.
- When the radio is off, gentle ambient music plays.

| Station feel | References |
|---|---|
| Drum and bass, jungle, breakbeat | Late-90s Toonami blocks, Jet Set Radio, Wipeout |
| Synthwave, outrun | Drive-era synth scores, 1980s anime |
| Doom and stoner metal | Heavy Metal's soundtrack, desert rock |
| Classic hard rock | 1970s and 1980s trucker radio, Heavy Metal |
| Boom bap, lo-fi hip hop | Samurai Champloo's soundtrack, late-night beat streams |
| Genre-mixing chaos | Cowboy Bebop's Seatbelts |
| Talk radio and callers | Late-night trucker call-in shows, GTA talk stations |
| Numbers station | Real shortwave numbers stations |

### Sound design

- Engine hum that rises with throttle; Doppler whoosh as ships pass; a deep rumble for giant freighters.
- Cockpit clicks, switches, creaks; radio static before and after every comm line.
- Big reverb and echoing gibberish announcements inside giant ships.
- Gibberish voices for everyone, Animal Crossing-style.

## Story, tone and humor

The story is told the Cowboy Bebop way: mostly small episodes and odd jobs,
with one quiet sorrow underneath that surfaces a little at a time.

### The husband

Her late husband's story is never front-loaded. It leaks through a photo on
the visor, a client who knew him, a voicemail found after an upgrade, a twin
derelict rig, a ghost rig legend on the CB, and the mystery numbers
station. References: Spike's past in Cowboy Bebop, Porco Rosso's grief, the
slow environmental storytelling of Outer Wilds and Gone Home.

### Tone mix

| Ingredient | Share | References |
|---|---|---|
| Cozy routine | Most of the time | Stardew Valley, Animal Crossing, Euro Truck Simulator |
| Absurd comedy | Often | Space Dandy, Red Dwarf, Hitchhiker's Guide to the Galaxy, Futurama |
| Wonder and awe | Regularly | Heavy Metal, Moebius, Outer Wilds, 2001: A Space Odyssey |
| Blue-collar realism | Underneath everything | Planetes, Alien, Cowboy Bebop |
| Melancholy | Rarely, and it counts | Cowboy Bebop, Porco Rosso |

### Humor rules

- **Mundane meets cosmic.** Toll booths, parking tickets and pie deliveries in a galaxy of space whales.
- **Funny names on serious things.** "Navy Leisure Barge," "Discount Mattress Freighter."
- **Deadpan lead.** The bunny underreacts to everything; the world overreacts.
- **Bureaucracy is the villain.** Fines, forms and permits, never monsters.
- **Original jokes only.** Inspired by those shows' spirit, never their characters, catchphrases or bits.

The full story, its layers and the clue trail: Story bible (not in the repo
yet).

## Inspiration library

More than 50 works feed the game, grouped by medium with the core four
first; each line says exactly what we borrow. Notes come from general
knowledge of these works, not fresh research.

| Work | Medium | What we take |
|---|---|---|
| Mega Man Legends | Game | Character style, swapped faces, ship as home, blue-collar charm |
| Halo | Game | Brutalist ships, industrial scale, tiny figures on huge structures |
| Cowboy Bebop | Anime | Broke crew on a rundown ship, melancholy, music as identity |
| Heavy Metal | Film and magazine | Rock and metal soundtrack, surreal cosmic art, the working-stiff cab driver |
| Star Fox 64 | Game | Animal pilots, comm portraits, gibberish voices |
| Final Fantasy VII | Game | Pre-rendered scale (Midgar), tiny characters in vast spaces |
| Final Fantasy VIII | Game | Fixed camera shots, the Ragnarok as lived-in ship |
| Tail Concerto | Game | Animal characters running big machines |
| Animal Crossing | Game | Cute critters, gibberish voices, cozy routine |
| Easy Delivery Co. | Game | Lo-fi blue-collar delivery mood |
| Rebel Galaxy Outlaw | Game | Space trucker life, radio stations with DJs and ads |
| American and Euro Truck Simulator | Game | Truck cab interiors and trucker culture |
| Stardew Valley | Game | A cozy community of familiar faces |
| Elite and Elite Dangerous | Game | Docking as ceremony, the lonely trader's life |
| EVE Online | Game | Industrial freighters, a player-driven space economy |
| Star Citizen | Game | Ships with distinct visual personality |
| Freelancer | Game | Trade lanes, asteroid fields, engine trails |
| Homeworld | Game | Yellow construction-equipment ships |
| Outer Wilds | Game | A small handmade solar system, discovery, story through places |
| Death Stranding | Game | Delivery as story, lonely routes, reconnecting people |
| No Man's Sky | Game | Colorful procedural skies and planets |
| Mass Effect | Game | Huge lived-in station hubs |
| Grand Theft Auto | Game | Radio stations, fake ads, talk radio |
| Jet Set Radio | Game | Neon, graffiti energy, pirate-radio attitude |
| Wipeout | Game | Electronica and bold industrial graphic design |
| F-Zero | Game | Hot-rod vehicle design, giant futuristic structures |
| Katamari Damacy | Game | Surreal cosmic humor |
| Space Channel 5 | Game | Retro-future space pop style |
| Silent Hill | Game | Fog that hides draw distance, recolored here to be cozy |
| Resident Evil (1996) | Game | Atmosphere built with fixed cameras |
| Space Dandy | Anime | Absurd planet-of-the-week adventures, psychedelic color |
| Planetes | Anime | Blue-collar space debris collectors, workplace realism |
| Outlaw Star | Anime | Scrappy ship crews, space westerns |
| Samurai Champloo | Anime | Hip hop and lo-fi as a soundtrack identity |
| Akira | Anime | Neon cities at night |
| Redline | Anime | Wild hot-rod vehicle designs |
| Macross | Anime | Giant colony ships, music in space |
| Mobile Suit Gundam (Universal Century) | Anime | Industrial space colonies, working-class pilots |
| Porco Rosso | Anime film | A grieving, sarcastic pilot; flying as escape |
| Kiki's Delivery Service | Anime film | Delivery work as a cozy coming-of-age |
| Toonami | TV block | Late-night anime vibe, electronica bumpers, robot host |
| Alien (1979) | Film | The Nostromo: space truckers complaining about their pay |
| Space Truckers (1996) | Film | Literal space trucking, campy and greasy |
| Silent Running | Film | Lonely worker on a huge ship |
| Dark Star | Film | Bored, slobby crew on a long haul |
| Outland | Film | Industrial mining colony grit |
| Blade Runner | Film | Neon in the dark, used future |
| 2001: A Space Odyssey | Film | Docking as a waltz, cosmic awe |
| Star Wars (1977) | Film | The "used universe": dirty, patched machines |
| WALL-E | Film | Lonely blue-collar work, junk in orbit |
| Convoy | Film | Trucker convoys and CB culture |
| Smokey and the Bandit | Film | Truckers versus highway cops, played for laughs |
| Red Dwarf | TV | A slob worker on a giant mining ship |
| Futurama | TV | A delivery company in space |
| Firefly | TV | A cargo ship crew scraping by |
| The Expanse | TV and books | Ice haulers, believable industrial ships |
| Star Trek | TV | Space anomalies, optimism, "strange new worlds" |
| The Hitchhiker's Guide to the Galaxy | Books, radio, TV | Cosmic bureaucracy and absurdity |
| Moebius | Comics and art | Surreal desert-cosmic landscapes, clean line |
| Philippe Druillet | Comics and art | Monumental cosmic architecture |
| Chris Foss | Paintings | Huge colorful brick ships with hazard stripes |
| Syd Mead | Concept art | Industrial futurism, giant vehicles |
| Ralph McQuarrie | Concept art | Lived-in sci-fi hardware |
