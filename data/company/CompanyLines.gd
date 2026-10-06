class_name CompanyLines
extends Resource
## Everything said about (and by) the company in its office and on its
## checks, in res://data/company/company.tres. Edit the words there.
## Lines can use {bunny}, {boss}, {company} and {currency} (see WorldNames).


## The fees on every check, adding up to the company's cut. Each is
## "Label|share" (shares are parts of the cut, any numbers: they're scaled
## to add up).
@export var fee_items: PackedStringArray = PackedStringArray()
## Jacki, reading her very first check.
@export var first_check_reaction: PackedStringArray = PackedStringArray()
## The boss, after that first check (he sends her to Marge).
@export var first_check_boss: PackedStringArray = PackedStringArray()
## Jacki, buying the company.
@export var buyout_jacki: PackedStringArray = PackedStringArray()
## The boss, when she buys the company out from under him.
@export var buyout_boss: PackedStringArray = PackedStringArray()
## The line under the price, before you can afford it (one picked at random).
@export var not_yet: PackedStringArray = PackedStringArray()

@export_group("New orders")
## The card when someone says they'll call the company (their problem
## became an order). Can also use {client}, {cargo} and {to}.
@export_multiline var order_placed: String = ""
## The boss, handing you a new order at check-in. Can also use {client},
## {cargo} and {to}.
@export var order_lines: PackedStringArray = PackedStringArray()
## The same, once you own the company (he works for you now).
@export var owner_order_lines: PackedStringArray = PackedStringArray()
## The boss, when there are more orders still waiting. {count} is how many.
@export var more_orders: PackedStringArray = PackedStringArray()
