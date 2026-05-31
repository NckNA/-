# Владение

Ранний прототип игры на Godot 4.6.3.

## Что уже есть

- глобальная процедурная карта мира;
- локальная карта выбранного тайла;
- сбор дерева, камня и ягод;
- лагерь, костер, склад, готовка и отдых;
- энергия, голод, здоровье и базовые навыки;
- журнал событий и обучающие цели;
- локальная сетка земли и разметка зон.

## Запуск

Откройте проект в Godot 4.6.3 и запустите главную сцену:

```text
res://scenes/GlobalMapScene.tscn
```

Через консольный Godot из корня проекта:

```powershell
.\Godot_v4.6.3-stable_win64_console.exe --path .
```

## Тесты

Тесты лежат в папке `tests/` и запускаются headless:

```powershell
Get-ChildItem tests -Filter *.gd | Sort-Object Name | ForEach-Object {
    .\Godot_v4.6.3-stable_win64_console.exe --headless --path . -s $_.FullName
}
```

## Структура

- `project.godot` - настройки проекта и autoload.
- `scenes/` - основные сцены.
- `scripts/autoload/` - состояние игры и сохранения.
- `scripts/global/` - глобальная карта.
- `scripts/local/` - локальная сцена тайла.
- `data/` - ресурсы данных игрока и тайлов.
- `assets/` - игровые ассеты.
- `tests/` - headless-тесты.
