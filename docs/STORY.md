# White's story

How the story of Jacki's late husband, White, is told, and where each piece
lives so you can change it. Everything here is **optional**. Nothing gates
money, rigs or the company, and no choice changes anything (your answers
16 and 18). Every line is a draft: rewrite freely.

## What happened (never said outright)

- White drove the Thumper for about twelve years.
- He was kind and dry. He brought Raccoony donuts, wired the dash himself
  ("don't touch the blue wire"), lost at cards to Sal and paid for the next
  trucker's fuel at Lily's.
- He sat with Gill past the whale buoy with the engine off, and made
  mixtapes for the long hauls.
- On his last run to Tidewater, with a storm on the lane, OrbitalEx wanted
  the cargo by morning. Going around would have added a day. He didn't go
  around. The company docked his pay for being late.

The player works it out from his last log, his message and the boss's
"Policy." Nobody says "he died in a storm." Quiet, never melodramatic.

## The beats

| # | What | Where | Needs | Sets |
|---|---|---|---|---|
| — | His old logs come back, about one per delivery | Cabin PC, OLD LOGS (`data/pc/trip_logs.tres`) | deliveries 1, 2, 3... | (read flags) |
| — | Crew remember him (Raccoony's donuts, Chang Ma's wiring...) | Aboard (`tools/crew_data/make_crew.py`) | friendship / flags below | |
| 1 | Marge recognizes the rig's cough | Truck stop, Marge | 2 deliveries | `marge_mentioned_white` |
| — | Big Wendell mistakes her for him on the scope | Comms (`data/dialogue/story_calls.tres`) | 3 deliveries | |
| — | Lily: "your next fill-up's on him" (one free fill) | Truck stop, Lily | `marge_mentioned_white` | `whites_tab` |
| 2 | Marge: his standing order, a cherry pie a month for Gill | Truck stop, Marge, job `white_pie` | 4 deliveries | |
| 3 | Gill: "We used to sit out past the whale buoy." | Tidewater, Gill | `white_pie_done` | `gill_talked_white` |
| 4 | Dusty finds a message chip taped behind the dash | Truck stop, Dusty | 6 deliveries, `gill_talked_white` | `white_chip` |
| 5 | His message plays on the comms in flight | Comms (story call) | `white_chip` | `white_voicemail` |
| — | His last log comes back: "Not going around." | Cabin PC | `white_voicemail` | |
| — | Raccoony calls next trip: "I wasn't gonna sell it." | Comms | `white_voicemail` | |
| 6 | The boss: his last load, still in impound. "Policy." | OrbitalEx office, job `white_last_load` | `white_voicemail` | |
| 7 | Gill opens the crate: his tapes, "FOR THE LONG HAULS" | Tidewater, Gill | `white_last_load_done` | `white_story_done` |
| 8 | His tapes are a radio station: **WHITE NOISE 43.8** | Radio (`data/radio/white_noise.tres`) | `white_story_done` | |
| — | After: the first tape plays; Wendell, Marge, the crew, two emails | Comms, people, PC mail | `white_story_done` | |

Two quiet echoes in the far systems (beta step 4), never pushed:
- **Penny** (the Frostline creamery), after her story and his message:
  years ago one trucker climbed all the way up, in a big lazy rig that
  started like a cough. He bought a plain cone and played a tape by the
  window. "Plain's on the house. Always." (`data/npcs/frostline_penny.tres`)
- **Mags** (the Dustbowl salvage yard), after her story and his tapes:
  "Dust takes everything else. Hang on to the stuff it can't." And in
  Penny's parlor, a booth with a tiny "W" carved in the table.

People with a new story line show a "!" over them (`marked` in the
conversation data), so the beats are easy to find. The objective line never
pushes the story.

## Testing a beat

Press **F10 → STORY: SKIP TO...** and pick a beat. It sets up everything
before that beat, so you can test one moment without 14 deliveries.

## Where things live

- **Story calls** (one-time comm calls, including his message):
  `data/dialogue/story_calls.tres` (blueprint `StoryCall.gd`).
- **His logs:** `data/pc/trip_logs.tres` (blueprint `TripLog.gd`).
- **His portrait and voice:** `data/npcs/white_message.tres` and `white_tape.tres`.
- **The people's lines:** `data/npcs/truckstop_control.tres` (Marge),
  `tidewater_gill.tres`, `truckstop_pumps.tres` (Lily),
  `truckstop_mechanic.tres` (Dusty), `company_boss.tres`.
- **The jobs:** `data/jobs/white_pie.tres`, `white_last_load.tres`.
- **The emails:** `data/pc/emails.tres` (`white_order`, `orbitalex_claims`).
- **His station:** `data/radio/white_noise.tres`. Drop real tracks in
  `audio/radio/white_noise/music/`; until then it's a placeholder loop with
  his voice between songs.
