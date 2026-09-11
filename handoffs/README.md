# Передачи между чатами

Handoff — неизменяемый снимок настоящей границы работы: перед новым чатом, после значимого milestone, при осознанной паузе или при блокере, который должен пережить чат. Он делает продолжение возможным без истории чата, но не заменяет `NOW.yaml` и канонические BMAD artifacts.

Не создавайте handoff для короткого уточнения, обычной правки, теста, commit, push или смены фазы. `NOW.last_handoff` хранит последний переносимый checkpoint; его Next action может быть старше текущего `NOW.next_action`. При расхождении всегда приоритетен текущий `NOW.yaml`.

Когда handoff действительно нужен, создайте `H-<UTC>-<work-id>.md` из `TEMPLATE.md`, обновите `control/NOW.yaml` и запишите путь в `last_handoff`. Затем выполните: `tools/verify-workspace.ps1 -Phase precommit` → отдельный Git commit с marker handoff → push в подтверждённый private remote → `tools/verify-workspace.ps1 -Phase postcommit`. Postcommit проверяет чистое рабочее дерево, текущий HEAD на remote и историческую целостность checkpoint commit.

Для обычного долговечного изменения используйте тот же короткий путь без handoff: precommit → обычный commit → push в подтверждённый remote → postcommit.

Не исправляйте уже закоммиченный handoff. Если в нём есть ошибка, создайте новый handoff с ссылкой на прежний и объяснением исправления.
