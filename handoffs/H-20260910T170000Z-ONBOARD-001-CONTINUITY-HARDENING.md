# H-20260910T170000Z-ONBOARD-001-CONTINUITY-HARDENING.md

## Граница передачи

- **Создано (UTC):** 2026-09-10T17:00:00Z
- **Work item:** ONBOARD-001 — усиление защиты проверенной continuity проекта
- **Завершённый action:** workspace-continuity-guard-hardening
- **Commit marker:** handoff:20260910T170000Z-ONBOARD-001-CONTINUITY-HARDENING
- **Base revision до handoff:** 22bb2c0ca7c84e5f8bddb53feecf4f001b88ca3a
- **Предыдущий handoff:** handoffs/H-20260910T164821Z-ONBOARD-001-CONTINUITY-GUARD.md
- **Resume state при блокере:** planning

## Что изменилось

- Нельзя обойти защиту origin самовольной сменой migration.state, полей continuity.* или continuity evidence.
- Postcommit теперь подтверждает, что текущий handoff commit находится именно в текущей ветке подтверждённого remote, а не только где-либо на remote.

## Канонические входы для нового чата

- AGENTS.md
- control/WORKSPACE-PROFILE.yaml
- control/NOW.yaml
- handoffs/H-20260910T164821Z-ONBOARD-001-CONTINUITY-GUARD.md

## Проверка

- **Команда / метод:** tools/verify-workspace.ps1 -Phase postcommit после отправки handoff commit в origin
- **Результат:** pass
- **Evidence:** AGENTS.md, tools/verify-workspace.ps1 и этот handoff

## Следующий action

- **ID:** onboard-001-confirm-product-brief
- **Ожидаемый результат:** сохранить или получить цель, пользователя и наблюдаемый первый результат без предположений из legacy материалов
- **Blocker / вопрос владельцу:** Нужно решение владельца: какова цель, пользователь и первый наблюдаемый успех продукта?

## Навигационная сводка для пользователя

- **Режим продолжения:** новый чат
- **Почему:** следующий action ожидает независимое решение владельца и не должен опираться на историю технической защиты среды.
- **Готовая фраза для нового чата:** Прочитай control/START-NEW-CHAT.md и выполни текущий next_action.
