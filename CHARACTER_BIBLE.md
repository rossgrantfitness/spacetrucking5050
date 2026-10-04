# Space Truckin' 5050 — Character Design Bible

> Repo copy for Claude Code. The editable original lives in the developer's Claude Doc; if the two disagree, ask the developer which is current. The original sketch is `reference/bunny_sketch.jpg`.

## How to use this bible

Every character in Space Truckin' 5050 is a chunky, cheerful Mega Man Legends-style toy with a PS1 polygon budget and a painted face that swaps expressions. This bible is the single reference for how characters look, are built, and act.

**Why Mega Man Legends.** It is the clearest proof that PS1-era characters can be warm, funny and readable instead of creepy. We borrow five things from it:

1. **Toy-like shapes.** Rounded, chunky forms that look like they could be picked up and squeezed.
2. **Big heads, big boots, big hands.** The extremities carry the silhouette; the torso stays small and simple.
3. **Clean color blocks.** Flat, bright colors with very little texture noise, so characters read at 480×270.
4. **Painted faces that swap.** Expressions live in a small texture sheet, not in geometry.
5. **Blue-collar charm.** Diggers, mechanics and pilots in practical workwear, operating big machines.

**What we add.** A dry, tired adult lead; a surreal space setting; and a slightly faded palette so the cheerfulness feels lived-in rather than sugary.

## Global style rules

| Rule | Standard |
| --- | --- |
| Proportions | 2.5 to 3 heads tall. Head is about one third of total height (ears not counted). |
| Shapes | Rounded prisms and capsules with 6 to 10 sides. No sharp, spiky or skinny forms except ears, tails and teeth. |
| Extremities | Oversized head, mitten hands and boots. Small torso, short limbs. |
| Silhouette | Each character has one hook readable in solid black: ears, a hat, a jaw, a tail. |
| Color | 3 to 5 flat color blocks per character, plus fur. Detail comes from color breaks, not texture noise. |
| Texture detail | Only where it tells a story: a patch, a stain, stitching, a logo. Everything else is flat or a soft gradient. |
| Faces | Painted on a texture sheet and swapped per expression. Never sculpted mouths or eyelids. |
| Lighting | Baked into vertex colors or the texture: soft shade under the head, ears and jacket hem. |
| Mood | Friendly and toy-like. Teeth, claws and monsters stay goofy, never scary. |

**The squint test.** Shrink a screenshot to 160 pixels wide. If you can still tell who the character is and what mood they are in, the design works.

## The protagonist

**[BUNNY_NAME]** is a 35-year-old lop-eared bunny space trucker: indifferent, stoned, burnt out, an old salt who is tired of all of it. She inherited the rig from her late husband, and it is her only way to make a living. She stays steady through the game; the world changes around her.

Sketch: `reference/bunny_sketch.jpg` (bunny on the right page; NPC concepts on the left).

### What the sketch locks in

- **Rock N Roll trucker cap** sitting high on a big round head.
- **Long lop ears** hanging down past the shoulders from under the cap, framing the face.
- **Furrowed, angled brows** and a cigarette dangling from the mouth: attitude, not cuteness.
- **Buck teeth**, a small triangle nose, whisker marks and fluffy cheek tufts.
- **Open utility vest** with big chest pockets and a zipper edge, over a soft round belly.
- **Mitten hands**, one holding a can.
- **Skinny legs into huge, heavy work boots.** Mega Man Legends proportions exactly.

### Proportions

| Measure | Target |
| --- | --- |
| Total height (cap top to sole) | 2.6 heads |
| Head (with cap) | About 1/3 of height |
| Ears | Hang to mid-chest; tips swing freely |
| Torso (neck to hips) | 0.7 heads, pear-shaped with a small belly |
| Legs | 0.6 heads, thin |
| Boots | 0.35 heads tall, about 0.6 heads long; the widest point of the lower body |
| Hands | Mittens about half the width of the face |

### Silhouette hook

Cap brim plus hanging lop ears plus giant boots. In solid black she reads as a mushroom-capped figure with two drooping ribbons and clown-sized feet. No other character may share this combination.

## Face sheet

Her default face is half-lidded, brows low, cigarette drooping: unimpressed, not angry. Every expression is a painted cell on the face texture, swapped at runtime the way Mega Man Legends swaps its faces.

