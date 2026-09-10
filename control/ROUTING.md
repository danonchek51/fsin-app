# Маршрутизация BMAD + SDD

## 1. Сначала выберите lane

`control/WORKSPACE-PROFILE.yaml` содержит один lane:

| Lane | Когда подходит | Владелец состояния |
| --- | --- | --- |
| `change` | Ограниченное изменение, исследование, документ или bug | source `.memlog.md` → implementation spec lifecycle; NOW только pointer/action |
| `bmm-project` | Продукт с утверждёнными epics/stories | BMM `sprint-status.yaml` владеет очередью; NOW указывает на одну выбранную story/action |

Не меняйте lane в середине work item без decision, migration step и нового handoff. Этот минимальный шаблон преднамеренно не поддерживает GDS: игровой workflow создаётся как отдельная среда с отдельным owner matrix, а не добавляется к BMM.

## 2. Change lane

1. Когда нет принятого контракта, `NOW.next_action` вызывает `bmad-spec` с точным input set.
2. `bmad-spec` создаёт workspace в `_bmad-output/specs/spec-<slug>/`. Его `.memlog.md` — source of record; `SPEC.md` и companions — производные, их не редактируют вручную.
3. После принятия source contract NOW хранит `source_memlog` (канонический журнал решений) и `source_contract` (производный `SPEC.md`). Companions перечисляются только в `next_action.input_paths`, если действительно нужны действию.
4. Build вызывается с явным `source_contract` в `next_action.input_paths`. Его implementation spec в `_bmad-output/implementation-artifacts/` получает frontmatter pointer `source_contract: <relative path to SPEC.md>` и при необходимости `source_memlog: <relative path to .memlog.md>`.
5. Требования не копируются между уровнями. Build spec содержит только реализационные задачи, verification и lifecycle.
6. После review/verification NOW указывает на следующий один action или закрывает work item.

## 3. BMM project lane

После BMM planning path и принятия epics BMM создаёт `sprint-status.yaml`. Этот файл — единственный владелец очереди stories. NOW не копирует его статусы: в `active_work.queue_path` он хранит путь, а в `active_work.selected_story_id` — ID выбранной story. Следующий action может быть, например, «создать story contract» или «выполнить build для story 2-3».

Если `sprint-status.yaml` не существует, не притворяйтесь, что очередь существует: оставайтесь в `change` lane либо завершите planning action.

## 4. Запрещённые сочетания

- Любой второй delivery module в этой Core+BMM среде.
- BMM sprint status + второй tasks/backlog engine для тех же stories.
- Source `SPEC.md` как вручную редактируемый второй contract поверх `.memlog.md`.
- `NOW.yaml` как копия status/requirements/backlog.

## 5. Связь с новым чатом

BMAD помогает выполнять workflow, но не создаёт автоматически новый пользовательский чат и не переносит в него транскрипт. Межчатовый слой — `NOW.yaml` + immutable handoff + Git. После `INIT-001` `NOW.last_handoff` обязателен. Это сознательная часть среды, а не скрытая функция одного skill.
