# INIT-001 — переносимая среда для существующего проекта

## Цель

Сначала сделать migration-ветку восстанавливаемой между чистыми чатами,
аккаунтами и компьютерами. Это действие не принимает продуктовые решения и
не продолжает старую работу автоматически.

## Единственный маршрут до завершения INIT

1. Выполни только `control/NOW.yaml:next_action`.
2. Подключи согласованный private Git remote как `origin`, отправь migration
   branch и checkpoint в remote.
3. Проведи восстановление в чистом clone и сохрани результат в evidence.
4. Только затем закрой `INIT-001`, установи свежий Core+BMM runtime и выбери
   один реальный work item отдельным action.

## Правила

- Не читай весь legacy-репозиторий: открывай только evidence, на которое
  указывает `docs/PROJECT-CHARTER.md`, и только после соответствующего action.
- Не считай старые specs, brainstorming, screenshots или чат продуктовым
  решением без явного подтверждения владельца.
- Пока private remote не подтверждён, не запускай `bmad-spec`, `bmad-build`,
  sprint planning, implementation, importer или product research.
- Не переноси локальные секреты, credentials, vault, raw export,
  machine-local config, chat sessions или installer-managed runtime.
- Если URL или доступ к private remote отсутствует, задай владельцу ровно
  один вопрос: какой private remote использовать как `origin`?
