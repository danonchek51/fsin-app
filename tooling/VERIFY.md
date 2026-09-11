# Критерии готовности рабочей среды

`tools/verify-workspace.ps1` проверяет механически то, что можно проверить без модели: структуру, один исполнимый `next_action`, существование его входов, machine state, целостность последнего handoff checkpoint, профиль Core+BMM и Git-переносимость. Строгая готовность определяется только явным `migration.state`, а не числом handoff.

Профиль намеренно имеет небольшой проверяемый YAML-контракт: `bmad_install`, `delivery` и `active_work` — корневые блоки, а `enabled_modules` записывается многострочным списком. Не заменяйте его inline-списком или произвольной вложенной схемой: validator должен оставаться простым и прозрачным.

Перед настоящим handoff также проверьте смысл вручную.

## Обязательные условия

1. `control/NOW.yaml` содержит ровно один `next_action` с непустыми ID, title, допустимым kind, input paths, expected outputs, done when и forbidden scope.
2. Все `input_paths` существуют и достаточны для действия; новый чат не должен искать контекст по всему репозиторию.
3. Каждый факт имеет ровно одного владельца по таблице в `README.md`.
4. В профиле выбран один delivery lane Core+BMM. Второй delivery module не установлен.
5. У active work есть `source_memlog` и `source_contract`, если создан SDD-contract; Build получает `source_contract` как input, а implementation contract ссылается на него в frontmatter.
6. Изменённые contracts, evidence, `NOW` и handoff versioned в Git. Локальные конфиги, секреты и caches не versioned.
7. Если `NOW.last_handoff` не `null`, он указывает на существующий versioned checkpoint с marker. Validator находит commit, в котором этот handoff был добавлен, и проверяет marker, handoff, исторический `NOW.yaml` и next action именно на момент checkpoint. Он не требует, чтобы checkpoint совпадал с текущим `NOW.next_action`.
8. При `migration.state: ready` `NOW.last_handoff` обязателен; в profile зафиксирована фактическая версия BMAD, есть заполненный успешный restore-test evidence, а private Git remote доступен.
9. `dispatch_state` следует `control/STATE-MACHINE.md`: при `blocked` есть blocker, `resume_state` и один `ask-owner`; вне блокера оба поля очищены.

## Проверка durable changes и handoff

До любого долговечного commit запустите `./tools/verify-workspace.ps1 -Phase precommit`: он проверяет structure, paths, profile и существующий checkpoint, но ещё не требует чистое дерево или отправленный HEAD.

После обычного commit и push в подтверждённый remote запустите `./tools/verify-workspace.ps1 -Phase postcommit` (это также режим по умолчанию). Он требует чистое дерево и присутствие текущего HEAD на remote, но не требует новый handoff ради обычной работы.

Если создаётся настоящий handoff, поместите handoff и обновлённый `NOW.last_handoff` в один commit с его marker, затем отправьте его и запустите тот же postcommit. Он проверит этот checkpoint commit исторически; дальнейшие обычные commits в том же чате допустимы.

## Граница нового чата

Проводите практический тест чистого чата только когда агент действительно выбрал новый чат: откройте его без прежнего transcript, вставьте `control/START-NEW-CHAT.md` и разрешите читать только перечисленные входы. Он должен суметь назвать один результат следующего action, его ограничения и критерий завершения. Если не может — входов не хватает, а не «нужно больше контекста».

В обычном чате агент после значимого результата сам выбирает `продолжить здесь` или `новый чат`, называет один следующий шаг и объясняет причину. Пользователь не должен угадывать границу, но не должен получать новый чат из-за технического микрошагa.

## Критерий выпуска шаблона

Шаблон считается пригодным для нового проекта, если `INIT-001` можно завершить без переноса материалов другого проекта, `migration.state` достигает `ready`, и после этого чистый чат проходит практический тест только на реальной границе передачи.
