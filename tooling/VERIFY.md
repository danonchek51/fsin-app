# Критерии готовности рабочей среды

`tools/verify-workspace.ps1` проверяет механически то, что можно проверить без модели: структуру, один исполнимый `next_action`, существование его входов, machine state, целостность handoff, профиль Core+BMM и Git-переносимость. Строгая готовность определяется только явным `migration.state`, а не наличием первого handoff.

Профиль намеренно имеет небольшой проверяемый YAML-контракт: `bmad_install`, `delivery` и `active_work` — корневые блоки, а `enabled_modules` записывается многострочным списком. Не заменяйте его inline-списком или произвольной вложенной схемой: validator должен оставаться простым и прозрачным.

Перед каждым handoff также проверьте смысл вручную.

## Обязательные условия

1. `control/NOW.yaml` содержит ровно один `next_action` с непустыми ID, title, допустимым kind, input paths, expected outputs, done when и forbidden scope.
2. Все `input_paths` существуют и достаточны для действия; новый чат не должен искать контекст по всему репозиторию.
3. Каждый факт имеет ровно одного владельца по таблице в `README.md`.
4. В профиле выбран один delivery lane Core+BMM. Второй delivery module не установлен.
5. У active work есть `source_memlog` и `source_contract`, если создан SDD-contract; Build получает `source_contract` как input, а implementation contract ссылается на него в frontmatter.
6. Изменённые contracts, evidence, `NOW` и handoff versioned в Git. Локальные конфиги, секреты и caches не versioned.
7. Если `NOW.last_handoff` не `null`, он указывает на существующий versioned handoff с marker, проверкой и ровно тем следующим action, который указан в `NOW`.
8. При `migration.state: ready` `NOW.last_handoff` обязателен; в profile зафиксирована фактическая версия BMAD, есть заполненный успешный restore-test evidence, а private Git remote доступен.
9. `dispatch_state` следует `control/STATE-MACHINE.md`: при `blocked` есть blocker, `resume_state` и один `ask-owner`; вне блокера оба поля очищены.

## Проверка handoff в два этапа

До commit запустите `./tools/verify-workspace.ps1 -Phase precommit`: он проверяет structure, paths, handoff contents и profile, но ещё не требует marker в Git.

После отдельного commit с marker отправьте его в private remote и запустите `./tools/verify-workspace.ps1`: это post-commit режим. Он требует marker в текущем `HEAD` и наличие в нём `control/NOW.yaml` и указанного handoff-файла. При `migration.state: ready` он дополнительно требует чистое дерево и присутствие текущего `HEAD` на remote.

## Граница нового чата

Проведите практический тест: откройте чистый чат без прежнего transcript, вставьте `control/START-NEW-CHAT.md` и разрешите ему читать только перечисленные входы. Он должен суметь назвать один результат следующего action, его ограничения и критерий завершения. Если не может — входов не хватает, а не «нужно больше контекста».

Проверьте и предшествующий чат: после завершения action он обязан сам выдать навигационную сводку с причиной перехода, ID следующего action и готовой фразой для нового чата. Пользователь не должен угадывать эту границу.

## Критерий выпуска шаблона

Шаблон считается пригодным для нового проекта, если `INIT-001` можно завершить без переноса материалов другого проекта, `migration.state` достигает `ready`, и после этого новый чат проходит практический тест выше.
