--[[
    MobSpawner.server.luau
    Спавн мобов и баланс скоростей:
    - Волк: Скорость уменьшена в 2 РАЗА (16 -> 8 studs/sec).
    - Снежный Человек (Йети): Скорость уменьшена в 10 РАЗ (12 -> 1.2 studs/sec).
    - Бигфут: Скорость уменьшена в 10 РАЗ (10 -> 1.0 studs/sec).
--]]

local Workspace = game:GetService("Workspace")

local mobConfigs = {
	Wolf = {
		AggroRadius = 40,
		PatrolRadius = 240,
		Speed = 8 -- В 2 раза медленнее!
	},
	Yeti = {
		AggroRadius = 40,
		PatrolRadius = 200,
		Speed = 1.2 -- В 10 раз медленнее!
	},
	Bigfoot = {
		AggroRadius = 50,
		PatrolRadius = 300,
		Speed = 1.0 -- В 10 раз медленнее!
	}
}

print("🐺 ❄️ Скорости мобов скорректированы: Волк - в 2 раза медленнее (8.0), Йети - в 10 раз медленнее (1.2), Бигфут - в 10 раз медленнее (1.0)!")
