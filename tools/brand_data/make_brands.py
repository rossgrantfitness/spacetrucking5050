#!/usr/bin/env python3
"""Writes res://data/brands/brands.tres from the plain lists below: every
brand in the galaxy and every snack and drink in its vending machines.
Edit the lists and re-run:

    python3 tools/brand_data/make_brands.py

The same brands turn up on the radio's ads and on billboards, so keep the
names and slogans the same everywhere. All made up: no real brands.

Effects: "none" (just the taste), "steady" (steady hands for the next trip),
"zoom" (tops up the boost tank by a quarter).
Packages: can, bottle, cup, bar, bag, box, stick.
sold_at: [] = every machine in the galaxy; or place ids (truck_stop,
tidewater, high_roller, base = your rig's own machine).
"""
import os

ROOT = os.path.join(os.path.dirname(__file__), "..", "..")
OUT = os.path.join(ROOT, "data", "brands", "brands.tres")

# (id, name on the packet, slogan, story, color r g b)
BRANDS = [
    ("moon_milk", "MOON MILK", "Now with 30% less gravity.",
     "Bottled on the dairy moons of Home Space, where the cows graze in low gravity and the milk floats up out of the pail if you're not quick. Every trucker's had a Moon Milk at three in the morning. Most of them have had it on the ceiling.",
     (0.92, 0.94, 1.0)),
    ("neon", "NEON SODA WORKS", "Tastes like a sunset. Glows a bit.",
     "Started in a casino basement in the Glimmer System by a bartender who spilled something into the jukebox. The glow is natural. Mostly. The cans are collectible, if you're the kind of person who keeps cans.",
     (1.0, 0.35, 0.75)),
    ("zoom", "ZOOM JUICE", "Now with 40% more zoom.",
     "An energy drink first brewed on a racing asteroid by a pit crew who never slept. Haulers swear by it. Dentists swear at it. Nobody knows what the first 100% of zoom was.",
     (1.0, 0.85, 0.1)),
    ("old_orbit", "OLD ORBIT SPACE JERKY", "Mysteriously chewy since forever.",
     "Nobody knows what animal it's from. The packet just says 'space'. The founder took the recipe to his grave and then, they say, came back for a bag.",
     (0.7, 0.35, 0.2)),
    ("galaxy_gumballs", "GALAXY GUMBALLS", "Collect all 9000.",
     "Every gumball has a tiny planet printed on it, and there are 9,000 planets. Nobody has ever collected them all. Somebody in the Glimmer System has 8,999 and won't talk about it.",
     (0.4, 0.6, 1.0)),
    ("mochi_moons", "MOCHI MOONS", "The snack that orbits your mouth.",
     "Soft rice-cake moons from a little family bakery that came loose from its station in a solar storm and just kept baking. Matcha is the classic. Sakura is for special occasions, like Tuesday.",
     (0.6, 0.85, 0.5)),
    ("star_stop", "STAR-STOP RAMEN", "Hot noodles at every ring on the road.",
     "The cup noodles of the spaceways: add hot water, wait three minutes, burn your tongue anyway. Every cab in the galaxy smells a little of it. There's a Star-Stop in every machine, and nobody remembers putting them there.",
     (0.95, 0.3, 0.2)),
    ("cozy_coil", "COZY COIL COCOA", "Drop one in space. It just floats there. Cozy.",
     "Hot cocoa cubes from the people who sponsor the late-night lo-fi on Cozy Coil radio. Drop one in hot water, or just let it float around the cab and smell it.",
     (0.55, 0.35, 0.25)),
    ("dr_sprinkle", "DR. SPRINKLE'S", "Hull putty. It's also a snack.",
     "Dr. Sprinkle invented a hull putty so good it patched a moon. Then he noticed it tasted like birthday cake. The company sells both, out of the same tub. Please read the label.",
     (1.0, 0.75, 0.9)),
    ("tidewater_cannery", "TIDEWATER CANNERY", "We can, therefore we are.",
     "The cannery in the teal Tidewater system. Gill's family has canned whatever the tide brings in for nine generations. Some of it is fish.",
     (0.2, 0.8, 0.8)),
    ("marges", "MARGE'S", "Pie's on. Coffee's on. She's on.",
     "Marge's diner at the truck stop, home of the Nebula Pie. Marge puts slices in the vending machine at night so nobody goes hungry while she sleeps. She knows if you take two.",
     (1.0, 0.75, 0.3)),
    ("high_roller", "THE HIGH ROLLER", "The house always wins. The snacks always lose.",
     "Sal Grinwell's casino in the Glimmer System sells its own snacks, shaped like the things you're losing. Sal says that's called branding.",
     (0.8, 0.3, 1.0)),
]

