# Полный комплект скриптов и руководство по установке в Roblox Studio: *Survive the Cold*

Мы создали полный готовый пакет скриптов на языке **Luau** для переноса вашей игры в Roblox Studio. 

---

## 📁 Структура созданных скриптов проекта

Все созданные исходные файлы хранятся в рабочей директории:

```
roblox_project/
├── ServerScriptService/
│   ├── WarmthManager.server.luau     (Система тепла, гипотермии и обогрева)
│   ├── WeatherController.server.luau (Динамика погоды, день/ночь, туман, близзард)
│   ├── TurretService.server.luau     (ИИ прицеливания турелей, стрельба, урона)
│   ├── CraftingService.server.luau   (Серверный крафт, списание ресурсов, постройка)
│   ├── MobSpawner.server.luau        (Спавнер ночных волн ледяных волков)
│   └── RelicManager.server.luau      (Квест 7 реликвий и победный финал)
├── ReplicatedStorage/
│   └── CraftingRecipes.luau          (Модуль рецептов крафта и турелей)
└── StarterPlayerScripts/
    └── WarmthHUD.client.luau         (Интерфейс: шкала тепла, иней на экране, предупреждения)
```

---

## 🚀 Пошаговая инструкция по переносу в Roblox Studio

### Шаг 1: Создание проекта в Roblox Studio
1. Откройте **Roblox Studio** и создайте новый шаблон **Baseplate** или **Village** (заснеженная карта).
2. Зайдите в окно `Explorer` (Explorer / Output / Properties).

### Шаг 2: Добавление серверных скриптов (`ServerScriptService`)
Создайте в папке `ServerScriptService` следующие обычные скрипты (`Script`):

1. **`WarmthManager`**: скопируйте код из [`WarmthManager.server.luau`](file:///C:/Users/pc1/.gemini/antigravity-cli/brain/851fc925-15bf-48d5-b245-4db4d5298f2d/roblox_project/ServerScriptService/WarmthManager.server.luau).
2. **`WeatherController`**: скопируйте код из [`WeatherController.server.luau`](file:///C:/Users/pc1/.gemini/antigravity-cli/brain/851fc925-15bf-48d5-b245-4db4d5298f2d/roblox_project/ServerScriptService/WeatherController.server.luau).
3. **`TurretService`**: скопируйте код из [`TurretService.server.luau`](file:///C:/Users/pc1/.gemini/antigravity-cli/brain/851fc925-15bf-48d5-b245-4db4d5298f2d/roblox_project/ServerScriptService/TurretService.server.luau).
4. **`CraftingService`**: скопируйте код из [`CraftingService.server.luau`](file:///C:/Users/pc1/.gemini/antigravity-cli/brain/851fc925-15bf-48d5-b245-4db4d5298f2d/roblox_project/ServerScriptService/CraftingService.server.luau).
5. **`MobSpawner`**: скопируйте код из [`MobSpawner.server.luau`](file:///C:/Users/pc1/.gemini/antigravity-cli/brain/851fc925-15bf-48d5-b245-4db4d5298f2d/roblox_project/ServerScriptService/MobSpawner.server.luau).
6. **`RelicManager`**: скопируйте код из [`RelicManager.server.luau`](file:///C:/Users/pc1/.gemini/antigravity-cli/brain/851fc925-15bf-48d5-b245-4db4d5298f2d/roblox_project/ServerScriptService/RelicManager.server.luau).

### Шаг 3: Добавление модуля рецептов (`ReplicatedStorage`)
1. В папке `ReplicatedStorage` создайте **`ModuleScript`** и назовите его `CraftingRecipes`.
2. Скопируйте код из [`CraftingRecipes.luau`](file:///C:/Users/pc1/.gemini/antigravity-cli/brain/851fc925-15bf-48d5-b245-4db4d5298f2d/roblox_project/ReplicatedStorage/CraftingRecipes.luau).

### Шаг 4: Добавление клиентского UI (`StarterPlayerScripts`)
1. Откройте `StarterPlayer` -> `StarterPlayerScripts`.
2. Создайте **`LocalScript`** с именем `WarmthHUD`.
3. Скопируйте код из [`WarmthHUD.client.luau`](file:///C:/Users/pc1/.gemini/antigravity-cli/brain/851fc925-15bf-48d5-b245-4db4d5298f2d/roblox_project/StarterPlayerScripts/WarmthHUD.client.luau).

---

## 🎮 Тестирование игровой механики

1. Нажмите кнопку **Play** (`F5`) в Roblox Studio.
2. **Интерфейс**: Внизу экрана появится шкала `🔥 Тепло: 100%`, вверху справа — счетчик `🗿 Реликвии: 0 / 7`.
3. **Мороз и Буря**: Каждые несколько минут сменяется фаза погоды. При наступлении бури видимость падает, туман становится густым, а шкала тепла быстро опускается. Когда тепло падаёт ниже 40%, на экране появляется эффект инея.
4. **Реликвии**: На карте автоматически создаются 7 светящихся артефактов с ProximityPrompt. При их активации счетчик растет. Когда собраны все 7 — срабатывает финал (рассвет).
