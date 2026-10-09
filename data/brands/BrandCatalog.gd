class_name BrandCatalog
extends Resource
## Every brand and every snack in the galaxy (see BrandData.gd and
## ProductData.gd). Written by tools/brand_data/make_brands.py.


@export var brands: Array[BrandData] = []
@export var products: Array[ProductData] = []


func find_brand(id: String) -> BrandData:
	for brand in brands:
		if brand != null and brand.id == id:
			return brand
	return null


func find_product(id: String) -> ProductData:
	for product in products:
		if product != null and product.id == id:
			return product
	return null


## What a vending machine at `place_id` sells: the galaxy-wide brands, plus
## anything local to that place.
func stocked_at(place_id: String) -> Array[ProductData]:
	var found: Array[ProductData] = []
	for product in products:
		if product != null and (product.sold_at.is_empty() or place_id in product.sold_at):
			found.append(product)
	return found