### Face parts

- **Eyes:** large ovals with a single white highlight. A flat upper lid cuts across them for half-lidded looks.
- **Brows:** thick dashes angled down toward the nose. The angle carries most of the mood.
- **Mouth:** small and off-center around the cigarette, with the two buck teeth always visible.
- **Fixed marks:** triangle nose, three whisker dots per cheek, cheek-fluff tufts on the head geometry.

### Expression cells

Eyes and mouth are separate cells so they combine freely (for example, Squint eyes with Talk mouth).

| Cell | Eyes | Mouth | Used for |
| --- | --- | --- | --- |
| Default "whatever" | Half-lidded, brows low | Flat, cig drooping | Most of the game |
| Blink | Closed lines | — | Every 3 to 6 seconds, random |
| Talk A / B / C | — | Closed, half open, open | Mouth flaps synced to gibberish blips |
| Squint | Narrow slits, brows down hard | Flat | Annoyance, bright light, bad news |
| Smirk | Half-lidded | One corner up | Payday, a good joke |
| Sleepy | Nearly shut | Small yawn | Morning, long hauls |
| Wide | Full ovals, brows up | Small "o", cig tilts | Rare: something truly weird drifts past |
| Soft | Relaxed, brows level | Faint smile | Rare story moments about her husband |

The rare cells are worth more because they are rare. Never use Wide or Soft as a default.

### Ear acting

The lop ears are her second face. Each ear is two segments that swing from the base.

- **Default:** hanging straight, slight sway with movement.
- **Annoyed:** pulled back and flat against the head.
- **Surprised:** both lift a little at the base, tips still hanging.
- **Sigh:** one ear slumps lower than the other.
- **Flight turbulence and bonks:** tips flop and settle with a little overshoot.

## Outfit and customization

She has four swappable slots: hat, jacket, boots and accessory. The sketch's outfit is the default, and each slot swaps one rigid part of the model.

| Slot | Default (from sketch) | Attaches to | Unlockable ideas |
| --- | --- | --- | --- |
| Hat | Rock N Roll trucker cap, mesh back, high crown | Head | Beanie, aviator headset, bucket hat, welding cap, bare head |
| Jacket | Open utility vest, two big chest pockets, zip edge | Torso (also swaps upper-arm sleeves) | Puffy bomber, mechanic jumpsuit top, hoodie, husband's old flight jacket |
| Boots | Huge work boots, thick soles, wide toes | Shins | Moon boots, hi-top sneakers, magnetic dock boots, slippers |
| Accessory | Cigarette in mouth, soda can in hand | Mouth socket and right-hand socket | Wheat stalk, lollipop, neon soda can, lighter, thermos, toothpick |

### Rules for every outfit piece

- Keeps the Mega Man Legends look: chunky shapes, flat color blocks, one story detail (patch, stain, stitching).
- Fits within the slot's triangle and texture budget (see Technical build spec).
- Never hides the face. Hats sit above the brows.
- Jackets keep a thick collar that hides the head-to-body seam.
- Boots stay oversized. Boots are part of her silhouette hook.
- Real brands and logos are not allowed. Invented brands are encouraged.

### Ears and hats

Because her ears are lop ears that hang from under the hat, every hat works with the same ear pieces. No ear holes or alternate ear meshes are needed. A hat only needs a slight notch at the sides so the ear bases don't clip.

### Two sockets for accessories

The mouth socket holds things she chews or smokes. The hand socket holds things she carries. One accessory may use both (a lighter in hand while a cigarette is in the mouth).

## Color palette

She wears warm, slightly faded colors so she pops against the cool, neon-lit hub and black space. These are proposed defaults; the final colors are an open decision.

| Part | Color | Hex |
| --- | --- | --- |
| Fur | Warm cream | #F2E6D0 |
| Cheek fluff, muzzle | Light cream | #FBF4E6 |
| Inner ears, nose | Dusty pink | #E3A6A1 |
| Eyes | Deep teal, white highlight | #1F5E6B |
| Cap front | Faded red | #C2463A |
| Cap mesh back | Sand | #E8DCC0 |
| Cap lettering, vest trim | Hazard yellow (matches the cockpit struts) | #F2C230 |
| Vest | Faded navy | #2E4A6E |
| Boots | Burnt orange-brown | #A0552E |
| Soles | Charcoal | #2B2B30 |
| Cigarette ember | Hot orange | #FF7A2E |
| Soda can | Neon green | #7CFF4F |

