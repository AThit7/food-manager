# Food Manager

Eating planner app.

Stuff that might require explaining:
* `/lib/data/database/schema` -> db schema, that way its harder to make typos in repositories
* `/lib/data/services/database` -> DatabaseServiceSqflite is just a wrapper for plugin function,
it's mostly unnecessary but theoretically we can now easily replace it with a different implementation
of DatabaseService
* `/domain/model/product/local_product` vs `/domain/model/pantry_item` -> LocalProduct represents 
abstract product, like spaghetti pasta of a specific brand. PantryItem is an instance of such product,
either bought or in plans to be bought.
* `Product.tag.name` is a string which the app will use when trying to match products to
ingredient. If there's a recipe with ingredient name that does not match any tag, such recipe will never be used.
