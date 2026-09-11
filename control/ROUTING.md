# Маршрутизация BMAD + SDD

## 1. Сначала выберите lane

`control/WORKSPACE-PROFILE.yaml` содержит один lane:

| Lane | Когда подходит | Владелец состояния |
| --- | --- | --- |
| `change` | Изменение продукта, кода, данных, архитектуры или документа, которому нужен принятый contract | source `.memlog.md` → implementation spec lifecycle; NOW только pointer/action |
| `bmm-project` | Продукт с утверждёнными epics/stories | BMM `sprint-status.yaml` владеет очередью; NOW указывает на одну выбранную story/action |

Не меняйте lane в середине work item без decision и migration step. Новый handoff нужен лишь если это создаёт реальную границу передачи. Этот минимальный шаблон преднамеренно не поддерживает GDS: игровой workflow создаётся как отдельная среда с отдельным owner matrix, а не добавляется к BMM.

## 2. Change lane

1. Когда работа изменяет долговечный продуктовый или репозиторный результат и ещё нет принятого контракта, `NOW.next_action` вызывает `bmad-spec` с точным input set.
2. `bmad-spec` создаёт workspace в `_bmad-output/specs/spec-<slug>/`. Его `.memlog.md` — source of record; `SPEC.md` и companions — производные, их не редактируют вручную.
3. После принятия source contract NOW хранит `source_memlog` (канонический журнал решений) и `source_contract` (производный `SPEC.md`). Companions перечисляются только в `next_action.input_paths`, если действительно нужны действию.
4. Build вызывается с явным `source_contract` в `next_action.input_paths`. Его implementation spec в `_bmad-output/implementation-artifacts/` получает frontmatter pointer `source_contract: <relative path to SPEC.md>` и при необходимости `source_memlog: <relative path to .memlog.md>`.
5. Требования не копируются между уровнями. Build spec содержит только реализационные задачи, verification и lifecycle.
6. После review/verification NOW указывает на следующий один action или закрывает work item.

### Лёгкий безопасный маршрут

Короткая read-only проверка с вручную переданными несекретными входами может идти из краткого решения прямо к verification: зафиксируйте цель, границы, разрешённые входы и результат в `NOW`/evidence. Не создавайте `bmad-spec`, implementation contract или build, если тест не меняет продукт, код, данные или архитектуру. Если тест превращается в долговечное изменение — создайте один source contract до реализации.

## 3. BMM project lane

После BMM planning path и принятия epics BMM создаёт `sprint-status.yaml`. Этот файл — единственный владелец очереди stories. NOW не копирует его статусы: в `active_work.queue_path` он хранит путь, а в `active_work.selected_story_id` — ID выбранной story. Следующий action может быть, например, «создать story contract» или «выполнить build для story 2-3».

Если `sprint-status.yaml` не существует, не притворяйтесь, что очередь существует: оставайтесь в `change` lane либо завершите planning action.

## 4. Запрещённые сочетания

- Любой второй delivery module в этой Core+BMM среде.
- BMM sprint status + второй tasks/backlog engine для тех же stories.
- Source `SPEC.md` как вручную редактируемый второй contract поверх `.memlog.md`.
- `NOW.yaml` как копия status/requirements/backlog.

## 5. Связь с новым чатом

BMAD помогает выполнять workflow, но не создаёт автоматически новый пользовательский чат и не переносит в него transcript. Межчатовый слой — `NOW.yaml` + immutable handoff + Git. При `migration.state: ready` `NOW.last_handoff` обязателен как последний переносимый checkpoint, но не обязан обновляться после каждого внутреннего шага. Новый чат нужен только на реальной границе работы; короткие вопросы, тесты, commits и переходы фазы остаются в текущем чате.