# (id, name, brand, kind, price, blurb, effect, package, sold_at, [taste lines])
PRODUCTS = [
    ("moon_milk", "Moon Milk", "moon_milk", "drink", 4, "The original. Shake it before it floats off.", "steady", "bottle", [],
     ["Cold. Floaty. Tastes like being a kid on a slow ship.", "*glug* ...I have a milk mustache, don't I."]),
    ("moon_milk_strawberry", "Moon Milk: Strawberry Phase", "moon_milk", "drink", 5, "Pink. For the inner child. And the outer one.", "none", "bottle", [],
     ["Pink milk. I'm thirty-five. Don't look at me.", "Strawberry Phase. I've been in one since forever."]),
    ("moon_milk_capsules", "Moon Milk Warm Capsules", "moon_milk", "drink", 6, "For haulers who can't sleep. Or won't.", "steady", "cup", [],
     ["Warm milk out of a capsule. Like a hug from a vending machine.", "Okay. Okay, that's nice."]),
    ("neon_soda", "Neon Soda", "neon", "drink", 3, "Classic pink. Glows a bit.", "none", "can", [],
     ["*clunk* ...it's lukewarm. Perfect.", "Tastes like a sunset. My tongue's glowing, isn't it."]),
    ("neon_lime_zero", "Neon Lime Zero", "neon", "drink", 3, "Zero sugar. All the glow.", "none", "can", [],
     ["Lime. Zero sugar. Zero joy. Still glowing, though."]),
    ("neon_after_dark", "Neon After Dark", "neon", "drink", 6, "Only in the Glimmer System. Purple. Very purple.", "zoom", "can", ["high_roller"],
     ["It's purple. It tastes like a casino carpet at four in the morning. ...Again."]),
    ("zoom_juice", "Zoom Juice", "zoom", "drink", 7, "40% more zoom. Tops up your boost.", "zoom", "can", [],
     ["*crack* *glug* ...my ears are ringing. In a good way.", "I can see sounds. Let's haul."]),
    ("zoom_turbo", "Zoom Juice Turbo", "zoom", "drink", 12, "For emergencies. Do not drink two.", "zoom", "can", [],
     ["Oh no. Oh, I can hear my own fur growing."]),
    ("space_jerky", "Space Jerky: Original", "old_orbit", "food", 6, "Mysteriously chewy since forever.", "steady", "bag", [],
     ["Still chewing. ...Still chewing.", "What animal is this. ...No. Don't tell me."]),
    ("space_jerky_teriyaki", "Space Jerky: Teriyaki Nebula", "old_orbit", "food", 7, "Sweet, smoky, and it lasts the whole trip.", "steady", "bag", [],
     ["Sweet and smoky. I'll be chewing this till the next system."]),
    ("galaxy_gumballs", "Galaxy Gumballs", "galaxy_gumballs", "food", 2, "One gumball, one tiny planet. Collect all 9000.", "none", "box", [],
     ["Got... planet number 4,112. Again.", "A gumball with a little planet on it. I'll name it after me."]),
    ("mochi_matcha", "Mochi Moons: Matcha", "mochi_moons", "food", 5, "Soft, green, round. The classic.", "steady", "box", [],
     ["Soft. Green. It does kind of orbit your mouth. Huh."]),
    ("mochi_sakura", "Mochi Moons: Sakura", "mochi_moons", "food", 6, "Cherry blossom. For special occasions.", "steady", "box", [],
     ["Cherry blossom. It's Tuesday somewhere. Special occasion."]),
    ("star_stop_ramen", "Star-Stop Ramen", "star_stop", "food", 4, "Hot noodles at every ring on the road.", "steady", "cup", [],
     ["Three minutes. I waited two. Worth it.", "Burned my tongue. Every time. Every single time."]),
    ("star_stop_comet", "Star-Stop Spicy Comet", "star_stop", "food", 5, "Hot noodles. HOT noodles.", "steady", "cup", [],
     ["SPICY. Okay. Okay. My ears are sweating. Is that possible?"]),
    ("cozy_cocoa", "Cozy Coil Cocoa Cube", "cozy_coil", "drink", 3, "Hot cocoa from a little floating cube.", "steady", "cup", [],
     ["Hot cocoa in the middle of nowhere. Cozy, like the radio said."]),
    ("sprinkle_putty", "Dr. Sprinkle's Snack Putty", "dr_sprinkle", "food", 4, "It's also a hull putty. Read the label.", "none", "box", [],
     ["Birthday cake. And... a hint of hull. Delicious, honestly."]),
    ("canned_starfish", "Tidewater Canned Starfish", "tidewater_cannery", "food", 6, "Fresh from the tide, nine generations of know-how.", "steady", "can", ["tidewater"],
     ["It's starfish. In a can. It's... honestly not bad. Don't tell Gill I said honestly."]),
    ("kelp_crisps", "Tidewater Kelp Crisps", "tidewater_cannery", "food", 3, "Salty, crunchy, a little bit ocean.", "none", "bag", ["tidewater"],
     ["Salty, crunchy, a little bit ocean. I could eat the whole tide."]),
    ("nebula_pie", "Marge's Nebula Pie (a slice)", "marges", "food", 8, "From the diner, for the night owls.", "steady", "box", ["truck_stop", "base"],
     ["Marge's pie. Out of a machine. Still the best in the system.", "...I'm taking two. She'll know. Worth it."]),
    ("marges_coffee", "Marge's Night Coffee", "marges", "drink", 3, "Black as space. Hot as a sun.", "zoom", "cup", ["truck_stop", "base"],
     ["Black as space. Hot as a sun. Thanks, Marge."]),
    ("chip_chips", "High Roller Chip Chips", "high_roller", "food", 5, "Crisps shaped like casino chips. Not legal tender.", "none", "bag", ["high_roller"],
     ["Tried to bet one at the slots. Sal laughed for a full minute."]),
]


