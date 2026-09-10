# Восстановление и разбор конфликтов

## Неполный или противоречивый NOW

Не выбирайте работу по имени файла, последнему чату или предположению. Установите `active_work.dispatch_state: blocked`, заполните `blocker` и `resume_state` (точное состояние, в которое надо вернуться), затем создайте `ask-owner` action с одним вопросом: какой work item и какой владелец состояния являются актуальными.

## Два активных source/implementation contracts

Остановите build. В decision зафиксируйте, какой contract канонический, а второй переведите в `legacy/` либо отметьте superseded. Только после этого обновите NOW.

## Второй delivery module в Core+BMM среде

Это блокер профиля независимо от путей. Не лечите ручной заменой paths в generated skills. Создайте отдельную clean среду для другого module, сохраните artifacts как legacy и зафиксируйте migration decision.

## Непереносимый путь или stale render-cache

Не копируйте render-cache. Удалите только подтверждённый cache, перегенерируйте workflow с текущим project root и сохраните факт проверки в evidence. Не переписывайте generated step files вручную.

## Новый аккаунт или компьютер

1. Клонируйте Git repo.
2. Установите BMAD заново согласно `WORKSPACE-PROFILE.yaml` (`bootstrap-per-clone`).
3. Создайте только local config, который намеренно не хранится в Git.
4. Запустите clean chat с `START-NEW-CHAT.md`.
5. Если artifacts отсутствуют, не компенсируйте это рассказом из старого чата: state становится `blocked`, пока missing files не восстановлены.