**Faded, not dull.** Start from a clean Mega Man Legends primary, then pull it about 15% toward gray and warm it slightly. She should look like her clothes have been through a hundred hauls.

## Animation and acting

She moves like someone who has done this ten thousand times and is not in a hurry. The hub uses fixed camera angles, so poses must read from a distance: exaggerate slouch, ear swing and boot weight.

### On foot (hub)

| Animation | Notes |
| --- | --- |
| Idle | Slouched, weight on one hip, slow breathing. Every 8 to 15 seconds a fidget: tap ash, scratch an ear, sip the soda, shift weight. |
| Long idle | After 30 seconds: big yawn and stretch, or she sits on the nearest crate. |
| Walk | Slow shuffle. Boots land heavy with a small dip. Ears sway a beat behind. |
| Jog | Rare and reluctant: short strides, ears flapping, cig bouncing. |
| Interact | Lean in, short reach with a mitten, lean back. |
| Talk | Faces the speaker, mouth flaps, one small hand gesture per line at most. |
| Payday | Tiny fist pump at hip height, then Smirk. Never a big celebration. |

### Cockpit

| Animation | Notes |
| --- | --- |
| Cruising | Sunk into the seat, one mitten on the throttle, elbow on the armrest. |
| Steering | Leans gently into turns; ears swing with the ship. |
| Radio | Reaches over and turns the dial; nods slightly if the song is good. |
| Bonk | Jolt forward, ears flop, cig nearly falls, Squint. |
| Boost | Pressed back into the seat, ears trail backward. |
| Long haul | Sleepy face, chin on mitten, then shakes it off. |

### Comm portrait

A head-and-shoulders portrait in a small framed window, like a Star Fox 64 comm. It uses the real 3D head with the face sheet, so mouth flaps sync to the gibberish blips. A short burst of radio static plays before and after each line. Every speaking NPC gets the same treatment.

## Supporting cast

The base holds about 250 animals, but players meet only 5 to 10 of them, plus 5 to 8 clients across the solar systems. Each one gets a different species, one silhouette hook, one prop and one personality note.

### Rules for every NPC

- Same global style rules and face-sheet system as the lead, with fewer cells (Default, Blink, Talk A/B/C and one signature expression).
- Same segmented skeleton as the lead, scaled and reshaped, so animations can be shared.
- No two NPCs share a silhouette hook with each other or with the lead.
- Each has their own gibberish voice pitch.
- Personality shows in one idle fidget (polishing glasses, tapping a pen, counting cash).

### Concepts from the sketch

| Concept | What the sketch shows | Proposed role | Silhouette hook |
| --- | --- | --- | --- |
| Crocodile | Huge toothy grin, collared shirt and tie, bulging eyes on top of the snout | A slick client, or the company boss you eventually buy out | Long jaw full of square teeth, tie |
| Pig | Scowling brows, stubble, round snout, leaning on a counter with a stack of paperwork | Grumpy dispatch clerk on one shift | Big round snout over a counter, folded arms |
| Cat | Skinny, upright, striped shirt, long curling tail, pointed ears | Hallway neighbor who is always just standing there | Thin vertical body, tall ears, curling tail |

The roles are suggestions; the developer decides.

### Still to design

- Two more dispatch shift workers (morning, evening and night need three, including the pig).
- Hangar mechanic.
- One client per solar system, each matching that system's color (for example, a magenta casino owner, a sleepy teal-system fisherman).
- Traffic-control voice and other truckers for comm chatter (portrait only, no full body needed).

## Technical build spec

Characters are built from separate rigid parts that pivot at the joints, PS1-style, so there is no rigging or weight painting. Each part is its own mesh in a Godot node tree and is animated by rotating it.

### Part list (lead, default outfit)

