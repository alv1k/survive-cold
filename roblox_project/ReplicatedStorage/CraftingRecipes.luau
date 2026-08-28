--[[
    CraftingRecipes.luau
    Таблица рецептов Верстака:
    - Крафт 'Planks' (Доски) УДАЛЕН. Доски теперь спавнятся на карте в виде ресурса!
--]]

local CraftingRecipes = {
	Torch = {
		Ingredients = { Branches = 5, Fiber = 5 },
		ResultItem = "Torch",
		ResultCount = 1
	},
	Backpack7 = {
		Ingredients = { Planks = 3, Fiber = 5 },
		ResultItem = "Backpack7",
		ResultCount = 1
	},
	Backpack9 = {
		Ingredients = { Planks = 5, Fiber = 5, Stone = 5 },
		ResultItem = "Backpack9",
		ResultCount = 1
	},
	Turret = {
		Ingredients = { Planks = 3, Stone = 5 },
		ResultItem = "Turret",
		ResultCount = 1
	},
	Wall = {
		Ingredients = { Planks = 3 },
		ResultItem = "Wall",
		ResultCount = 1
	}
}

return CraftingRecipes
