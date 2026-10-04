# Things you pass on the road (research notes)

What would a space trucker pass on a long haul? This is the list I worked
from for round 8, what made it into the game, and what's left for later.
The rule I used: **mundane trucker stuff + surreal space stuff**, never
danger. Everything is something to *look at*, *talk about* on the comms,
or *gently steer around*.

## Where the ideas come from

- **Real highway trucking** (the American/Euro Truck Simulator feeling):
  green highway signs counting down the kilometers, the next fuel stop,
  roadside attractions ("world's biggest ___"), weigh stations and speed
  traps, convoys, spilled loads, lighthouses, border crossings, other
  truckers on the CB radio, billboards for the next diner.
- **Space trucking games:** *Star Trucker* (Monster and Monster, published
  by Raw Fury, 2024) is the closest cousin: hauling cargo between stations,
  a CB radio full of characters, a rig you keep running, space weather.
  Sources I read: the game's page at Raw Fury
  (<https://rawfury.com/games/star-trucker/>), its Wikipedia article
  (<https://en.wikipedia.org/wiki/Star_Trucker>), PCGamesN's hands-on
  impressions (<https://www.pcgamesn.com/star-trucker/impressions>) and its
  TV Tropes page (<https://tvtropes.org/pmwiki/pmwiki.php/VideoGame/StarTrucker>).
  We take the *vibe* (the lonely road, the radio voices), not its systems
  or content.
- **Sci-fi in general:** derelict ships with a story, huge ships passing
  close, comets, ion storms, creatures that live in space (whales,
  jellyfish), lonely beacons. Cowboy Bebop's tired, beautiful, absurd
  universe is the tone (see `CLAUDE.md`).

## In the game now

**Fixed, along the road to Tidewater** (`scenes/flight/TidewaterRoad.tscn`,
built by `tools/build_road.gd`):

| Km | What | Why it's there |
|---|---|---|
| 3, 13, 25, 36, 47, 56 | Green highway signs (both directions) | Mundane = homey. Countdown to the next stop. |
| 18 | A junk spill across the lane | Debris to weave through (bonkable). |
| ~30 (1.8 km right) | **Gas-N-Go 47**, a drive-through fuel stop | The optional stop. Moe the sloth runs it. |
| 28 | THE WORLD'S BIGGEST DONUT | A roadside attraction, just because. |
| 31 | The border gate into Tidewater | You know you've crossed over. |
| 33.5 | A lighthouse warning ships off a rock that isn't there anymore | A sweet, slightly sad joke. |
| 40 | *The Dorothy Mae*, an abandoned derelict, one light still blinking | A mystery (lore can hang off it later). |
| 44 | An ion storm off the lane | Radio static, the STORM light, a few jolts. Never damage. |
| 48-53 | Tidewater's icy rocks | A pretty, gentle obstacle field. |
| 52 | A pod of space whales, singing | Tidewater's gimmick (from the brief). |
| 55 | Space patrol radar buoy | The brief's speed trap: a small fine, not a fight. |
| 57.5 | Scrap around the cannery | Industrial clutter near the destination. |
| all the way | Two long-haul truckers and a courier going back and forth | Traffic, engine trails, ID labels. |

**Random, every few kilometers** (`data/events/route_events.tres`, placed
by `scenes/flight/RouteEvents.gd`): a big ship crossing your path (with a
rumbling, Doppler-shifted engine), a convoy of rigs, billboards for
surreal products, comets, cosmic jellyfish drifting by, junk clouds,
derelicts, a giant rubber duck, whales and ion storms (those two only in
Tidewater). Some come with a comment on the comms.

## Ideas for later (not built)

- **Weigh station:** pull in, the scale reads your cargo, a bored clerk
  waves you on. (Overweight = a joke, not a fine.)
- **Rest area / scenic overlook:** a place to stop and look at a planet.
  Could tie into sleep/time (M6).
- **Construction zone:** cones and a flagger bot slowing traffic to one lane.
- **Broken-down trucker:** an optional favor (tow, fuel), with a thank-you
  later. Cozy side quest.
- **Hitchhiker beacon:** a stranded someone with a story; a free ride is
  its own little scene.
- **Yard sale in space:** a junk dealer drifting with a sign.
- **Lost cargo pods** to pick up and return for a reward.
- **Message buoys / old signals:** lore about the husband (M8).
- **Gravity well with a slingshot** (already in the brief for M5).
- **Wedding barge, parade float, funeral procession:** slow ships with
  streamers to pass respectfully.
- **Seasonal migrations:** jellyfish that only come through on some days.
