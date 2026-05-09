# Micro Editor — Документация

## Быстрый старт

```
micro filename        # открыть файл
micro .               # открыть текущую директорию (не работает, используй F7 внутри)
```

---

## Горячие клавиши

### Базовые
| Клавиша         | Действие                    |
|-----------------|-----------------------------|
| Ctrl+S          | Сохранить                   |
| Ctrl+Q          | Выйти                       |
| Ctrl+Z          | Отменить                    |
| Ctrl+Y          | Повторить                   |
| Ctrl+A          | Выделить всё                |
| Ctrl+C          | Копировать                  |
| Ctrl+V          | Вставить                    |
| Ctrl+X          | Вырезать                    |
| Ctrl+D          | Дублировать строку          |
| Ctrl+K          | Удалить строку              |
| Ctrl+F          | Поиск                       |
| Ctrl+H          | Поиск и замена              |
| Ctrl+G          | Перейти к строке            |
| Ctrl+E          | Командная строка            |
| Ctrl+W          | Переключение между панелями |
| Shift+стрелки   | Выделение текста            |

### Плагины (кастомные)
| Клавиша   | Действие                    | Плагин      |
|-----------|-----------------------------|-------------|
| F7        | Дерево файлов (вкл/выкл)   | filemanager |
| Ctrl+P    | Быстрый поиск файлов (fzf) | fzf         |
| Alt+/     | Закомментировать строку     | comment     |
| F2        | Переименовать (LSP)         | lsp         |
| Alt+D     | Перейти к определению (LSP) | lsp         |
| Alt+R     | Найти ссылки (LSP)          | lsp         |
| Alt+H     | Подсказка/hover (LSP)       | lsp         |
| Alt+F     | Форматирование (LSP)        | lsp         |

### Дерево файлов (filemanager)
| Клавиша   | Действие              |
|-----------|-----------------------|
| F7        | Открыть/закрыть       |
| Tab       | Открыть файл          |
| стрелки   | Навигация             |
| Ctrl+W    | Перейти в дерево/код  |

### Командная строка (Ctrl+E)
```
open filename         # открыть файл
vsplit filename       # открыть файл в вертикальном сплите
hsplit filename       # открыть файл в горизонтальном сплите
set option value      # изменить настройку
tab filename          # открыть в новой вкладке
tabswitch N           # переключиться на вкладку N
```

---

## Установленные плагины

| Плагин       | Версия | Описание                              |
|--------------|--------|---------------------------------------|
| filemanager  | 3.5.1  | Дерево файлов (F7)                    |
| fzf          | 1.1.1  | Быстрый поиск файлов (Ctrl+P)        |
| lsp          | 0.6.2  | Автодополнение, go-to-definition      |
| bounce       | 2.0.0  | Прыжок к парной скобке               |
| autoclose    | встр.  | Автозакрытие скобок и кавычек        |
| comment      | встр.  | Комментирование кода (Alt+/)         |
| diff         | встр.  | Подсветка git-изменений              |
| ftoptions    | встр.  | Настройки по типу файла              |
| linter       | встр.  | Проверка ошибок                      |

### Управление плагинами
```
micro -plugin list                    # список плагинов
micro -plugin install имя             # установить
micro -plugin remove имя              # удалить
micro -plugin available               # доступные для установки
```

---

## LSP (автодополнение)

Для работы автодополнения нужны language servers:

| Язык        | Сервер                         | Установка                                |
|-------------|--------------------------------|------------------------------------------|
| Java        | jdtls                          | `paru -S jdtls`                          |
| Python      | pyright                        | `sudo pacman -S pyright`                 |
| Bash        | bash-language-server           | `sudo pacman -S bash-language-server`    |
| JS/TS       | typescript-language-server     | `sudo pacman -S typescript-language-server` |
| C/C++       | clangd                         | `sudo pacman -S clang`                   |
| Go          | gopls                          | `sudo pacman -S gopls`                   |
| Rust        | rust-analyzer                  | `sudo pacman -S rust-analyzer`           |
| C#          | omnisharp                      | `paru -S omnisharp-roslyn`               |

Статус: установлен только **jdtls** (Java).

---

## Темы оформления

Текущая тема: **darcula** (стиль IntelliJ IDEA)

Доступные темы:
- `darcula` — тёмная, стиль IntelliJ
- `catppuccin-macchiato` — тёмная, мягкие цвета
- `catppuccin-mocha` — тёмная, тёплые тона
- `catppuccin-frappe` — тёмная, приглушённая
- `catppuccin-latte` — светлая

Сменить тему: `Ctrl+E` → `set colorscheme имя_темы`

---

## Структура файлов

```
~/.config/micro/
├── settings.json          # Основные настройки
├── bindings.json          # Горячие клавиши
├── README.md              # Этот файл
├── colorschemes/          # Темы оформления
│   ├── darcula.micro      # Тема darcula (кастомная)
│   ├── catppuccin-macchiato.micro
│   ├── catppuccin-mocha.micro
│   ├── catppuccin-frappe.micro
│   └── catppuccin-latte.micro
├── syntax/                # Подсветка синтаксиса (143 языка)
│   ├── env.yaml           # .env файлы (кастомный)
│   ├── java.yaml
│   ├── javascript.yaml
│   ├── python3.yaml
│   ├── csharp.yaml
│   ├── sh.yaml            # Bash
│   ├── dockerfile.yaml
│   ├── json.yaml
│   └── ...                # и ещё 135 языков
├── plug/                  # Установленные плагины
│   ├── filemanager/
│   ├── fzf/
│   ├── lsp/
│   └── bounce/
├── buffers/               # Сохранённые позиции курсора
└── backups/               # Резервные копии файлов
```

---

## Полное удаление всех кастомных настроек

```fish
# Вернуть дефолтные настройки
echo '{}' > ~/.config/micro/settings.json
echo '{}' > ~/.config/micro/bindings.json

# Удалить кастомные файлы
rm ~/.config/micro/colorschemes/darcula.micro
rm ~/.config/micro/syntax/env.yaml
rm ~/.config/micro/README.md

# Удалить плагины
micro -plugin remove filemanager
micro -plugin remove fzf
micro -plugin remove lsp
micro -plugin remove bounce

# Удалить language servers
paru -R jdtls
```
