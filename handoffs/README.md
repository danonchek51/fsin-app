# Передачи между чатами

Handoff — неизменяемый снимок завершённой границы работы. Он делает продолжение возможным без истории чата, но не заменяет `NOW.yaml` и канонические BMAD artifacts.

После каждого session-sized action создайте `H-<UTC>-<work-id>.md` из `TEMPLATE.md`, обновите `control/NOW.yaml` и запишите путь нового handoff в `last_handoff`. Его Next action ID обязан совпадать с `NOW.next_action.id`.

Затем выполните строгий двухфазный протокол: `tools/verify-workspace.ps1 -Phase precommit` → отдельный Git commit с marker handoff → push этого commit в private remote → `tools/verify-workspace.ps1`. Post-commit проверка требует чистое рабочее дерево, именно этот marker в текущем `HEAD` и наличие текущего `HEAD` на remote; до её успеха handoff не готов к передаче.

Не исправляйте уже закоммиченный handoff. Если в нём есть ошибка, создайте новый handoff с ссылкой на прежний и объяснением исправления.
