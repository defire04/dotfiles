# Kitty: сессии

Kitty запоминает вкладки, папки и запущенные программы (claude, btop, lazygit и т. д.) и после перезагрузки открывает их снова. Отдельно есть kitty вне сессии, его вкладки никуда не сохраняются.

Код здесь не копируется, только пути и что делает каждый файл. Копии в этой доке устаревали, теперь смотреть сами файлы. Все они лежат в `~/dotfiles/packages/` и ставятся через stow.

## Клавиши

| Клавиша | Что делает |
|---|---|
| Ctrl+Alt+T | Основной kitty. Если он не запущен, открывает сохранённую сессию. Если уже запущен, открывает новое окно в нём |
| Ctrl+Alt+H | Kitty вне сессии. Не сохраняется и не трогает основную сессию |
| Ctrl+S | Сохранить сессию сейчас, не дожидаясь таймера |

Клавиши KDE назначены в `kde/.config/kglobalshortcutsrc` (разделы `[services][kitty.desktop]` и `[services][kitty-scratch.desktop]`). Новую клавишу назначать через Параметры системы → Комбинации клавиш → «Добавить» → «Приложение». Руками этот файл не править: KDE держит его в памяти и при выходе из системы перезапишет.

## Как это работает

```
Ctrl+Alt+T ──► kitty-start.sh ──► есть @kitty-main.sock?
                                     ├─ нет ──► kitty --session last.kitty-session
                                     └─ да  ──► новое окно в запущенном kitty

таймер 5 мин / Ctrl+S ──► kitty-save-session.sh
      ──► kitty @ ls (через @kitty-main.sock) ──► session-convert.py ──► last.kitty-session

Ctrl+Alt+H ──► kitty-scratch.sh ──► отдельный kitty, сокет @kitty-scratch.sock
```

Сохранение и запуск находят основной kitty по сокету `@kitty-main.sock`. Kitty вне сессии слушает другой сокет, поэтому его никто не видит.

## Файлы

### Основная сессия

- `kitty/.config/kitty/kitty.conf`. Нужное для сессий в начале файла: `allow_remote_control yes` (без этого сохранение не может спросить kitty о вкладках), `listen_on unix:@kitty-main.sock` (kitty сам добавляет к имени `-<pid>`), `single_instance yes`, `startup_session none`.
- `scripts/.local/bin/kitty-start.sh`. Запуск по Ctrl+Alt+T. Сокета `@kitty-main.sock` нет, значит kitty не запущен: открывает `last.kitty-session`. Есть, значит открывает новое окно в уже запущенном.
- `systemd/.config/systemd/user/app-kitty@.service.d/exec.conf`. KDE запускает приложения по `.desktop` через systemd, этот файл подменяет команду на `kitty-start.sh`.
- `scripts/.local/bin/kitty-save-session.sh`. Снимает через `kitty @ ls` два снимка, JSON и готовый файл сессии, отдаёт их в `session-convert.py` и пишет результат в `last.kitty-session`. Если новая версия отличается от прошлой, прошлая уходит в `last.kitty-session.prev`. По ней можно вернуть вкладки, если сохранение записало не то.
- `kitty/.config/kitty/session-convert.py`. Берёт файл сессии от kitty (там есть раскладка панелей) и подставляет в каждую панель её папку и программу из списка `PROGRAMS`. Claude ищется по всему дереву процессов панели и запускается с `--continue`, kiro-cli с `--resume`. Команды из нескольких строк не сохраняются, иначе ломают файл сессии.
- `systemd/.config/systemd/user/kitty-save-session.service` и `.timer`. Запускают сохранение каждые 5 минут.

### Kitty вне сессии

- `scripts/.local/bin/kitty-scratch.sh`. Запускает `kitty --single-instance --instance-group scratch -o listen_on=unix:@kitty-scratch.sock -o startup_session=none`.
  - `--instance-group scratch` запускает отдельный процесс kitty, поэтому окно не откроется вкладкой в основном.
  - `listen_on=unix:@kitty-scratch.sock` нужен, чтобы этот kitty не занял имя `@kitty-main.sock-<pid>` из `kitty.conf`. Иначе сохранение могло бы выбрать его сокет и записать в сессию его вкладки вместо основных.
  - Повторный Ctrl+Alt+H открывает новое окно в том же отдельном kitty.
- `scripts/.local/share/applications/kitty-scratch.desktop`. Пункт меню «kitty (вне сессии)», на него назначен Ctrl+Alt+H.

## Поставить на новой машине

```bash
cd ~/dotfiles && stow -d packages -t ~ kitty scripts systemd kde
kbuildsycoca6                       # KDE увидит kitty-scratch.desktop
systemctl --user daemon-reload
systemctl --user enable --now kitty-save-session.timer
```

Если Ctrl+Alt+H не сработал сразу, выйти из системы и войти снова: KDE читает `kglobalshortcutsrc` при входе. Не помогло, назначить клавишу через Параметры системы.

## Проверить, что kitty вне сессии не сохраняется

```bash
ss -lx | grep kitty     # должны быть @kitty-main.sock-<pid> и @kitty-scratch.sock-<pid>
ss -lx | grep '@kitty-main\.sock' | awk '{print $5}' | head -1   # должен быть main
```
