# H-20260910T164821Z-ONBOARD-001-CONTINUITY-GUARD.md

## Граница передачи

- **Создано (UTC):** 2026-09-10T16:48:21Z
- **Work item:** ONBOARD-001 — защита проверенной continuity проекта
- **Завершённый action:** workspace-continuity-guard-update
- **Commit marker:** handoff:20260910T164821Z-ONBOARD-001-CONTINUITY-GUARD
- **Base revision до handoff:** d7f9c3ddf81958de53964bf0c133a54491ff58b9
- **Предыдущий handoff:** handoffs/H-20260910T140325Z-ONBOARD-001.md
- **Resume state при блокере:** planning

## Что изменилось

- Подтверждённый `origin` защищён от самовольной замены, отказа или «очистки» истории из-за legacy-контекста.
- Явно зафиксировано: product work не меняет continuity, а успешный pre-commit не заменяет push и postcommit.

## Канонические входы для нового чата

- `AGENTS.md`
- `control/WORKSPACE-PROFILE.yaml`
- `control/NOW.yaml`
- `handoffs/H-20260910T140325Z-ONBOARD-001.md`

## Проверка

- **Команда / метод:** tools/verify-workspace.ps1 -Phase postcommit после отправки handoff commit в origin
- **Результат:** pass
- **Evidence:** AGENTS.md и этот handoff

## Следующий action

- **ID:** onboard-001-confirm-product-brief
- **Ожидаемый результат:** сохранить или получить одно явное решение владельца без предположений из legacy материалов
- **Blocker / вопрос владельцу:** Нужно решение владельца: назовите одну цель FSIN-app, пользователя и первый наблюдаемый результат, который будет считаться успехом.

## Навигационная сводка для пользователя

- **Режим продолжения:** новый чат
- **Почему:** следующий action ожидает независимое решение владельца и не должен опираться на историю технической защиты среды.
- **Готовая фраза для нового чата:** `Прочитай control/START-NEW-CHAT.md и выполни текущий next_action.`