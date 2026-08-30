# Полный комплект скриптов и руководство по установке в Roblox Studio: *Survive the Cold*

Все игровые механики полностью интегрированы в код для **Roblox Studio** на языке **Luau**.

---

## 📁 Структура скриптов Roblox проекта

Все исходные файлы хранятся в рабочей директории [`roblox_project/`](file:///C:/Users/Professional/Desktop/my%20projects/my%20Roblox%20projects/survive-cold/roblox_project):

```
roblox_project/
├── ServerScriptService/
│   ├── WarmthManager.server.luau          (Система тепла, голода 100%, здоровья, костра и дома)
│   ├── CraftingService.server.luau        (5 уровней верстака, оружие, патронташ, 16 сундуков деталей)
│   ├── PetService.server.luau             (3 питомца: Лис, Волк, Медведь, кормление F, баффы, уход через 60с)
│   ├── MobSpawner.server.luau             (Барьер безопасной зоны X<180, опасная зона X>=250, дроп шкур)
│   ├── FoodShopService.server.luau        (Продуктовый магазин, бесплатный паек, очаг)
│   ├── ShopService.server.luau            (Магазин одежды, бесплатные манекены 1-4, VIP Robux)
│   ├── RelicManager.server.luau           (7 реликвий, Древний Алтарь, Бункер эвакуации и Перерождение)
│   ├── TurretService.server.luau          (Авто-турели и тяжелые сдвоенные турели)
│   ├── WeatherController.server.luau      (Погода, день/ночь, туман, снежная буря)
│   └── DataPersistenceService.server.luau (Автосохранение в DataStore, сохранение дома и вещей)
├── ReplicatedStorage/
│   └── CraftingRecipes.luau               (Конфигурация 5 уровней верстака, рецепты, лимиты стаков)
└── StarterPlayer/StarterPlayerScripts/
    ├── WarmthHUD.client.luau              (HUD: 4 шкалы, хотбар, сумка боеприпасов, дистанции, F/T/G)
    ├── SprintController.client.luau       (Бег на Shift, расход стамины, механика одышки)
    └── WelcomeGuide.client.luau           (Интерактивный Гайд выживающего: 5 вкладок, кнопка в HUD)
```

---

## 🚀 Пошаговая инструкция по установке в Roblox Studio

### Шаг 1: `ReplicatedStorage`
1. Создайте `ModuleScript` с именем **`CraftingRecipes`** и вставьте код из [`CraftingRecipes.luau`](file:///C:/Users/Professional/Desktop/my%20projects/my%20Roblox%20projects/survive-cold/roblox_project/ReplicatedStorage/CraftingRecipes.luau).

### Шаг 2: `ServerScriptService`
Создайте обычные скрипты (`Script`):
1. **`WarmthManager`** (код из [`WarmthManager.server.luau`](file:///C:/Users/Professional/Desktop/my%20projects/my%20Roblox%20projects/survive-cold/roblox_project/ServerScriptService/WarmthManager.server.luau))
2. **`CraftingService`** (код из [`CraftingService.server.luau`](file:///C:/Users/Professional/Desktop/my%20projects/my%20Roblox%20projects/survive-cold/roblox_project/ServerScriptService/CraftingService.server.luau))
3. **`PetService`** (код из [`PetService.server.luau`](file:///C:/Users/Professional/Desktop/my%20projects/my%20Roblox%20projects/survive-cold/roblox_project/ServerScriptService/PetService.server.luau))
4. **`MobSpawner`** (код из [`MobSpawner.server.luau`](file:///C:/Users/Professional/Desktop/my%20projects/my%20Roblox%20projects/survive-cold/roblox_project/ServerScriptService/MobSpawner.server.luau))
5. **`FoodShopService`** (код из [`FoodShopService.server.luau`](file:///C:/Users/Professional/Desktop/my%20projects/my%20Roblox%20projects/survive-cold/roblox_project/ServerScriptService/FoodShopService.server.luau))
6. **`ShopService`** (код из [`ShopService.server.luau`](file:///C:/Users/Professional/Desktop/my%20projects/my%20Roblox%20projects/survive-cold/roblox_project/ServerScriptService/ShopService.server.luau))
7. **`RelicManager`** (код из [`RelicManager.server.luau`](file:///C:/Users/Professional/Desktop/my%20projects/my%20Roblox%20projects/survive-cold/roblox_project/ServerScriptService/RelicManager.server.luau))
8. **`TurretService`** (код из [`TurretService.server.luau`](file:///C:/Users/Professional/Desktop/my%20projects/my%20Roblox%20projects/survive-cold/roblox_project/ServerScriptService/TurretService.server.luau))
9. **`WeatherController`** (код из [`WeatherController.server.luau`](file:///C:/Users/Professional/Desktop/my%20projects/my%20Roblox%20projects/survive-cold/roblox_project/ServerScriptService/WeatherController.server.luau))
10. **`DataPersistenceService`** (код из [`DataPersistenceService.server.luau`](file:///C:/Users/Professional/Desktop/my%20projects/my%20Roblox%20projects/survive-cold/roblox_project/ServerScriptService/DataPersistenceService.server.luau))

### Шаг 3: `StarterPlayer` -> `StarterPlayerScripts`
Создайте клиентские скрипты (`LocalScript`):
1. **`WarmthHUD`** (код из [`WarmthHUD.client.luau`](file:///C:/Users/Professional/Desktop/my%20projects/my%20Roblox%20projects/survive-cold/roblox_project/StarterPlayer/StarterPlayerScripts/WarmthHUD.client.luau))
2. **`SprintController`** (код из [`SprintController.client.luau`](file:///C:/Users/Professional/Desktop/my%20projects/my%20Roblox%20projects/survive-cold/roblox_project/StarterPlayer/StarterPlayerScripts/SprintController.client.luau))
3. **`WelcomeGuide`** (код из [`WelcomeGuide.client.luau`](file:///C:/Users/Professional/Desktop/my%20projects/my%20Roblox%20projects/survive-cold/roblox_project/StarterPlayer/StarterPlayerScripts/WelcomeGuide.client.luau))

