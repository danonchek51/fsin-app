# Состояния диспетчера

`active_work.dispatch_state` описывает только состояние **передачи и следующего действия**. Он не заменяет lifecycle нативного BMAD contract и не копирует его status.

| State | Значение | Допустимый следующий шаг |
| --- | --- | --- |
| `setup` | Новый проект ещё не имеет принятого charter/profile | `INIT-001` → `planning` |
| `planning` | Уточняется source contract или product planning | source contract / planning action → `implementation`, `verification` или `blocked` |
| `implementation` | Выполняется принятый implementation contract | implementation action → `verification` или `blocked` |
| `verification` | Проверяются результат и evidence | verification → `closed`, `planning` или `blocked` |
| `blocked` | Нужен ответ владельца; агент не должен угадывать | только `ask-owner` → `resume_state` |
| `closed` | Work item закончен | создать новый work item в `setup`/`planning` |

## Инварианты

- При `blocked` поля `blocker` и `resume_state` обязательны, а `next_action.kind` равно `ask-owner`. `resume_state` хранит точное состояние возврата: `setup`, `planning`, `implementation` или `verification`.
- После ответа владельца восстановите `dispatch_state` из `resume_state`, затем очистите `blocker` и `resume_state` и создайте один новый action.
- В остальных состояниях `blocker: null` и `resume_state: null`.
- `bmad-build` требует `source_contract`; `implementation` action требует и `source_contract`, и `implementation_contract`.
- После каждого законченного action обновляются state, один `next_action`, handoff и `NOW.last_handoff`.
