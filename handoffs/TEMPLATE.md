# H-<UTC>-<work-id>

> Скопируйте этот файл только для настоящей границы передачи, замените все `<…>` и затем больше не меняйте его после commit.

## Граница передачи

- **Создано (UTC):** `<YYYY-MM-DDTHH:MM:SSZ>`
- **Work item:** `<id and short title>`
- **Завершённый milestone / action:** `<what this checkpoint preserves>`
- **Commit marker:** `handoff:<UTC>-<work-id>`
- **Base revision до handoff:** `<git HEAD before this handoff commit, or “no-git-yet”>`
- **Предыдущий handoff:** `<path or null>`
- **Resume state при блокере:** `<null or setup | planning | implementation | verification>`

## Что изменилось

- `<canonical artifact / code / decision created or changed>`

## Канонические входы для нового чата

- `AGENTS.md`
- `control/WORKSPACE-PROFILE.yaml`
- `control/NOW.yaml`
- `<source contract, implementation contract, selected story, or evidence path>`

## Проверка

- **Команда / метод:** `<command or manual protocol>`
- **Результат:** `<pass | fail | not-run with reason>`
- **Evidence:** `<relative path or none>`

## Следующий action на момент checkpoint

- **ID:** `<must equal control/NOW.yaml next_action.id in this handoff commit>`
- **Ожидаемый результат:** `<one bounded outcome>`
- **Blocker / вопрос владельцу:** `<none or one concrete question>`

## Навигационная сводка для пользователя

- **Режим продолжения:** `<новый чат | продолжить здесь>`
- **Почему:** `<one concrete reason>`
- **Готовая фраза для нового чата:** `Прочитай control/START-NEW-CHAT.md и выполни текущий next_action.`

Полный hash этого же handoff commit здесь намеренно не обязателен: он неизвестен до создания commit. Проверка находит commit по `Commit marker`, сверяет исторический `NOW.yaml` из checkpoint, а затем сверяет актуальный HEAD и текущий `NOW.yaml`. Обычные commits после checkpoint допустимы.
