# INIT-001 — запуск нового проекта

Это единственный action, который существует в чистой копии шаблона. Его цель — не начать реализацию, а создать минимальный, проверяемый контекст для следующего чата.

Начните так: `Выполни INIT-001 по шаблону. Сам предложи безопасный маршрут и задавай мне только решения, которые нельзя безопасно вывести из проекта.` Агент обязан объяснить выбор lane и в конце дать навигационную сводку, а не ожидать, что вы сами догадаетесь о следующем чате.

## Входы

- `README.md`
- `docs/PROJECT-CHARTER.md`
- `control/WORKSPACE-PROFILE.yaml`
- `control/ROUTING.md`

## Что сделать

0. На Windows выберите короткий путь для clone, например `C:\Projects\my-project`; не используйте глубокую временную вложенность.
1. Заполните `docs/PROJECT-CHARTER.md`: одну проблему, проверяемый результат, границы, ограничения и критерии приёмки.
2. Выберите ровно один delivery lane:
   - `change` — ограниченное изменение, исследование, документ или bug;
   - `bmm-project` — продукт, который будет проходить planning, epics/stories и sprint queue.
3. Заполните `control/WORKSPACE-PROFILE.yaml`: ID, название, язык, выбранные modules и lane. Оставьте `migration.state: remote-pending`.
4. Подключите private Git remote `origin`, отправьте в него базовый commit шаблона и убедитесь, что второй аккаунт/компьютер действительно имеет к нему доступ. Затем переведите `migration.state` в `runtime-pending`. Этот минимальный шаблон намеренно не поддерживает альтернативный transport: без доступного remote не начинайте product work.
5. Установите свежие только Core+BMM, запишите фактическую версию BMAD и убедитесь, что generated `_bmad/` и `.agents/` не versioned. Зафиксируйте и отправьте это изменение, затем установите `migration.state: restore-pending`.
6. Проведите restore test в независимом clone/на втором аккаунте. Скопируйте `evidence/CONTINUITY-RESTORE-TEMPLATE.md` в заполненный evidence-файл, запишите его путь в `continuity.evidence_path` и установите `migration.state: ready`.
7. Не включайте extension «на всякий случай». Для каждой нужной extension запишите пользу, владельца её artifacts и последствия для output paths.
8. Только теперь завершите служебный work item: замените `active_work.id: INIT-001` на первый реальный ID (например, `WORK-001`), оставьте `blocker: null` и `resume_state: null`, затем замените `next_action` одним конкретным действием:
   - для `change`: создать или уточнить source contract через выбранный spec workflow;
   - для `bmm-project`: выполнить следующий planning action, который формирует продуктовый contract.
9. Не создавайте handoff после каждого bootstrap action. Сохраняйте обычные durable changes через precommit → commit → push → postcommit в том же чате. Создайте первый handoff по `handoffs/TEMPLATE.md` только на реальной границе передачи, milestone или паузе; запишите его путь в `NOW.last_handoff`, сделайте отдельный handoff commit с marker и отправьте его в `origin`. В состоянии `ready` новый чат может продолжать product work только после успешного postcommit и при наличии переносимого checkpoint.

## Done when

- В уставе нет существенных маркеров `<…>`.
- В профиле выбран один lane Core+BMM и нет второго delivery module.
- `migration.state: ready`; зафиксирована версия BMAD, есть заполненный restore-test evidence, а handoff commit отправлен в доступный private remote.
- `NOW.yaml` указывает только на один следующий action с существующими `input_paths`.
- Новый чистый чат может начать работу, прочитав только файлы из `control/START-NEW-CHAT.md`.

## Не делать

- Не переносить `_bmad/`, `.agents/`, render-cache, локальные конфиги или transcript старого проекта.
- Не создавать параллельные `SPEC`, `PLAN`, `TASKS` и backlog, если соответствующий BMAD artifact уже является владельцем факта.
- Не реализовывать продуктовую функцию до принятия устава и профиля.