| Part | Parent | Shape | Triangles |
| --- | --- | --- | --- |
| Hips (root) | — | Rounded box | 40 |
| Torso + vest | Hips | Pear-shaped capsule, thick collar | 120 |
| Head | Torso | 10-sided rounded prism, muzzle wedge, cheek tufts, buck teeth | 180 |
| Hat | Head | Trucker cap, brim, mesh back | 100 |
| Ears (upper and lower, ×2) | Head, then upper ear | Flat 2-quad strips, slightly curved | 48 total |
| Upper arms (×2) | Torso | 6-sided tube | 48 total |
| Forearms (×2) | Upper arms | 6-sided tube | 48 total |
| Mittens (×2) | Forearms | Mitten with separate thumb | 80 total |
| Thighs and shins (×4) | Hips, then thighs | Thin 6-sided tubes | 80 total |
| Boots (×2) | Shins | Oversized rounded wedge, thick sole | 160 total |
| Tail | Hips | Small puff | 20 |
| Accessories | Mouth and hand sockets | Cigarette, can | 30 |
| **Total** | | | **about 950** |

### Budgets

| Character type | Triangles | Texture | Face sheet |
| --- | --- | --- | --- |
| Lead (bunny) | 800–1,200 | 256×256 atlas | 128×128, 4×4 grid of 32×32 cells |
| Named NPC | 400–800 | 128×128 atlas | 64×64, 2×4 grid |
| Portrait-only voice | 300 (head and shoulders) | 128×128 | 64×64 |
| Background crowd | 200–400 | 64×64 | Painted, no swaps |

### Texture and shading rules

- Nearest-neighbor filtering, no mipmap blur.
- Flat color blocks; small gradients only for shading.
- Bake soft shade under the head, ears, collar and boot tops into vertex colors.
- Every character uses the project PSX surface shader (vertex snap, affine warp) from `CLAUDE.md`.

### Godot setup

- Scene `Bunny.tscn`: a Node3D tree matching the part list, each pivot placed at the joint, each part a MeshInstance3D.
- Animations in an AnimationPlayer, keyframing part rotations. No Skeleton3D needed for the first version.
- Ears and tail get a small spring script for follow-through, so they swing on their own.
- Face: eyes and mouth are separate face quads whose shader picks a cell from the face sheet by index.
- Customization: each slot is a node whose mesh and texture come from an outfit data resource. Sockets are Marker3D nodes (`mouth_socket`, `hand_socket_r`).
- Scale: 1 unit = 1 meter. Proposed height 1.2 m including cap.

### Build path

1. **Placeholder:** Claude Code builds her from Godot primitives, matching the proportions table and part names.
2. **Real model:** the developer (or a hired artist) models each part in Blender and replaces the placeholders one at a time, keeping the same names and pivot positions.
3. **Polish:** paint the final atlas and face sheet, then bake vertex shading.

## References and checklist

| Reference | Take from it |
| --- | --- |
| Mega Man Legends (PS1) | Primary style: toy-like shapes, big boots and heads, clean color blocks, texture-swapped faces, blue-collar charm |
| Tail Concerto (PS1) | Animal characters operating big machines in practical work gear |
| Star Fox 64 (N64) | Animal pilots in cockpits; comm portraits with mouth flaps; headsets around long ears |
| Animal Crossing (N64, GameCube) | Simple muzzles, flat ear shapes, bold readable color blocking, gibberish voices |
| Easy Delivery Co. | Lived-in blue-collar posture and the lo-fi working-life mood |
| Final Fantasy VIII | Characters staged in fixed camera shots; the ship as a lived-in place |

### Do

- Read clearly at 160 pixels wide (the squint test)
- Big head, big mittens, big boots, small torso
- Flat color blocks with one story detail per piece
- Default face is tired, not cute
- Ears and tail move on their own
- Stay inside the triangle and texture budget

### Don't

- Sculpted facial features in the geometry
- Skinny, spiky or realistic anatomy
- Noisy photo textures
- A bubbly, sexualized or wide-eyed default look
- Real brands or logos
- Scary monsters or NPCs

## Open decisions

Until these are settled, use the defaults shown and keep every value in data so it can change in one place.

| Decision | Default until decided |
| --- | --- |
| Protagonist name | [BUNNY_NAME] |
| Final color palette | The proposed palette above |
| Height in meters | 1.2 m including cap |
| Roles for the crocodile, pig and cat | As proposed in Supporting cast |
| Remaining dispatch shift workers, mechanic, clients | Not designed yet |
| Husband's look (photos, flashbacks, his old jacket) | Not designed yet |
| Who makes the final models | The developer in Blender, or a hired artist |