def gd_string(text):
    return '"' + text.replace("\\", "\\\\").replace('"', '\\"') + '"'


def packed(items):
    return "PackedStringArray(" + ", ".join(gd_string(i) for i in items) + ")"


def main():
    lines = ['[gd_resource type="Resource" script_class="BrandCatalog" format=3]', "",
             '[ext_resource type="Script" path="res://data/brands/BrandCatalog.gd" id="1_catalog"]',
             '[ext_resource type="Script" path="res://data/brands/BrandData.gd" id="2_brand"]',
             '[ext_resource type="Script" path="res://data/brands/ProductData.gd" id="3_product"]', ""]
    brand_ids = set()
    for (bid, name, slogan, story, color) in BRANDS:
        brand_ids.add(bid)
        lines += ['[sub_resource type="Resource" id="brand_%s"]' % bid, 'script = ExtResource("2_brand")',
                  "id = " + gd_string(bid), "display_name = " + gd_string(name), "slogan = " + gd_string(slogan),
                  "story = " + gd_string(story), "color = Color(%g, %g, %g, 1)" % color, ""]
    for (pid, name, brand, kind, price, blurb, effect, package, sold_at, tastes) in PRODUCTS:
        assert brand in brand_ids, "unknown brand " + brand
        lines += ['[sub_resource type="Resource" id="product_%s"]' % pid, 'script = ExtResource("3_product")',
                  "id = " + gd_string(pid), "display_name = " + gd_string(name), "brand_id = " + gd_string(brand),
                  "kind = " + gd_string(kind), "price = %d" % price, "blurb = " + gd_string(blurb),
                  "taste_lines = " + packed(tastes), "effect = " + gd_string(effect), "package = " + gd_string(package),
                  "sold_at = " + packed(sold_at), ""]
    lines += ["[resource]", 'script = ExtResource("1_catalog")',
              'brands = Array[ExtResource("2_brand")]([%s])' % ", ".join('SubResource("brand_%s")' % b[0] for b in BRANDS),
              'products = Array[ExtResource("3_product")]([%s])' % ", ".join('SubResource("product_%s")' % p[0] for p in PRODUCTS), ""]
    with open(OUT, "w") as f:
        f.write("\n".join(lines))
    print("Wrote %s: %d brands, %d products." % (OUT, len(BRANDS), len(PRODUCTS)))


if __name__ == "__main__":
    main()
