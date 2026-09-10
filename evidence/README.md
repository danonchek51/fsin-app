# Доказательства

Сохраняйте здесь небольшие, проверяемые результаты action: ссылку на запуск тестов, скриншот, лог проверки, checklist review или воспроизводимый отчёт. Имя файла: `E-<UTC>-<work-id>-<subject>.md`.

Evidence не является вторым источником требований или состояния. У него должна быть ссылка на work item и способ повторной проверки. Секреты, персональные данные, большие build-артефакты и machine-local paths сюда не добавляются.

До перевода `migration.state` в `ready` обязателен один короткий record успешного restore test. Скопируйте `CONTINUITY-RESTORE-TEMPLATE.md` в новый файл, заполните его без маркеров `<…>` и укажите этот путь в `control/WORKSPACE-PROFILE.yaml:continuity.evidence_path`. В состоянии `ready` post-commit validator дополнительно проверяет, что текущий `HEAD` уже присутствует на настроенном remote.
