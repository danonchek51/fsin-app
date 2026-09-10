# Baseline BMAD для этой среды

Цель baseline — сделать BMAD воспроизводимым инструментом проекта, а не вторым репозиторием с вручную исправленными generated skills.

## Рекомендуемая конфигурация

| Сценарий | Modules | Delivery lane | Очередь |
| --- | --- | --- | --- |
| Обычный продукт, изменение, исследование | `core` + `bmm` | `change` в начале; `bmm-project` после planning | `sprint-status.yaml` только когда BMM его создал |

`core + bmm` — единственный delivery baseline этого шаблона. Другой delivery module требует отдельной среды и отдельного проверенного owner matrix; не добавляйте его к BMM даже при разных output paths.

## Что означает SDD здесь

SDD — порядок мышления, а не второй установленный движок:

1. Зафиксировать источник требований и решений.
2. Превратить его в реализационный contract.
3. Выполнить реализацию только из принятого contract.
4. Сохранить проверяемое evidence.

В BMM-профиле source of record для bounded change — append-only `.memlog.md` в workspace `bmad-spec`; `SPEC.md` и companion files являются производными. Реализационный lifecycle принадлежит BMM implementation spec. Не создавайте поверх этого самостоятельный каталог с ещё одним `SPEC/PLAN/TASKS` для той же работы.

## Установка и version control

По умолчанию выбран `bootstrap-per-clone`:

- каждый клон устанавливает BMAD с нуля по текущей официальной процедуре;
- версия и modules фиксируются в `control/WORKSPACE-PROFILE.yaml`;
- installer-managed `_bmad/` и `.agents/` игнорируются Git;
- проектные artifacts в `_bmad-output/`, `docs/`, `evidence/`, `handoffs/`, код и тесты остаются versioned.

Этот минимальный шаблон не поддерживает `vendor-managed-install`: это отдельная архитектура с lock/checksum и собственным verifier, а не расширение этого baseline. Нельзя вручную патчить generated files.

## Extensions

TEA, CIS, Builder, Loop и Build Auto выключены в базовом профиле. Их включение требует decision с четырьмя ответами: зачем extension нужна, какие новые artifacts она создаёт, кто владеет ими и как исключён конфликт с существующим lane.

Loop и Build Auto не являются «следующим шагом» в обычном workflow: это автоматизация, которую включают только после того, как ручной путь стабильно проходит критерии приёмки.
