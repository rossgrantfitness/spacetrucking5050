# data/

Everything that's *content* rather than *code* lives here, so changing the
game's numbers, names and stuff never needs programming.

- **`tuning.tres`** (with its blueprint `Tuning.gd`): every feel number shared
  by all ships: steering, camera, field of view, dust, trails, engine sound.
  Double-click it and use the Inspector; hover a value to see what it does.
- **`ships/`**: one file per rig. `starter_rig.tres` is *The Thumper*,
  your inherited rig; the others are for sale at Dusty's garage (price,
  model, how much more each job pays for a bigger hold). Each has its own
  top speed, acceleration, how heavy it turns, boost, trail color and
  engine voice. `ships.tres` is the dealer's list; `paints.tres` lists the
  paint shop's colors. Blueprints: `ShipData.gd`, `ShipList.gd`,
  `PaintJob.gd`, `PaintList.gd`.
- **`systems/`**: one file per solar system (`home_system.tres`,
  `tidewater.tres`, `glimmer.tres`), listed in `systems.tres`: its middle, its signature color (tints the space dust,
  the nebula and the HUD frames), haze color (the distance haze faraway
  things fade into), sunlight, fill light and nebula brightness. Flying
  between systems blends their colors. Its planets and sun are SkyBody
  nodes in the flight scene. Blueprints: `SystemData.gd`, `SystemList.gd`.
- **`npcs/`**: one file per person: name, voice pitch, portrait colors and
  what they say. What they say can depend on the story: each person has a
  list of conversations (`Conversation.gd`) with conditions (story flags,
  the job you're hauling), and the first one that fits is used. A
  conversation can set story flags, offer a job or open a menu (job board,
  pumps, garage). `dispatch_morning.tres` is Raccoony; the truck stop folks
  are `truckstop_*.tres`. Blueprint: `NPCData.gd`.
  The truckers you only hear on the comms (Big Wendell, Pip) live here too,
  with a short `comm_name` for the comm portrait.
- **`world_names.tres`**: the big names in one place: the bunny, her
  husband, the base, and what money is called (plus its short form for the
  HUD). Dialogue fills them in where it says `{bunny}`, `{husband}`,
  `{base}` or `{currency}`.
- **`places/`**: one file per place you can dock at (the home base, the
  truck stop, Tidewater Cannery, the Gas-N-Go, The High Roller): its name, its kind (walk
  around inside, a drop-off where you stay in the cab, or a drive-through),
  the counters it has, and who says hello. `places.tres` lists them.
  Blueprint: `PlaceData.gd`.
- **`jobs/`**: one file per job: cargo, client, where it's picked up and
  where it goes, base pay, the optional fragile (care) and rush bonuses,
  and story settings (on the job board or offered in person, repeatable or
  one-off, which story flag it needs or sets). `jobs.tres` lists them all;
  `first_long_haul.tres` is the first mission. Blueprint: `JobData.gd`.
- **`upgrades/`**: one file per rig upgrade sold at a garage: price and how
  much it multiplies top speed, acceleration, turning or the fuel tank.
  `upgrades.tres` is the shop list. Blueprint: `UpgradeData.gd`.
- **`radio/`**: one file per station (name, dial number, DJ, slogan, music
  and ads folders, placeholder loop, made-up song names, text ads, DJ
  banter and reactions, and where and when it comes in), and
  `lineup.tres` listing the stations on the dial. The music itself goes in
  `res://audio/radio/` (see the README there). Blueprints:
  `RadioStation.gd`, `RadioLineup.gd`.
- **`dialogue/flight_chatter.tres`**: what people say over the comms while
  you fly, grouped by who says it and when (takeoff, small talk, approach,
  docking, bonks, boosts, low fuel, rough flying, speeding tickets), optionally only at a place, a point in
  the story or during a job. Blueprints: `ChatterSet.gd`, `FlightChatter.gd`.
- **`logbook/sights.tres`**: every sight that can go in the logbook (its
  name, what Jacki wrote about it, whether it's rare). Blueprints:
  `LogbookEntry.gd`, `Logbook.gd`.
- **`dialogue/story_calls.tres`**: calls that matter, made once each when the
  story's ready (like White's message on the chip Dusty finds). Who, what
  (one card per line), a banner, and when. Blueprints: `StoryCall.gd`,
  `StoryCallList.gd`. The whole story is mapped out in `docs/STORY.md`.
- **`pc/trip_logs.tres`**: White's old notes from the Thumper's trip
  computer, read on the cabin PC (OLD LOGS). About one more comes back each
  delivery. Blueprints: `TripLog.gd`, `TripLogList.gd`.
- **`dialogue/bunny_replies.tres`**: the one-liners Jacki can say back to
  comm calls, grouped by kind of call. Blueprint: `BunnyReplies.gd`.
- **`events/route_events.tres`**: everything that can happen on the road:
  your route events list (1-167 so far) plus the original sights. Each one
  has its zone (deep space, traffic lanes, station approach, orbit,
  weather, anywhere), type, tone, rarity and build cost; whether it's
  built yet (`playable`) and if not, what it `needs`; and what happens: a
  3D thing (big ship, convoy, sign, a passing ship with a story...), a
  call with reply choices, a radio line, a banner, a small effect (hull
  pings, a gravity nudge, dead air...). How busy each zone is, and the
  cooldowns, are in tuning.tres. Made from `docs/ROUTE_EVENTS_LIST.md` by
  `tools/route_events/import_route_events.py` (careful: re-running it
  overwrites edits). Blueprints: `EventData.gd`, `RouteEventList.gd`.
- **`traffic_names.tres`**: the funny names on passing ships' ID labels.
  Add as many as you like.
- **The other folders are empty for now** and fill up as their milestones
  arrive: `clients/` (M5, M8), `outfits/` and `furniture/` (M7).

The pattern for each folder: one small blueprint script (like `ShipData.gd`)
that defines the fields, plus one `.tres` file per thing (like
`starter_rig.tres`). Adding a new ship or system means duplicating a `.tres`
file and editing it in the Inspector. No code.
