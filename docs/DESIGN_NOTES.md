# Design notes: your 25 answers (round 10)

After round 9 I asked you 25 questions about feel, fun and progression.
This is what you said, what I think it means for the game, and the order
I'd build it in. When something here and `CLAUDE.md` disagree, **your
answers win** (they're newer), and the change is logged in `DECISIONS.md`.

## The big picture in five lines

1. **A background game.** Long hauls are the job. It's something you play
   at night, stoned, for a couple of atmospheric deliveries, or at work on
   autopilot while you crank out emails.
2. **Feel poor at the start.** Everything costs money (real 2026 trucking
   costs × 20,000). You can lose money on a job, and you could actually run
   low on fuel if you mess around.
3. **Numbers going up, RPG-style.** A payout screen with stars, XP bars and
   a 5-star trucker rating. The rig levels up its steering, handling,
   acceleration and top speed. Jack gets skills, and clients get
   reputation.
4. **The world opens up.** New systems and stations unlock through
   reputation and story. Buying the company is the finish line (for now).
5. **Never a chore.** No timers that fail you, no daily logins, no losing
   progress, nothing tedious. The story is optional and the choices carry
   no consequences.

## Your answers, and what they mean

| # | Topic | You said | What it means for the game |
|---|---|---|---|
| 1 | Delivery length | Long hauls are the job; playtest to find the balance; cozy, play-in-the-background. | Hauls stay long (the 18-minute Tidewater run is the model). Autopilot plus the cabin make "background" work. Length stays a tuning number. |
| 2 | What a delivery asks | "All of them, but choosing a time window." | Every job can ask for care, speed and fuel thrift. **Delivery windows**: you pick a window (e.g. "by the evening shift" or "whenever") that sets the pay. Late never fails; it just pays the base. No countdowns on screen. |
| 3 | Cargo changes flying | Yes to all. | Cargo **traits** in data: livestock (boost spooks them), ice cream (melts over time and in sunlight, so a slow drive costs), explosives (bonks hurt more), heavy (sluggish turns and acceleration). The traits stack with the rig's numbers. |
| 4 | Picking jobs | Job board for repeatable jobs, in person for story jobs. | That's the setup now. Keep it: boards are generated from client data, and story jobs come from people. |
| 5 | Good-run feel | Rating payout screen: XP, filling meters, stars, points, stretch goals, 5-star trucker rating, speed rating. | **New payout screen**: stars for care, speed and fuel; meters filling (rig XP, Jack's skills, client rep); a stretch-goal checklist per job; your running trucker rating out of 5. Sounds and juice. |
| 6 | Money tightness | Feel poor; you could actually run out of fuel. | Start broke. Fuel is a real cost. An empty tank doesn't end the game: ~~the rig crawls on fumes toward the nearest pump, or~~ a Gas-N-Go roadside tanker comes out to you and it costs money. (2026-10-07, your note: an empty tank now kills the engines; crawling on fumes is gone.) It hurts, but you never lose progress. |
| 7 | Rent | Everything costs money; real 2026 trucking costs × 20,000. | **Economy rebalance**: prices and pay based on real per-mile trucking costs (fuel, insurance, maintenance, truck payments, parking), multiplied by 20,000. Credits get big numbers. Rent is weekly. |
| 8 | Prices change | Peg fuel to today's real oil price, checked when the game loads. | Possible. It needs the internet and a free price source. Plan: check once at load, move fuel prices by how far oil is from a baseline (capped, e.g. ±30%), and fall back to the baseline offline. A setting turns it off. **I'll confirm the details with you before building it** (it sends a web request). |
| 9 | Losing money | Sure. | A careless run can cost more in fuel and repairs than it pays. The payout screen shows the honest profit and loss. |
| 10 | Buying the company | Finish line, for now. | Buying the company is the end goal: a big moment, then the sandbox continues. |
| 11 | Leveling | Rig attributes (steering, handling, acceleration, top speed); Jack's skills; client reputation. All three. | **Rig XP** with four attributes you raise. **Jack's skills** (e.g. smooth hands, haggling, fuel sense, napping). **Reputation** per client, which unlocks their story jobs, better pay and new places. |
| 12 | Upgrades: numbers or abilities | Not sure yet. | Keep both for now: parts nudge numbers, and a few special parts add abilities (docking computer, auto-refuel, a cargo stabilizer). Decide later from playtests. |
| 13 | Rigs | One favorite rig you upgrade forever, chosen from several. | You can own many rigs but mark one as your **favorite**. Deep upgrades go on the favorite. More rigs can be added any time as data files. |
| 14 | The husband's rig special | "idk but good thought." | Parked. Ideas for later: a voicemail in the dash, an old logbook, a quirk only it has. |
| 15 | Unlocking places | A big reward. | New systems and stations unlock through reputation and story. The course chart shows locked places as "???". |
| 16 | Story | You can clear the game without paying attention to the story. | The story is fully **optional**. No story beat gates the money, rigs or the company. |
| 17 | Conversations | Room for character portraits. | **Visual-novel-style talk** on foot: a big portrait of who's talking (later the real 3D head), the text box below. |
| 18 | Choices | Consequence-free. | Replies are flavor (as now). Nothing locks you out. |
| 19 | Relationships | No romance; it's just space trucking. | No romance. Friendships show through reputation and what people say. |
| 20 | Jack | One-liners. | Jack talks in dry one-liners, never speeches. |
| 21 | Typical session | Night at home: atmosphere, a couple of deliveries, stoned. Day at work: autopilot and emails. | Autopilot has to be trustworthy for long stretches. The game needs to be fine minimized or in a small window, with sound cues for "you've arrived" and "someone's calling". It should never punish you for looking away. |
| 22 | Time | A weird fantasy in-world clock based on animals. | An **animal clock**: the day has named "hours" (e.g. Hour of the Owl, Hour of the Rooster) and the shifts follow it. The clock keeps moving with real play, gently. Exact names are your creative call (I'll draft some). |
| 23 | Off-driving activities | A mini game. And the hallway, the raccoon's dispatch desk and the apartment are all inside the ship. | **The hub moves into the rig**: apartment, hallway and Dottie's dispatch desk are rooms in a big ship (a "mothership" the rig docks with, or a much bigger rig). Plus a mini game (ideas: cargo loading/Tetris, an arcade cabinet, fishing at Tidewater, cards with Moe). |
| 24 | One-more-run hook | "Not that kind of game." | No streaks, cliffhangers or compulsion loops. Sessions end when you feel like it. |
| 25 | Never make you do | Timers, daily logins, losing progress, tedium. | These are hard rules (on top of `CLAUDE.md` §10). |

## Tensions I'll handle (and how)

- **"Time windows" vs "no timers".** Windows are something you *choose*
  for more pay. Missing one pays the base rate. There's never a countdown
  on screen, just a clock time on the job card and on the HUD.
- **"Feel poor / run out of fuel" vs "cozy, never punishing".** Running dry
  costs time and money (crawling on fumes, or a tow), never progress or the
  game. Early jobs are tuned so a careful driver always comes out ahead.
- **"Hub inside the ship" vs what's built.** Today the base is a station
  and the apartment is the rig's cabin. The next step is deciding *which*
  ship holds the hallway and the dispatch desk. My pick: the rig docks with
  a big "home ship", the [BASE_NAME], which flies between systems. That
  matches your answer and keeps the rig cozy. Your call.
- **The live oil price** needs an internet check at load. I'll make it
  optional and safe (offline fallback, capped swings, no personal data
  sent) and ask before turning it on.

## Proposed order (rounds 10 and on)

1. **Round 10 (this one):** pixel font everywhere, controls in the Esc
   menu, these notes, and your 250 route events converted to data with the
   event director rules.
2. **Economy rebalance** (×20,000 real costs), losing money, fuel that
   matters, crawling on fumes, the honest profit and loss.
3. **The payout screen**: stars, ratings, XP meters, stretch goals, the
   5-star trucker rating.
4. **Cargo traits** (livestock, ice cream, explosives, heavy) and
   **delivery windows**.
5. **Leveling**: rig attributes, Jack's skills, client reputation, and
   unlocking places.
6. **The animal clock** and shifts. The hub moves into the ship.
7. **Visual-novel conversations** with portraits; a mini game.
8. The rest of the brief's milestones (outfits, more clients and systems,
   the story, buying the company).
