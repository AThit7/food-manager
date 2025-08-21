# Food Manager

Eating planner app.

Stuff that might require explaining:
* `/lib/data/database/schema` -> db schema, that way its harder to make typos in repositories
* `/lib/data/services/database` -> DatabaseServiceSqflite is just a wrapper for plugin function,
it's mostly unnecessary but theoretically we can now easily replace it with a different implementation
of DatabaseService
* `/domain/model/product/local_product` vs `/domain/model/pantry_item` -> LocalProduct represents 
abstract product, Like spaghetti pasta of a specific brand. PantryItem is an instance of product,
either bought or in plans to buy.
