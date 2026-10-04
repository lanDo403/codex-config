# Моя конфигурация Codex

Личные инструкции и выбранные skills для работы с FPGA, SystemVerilog и
инфраструктурой автоматизированной торговли. Собственные Markdown-файлы хранятся
в этом репозитории; внешние skills, плагины и инструменты подключаются из своих
исходных проектов.

## Содержимое

```text
Codex_config/
├── .gitattributes
├── README.md
├── install.sh
├── install.ps1
├── tests/
│   └── test_install.py
├── codex/
│   ├── AGENTS.md
│   └── RTK.md
└── skills/
    ├── fpga-workflow/
    │   └── SKILL.md
    ├── systemverilog/
    │   └── SKILL.md
    └── trading-infrastructure-guide/
        ├── SKILL.md
        └── references/
            ├── system-design.md
            ├── market-data.md
            ├── execution-risk.md
            ├── simulation-validation.md
            ├── operations.md
            └── roadmap.md
```

## Личные skills

| Skill | Назначение |
| --- | --- |
| [fpga-workflow](skills/fpga-workflow/SKILL.md) | Разработка и отладка RTL, интерфейсов, clock/reset, constraints и timing. |
| [systemverilog](skills/systemverilog/SKILL.md) | Правила разработки и проверки SystemVerilog для FPGA и ASIC. |
| [trading-infrastructure-guide](skills/trading-infrastructure-guide/SKILL.md) | Market data, исполнение ордеров, риск, replay, наблюдаемость и эксплуатация торговых систем. |

Для `systemverilog` локальный установочный lock указывает исходный проект
[mindrally/skills](https://github.com/mindrally/skills). Эта ссылка сохраняет
сведения о происхождении установленного skill.

У `trading-infrastructure-guide` основной файл использует материалы из
`references/`; при установке нужно сохранить весь каталог.

## Внешние компоненты

| Тип | Компонент | Использование |
| --- | --- | --- |
| Skill и hook | [Z.A.E.B.A.L.](https://github.com/howdeploy/Z.A.E.B.A.L) (`zaebal`) | Аудит ошибок агента; подключается вместе с hook по инструкции исходного проекта. |
| Skill | [Pohuy](https://github.com/howdeploy/pohuy) | Режим общения с русским матом; код, коммиты и документация сохраняют обычный стиль. |
| Skill | [Playwright](https://github.com/openai/skills/tree/main/skills/.curated/playwright) | Управление браузером через Playwright CLI: навигация, формы, snapshots и screenshots. |
| MCP-сервер | [Playwright MCP](https://github.com/microsoft/playwright-mcp) | Управление браузером через MCP-инструменты. |
| Плагин | [Ponytail](https://github.com/DietrichGebert/ponytail) | Минимальные решения в коде и поиск лишней сложности. |
| Инструмент | [ObsidianLLMWiki](https://github.com/lanDo403/ObsidianLLMWiki) | Хранение и поиск проверенных межсессионных знаний; подключается через `obsidian-llmwiki`. |
| Инструмент | [RTK](https://github.com/rtk-ai/rtk) | Сжатие вывода команд. Используемые инструкции находятся в [RTK.md](codex/RTK.md). |

## Использование

Установщики предназначены для Codex: они переносят один выбранный skill или
весь каталог `skills/` в `~/.agents/skills/`, а также глобальные `AGENTS.md`
и `RTK.md` в `~/.codex/`. Правила переносятся при любом выборе skill.
Каталог глобальных правил учитывает `CODEX_HOME`, если он задан.

Linux (Bash):

```bash
bash ./install.sh all
bash ./install.sh fpga-workflow
```

Windows (PowerShell 5.1+, Bash и WSL не требуются):

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\install.ps1 all
powershell -NoProfile -ExecutionPolicy Bypass -File .\install.ps1 fpga-workflow
```

Для другого каталога установки используйте `--skills-dir PATH` в Bash
или `-SkillsDir PATH` в PowerShell; для глобальных правил — `--codex-dir PATH`
или `-CodexDir PATH`. Существующие выбранные skills сохраняются в соседний
каталог `skill-backups/`, глобальные правила — в `config-backups/` внутри
каталога Codex. Резервные копии получают уникальные имена. Затем выбранные
skills и правила заменяются версиями из репозитория.
Остальные установленные skills сохраняются.
Если новые skills не появились, перезапустите Codex.

Ссылка на `RTK.md` в устанавливаемом `AGENTS.md` подставляется автоматически.
В Linux путь к Python-окружению Wiki адаптируется на `.venv/bin/python`.
Чтобы подставить остальные пути, передайте существующие каталоги Vault
и инструментов ObsidianLLMWiki:

```bash
bash ./install.sh all --vault-path "/path/to/vault" --wiki-tools-path "/path/to/ObsidianLLMWiki"
```

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\install.ps1 all -VaultPath "C:\path\to\vault" -WikiToolsPath "C:\path\to\ObsidianLLMWiki"
```

Если пути Wiki не заданы, соответствующие шаблоны остаются в `AGENTS.md`,
а установщик сообщает об этом. Их можно заполнить вручную.
Расположение skills описано в [документации OpenAI](https://learn.chatgpt.com/docs/build-skills).

Внешние компоненты из таблицы требуют отдельной установки по инструкциям
исходных проектов. Для Z.A.E.B.A.L. требуется также регистрация hook.
Параметры Wiki указывают пути к уже существующим каталогам; перенос содержимого
Vault и установка инструментов выполняются отдельно.

## Playwright

Playwright skill использует CLI, а Playwright MCP предоставляет отдельный набор
MCP-инструментов. Skill устанавливается из исходного проекта вместе с
`scripts/playwright_cli.sh` и `references/`.

Для Playwright MCP нужны Node.js 18+ и `npx`. Добавьте следующий блок в
`~/.codex/config.toml`, объединив его с существующей секцией, если она уже есть:

```toml
[mcp_servers.playwright]
command = "npx"
args = ["@playwright/mcp@latest"]
enabled = false
```

В этой конфигурации MCP выключен. Чтобы включить его, замените `enabled = false`
на `enabled = true`. Другие параметры описаны в
[документации Playwright MCP](https://github.com/microsoft/playwright-mcp).

## О копии глобальных правил

[codex/AGENTS.md](codex/AGENTS.md) содержит копию глобальных правил с заменой
личных путей на `<ТВОЙ ПУТЬ>` и `<ТВОЙ ПУТЬ ДО VAULT>`.
[codex/RTK.md](codex/RTK.md) скопирован без изменений.
При установке подставьте пути своей системы.

## Проверка установщиков

```text
python tests/test_install.py
```

Проверка запускает доступные Bash и PowerShell в отдельных временных каталогах:
установка одного skill и всех skills, глобальных правил, подстановка путей,
повторная установка, сохранение резервных копий и отклонение неверных аргументов.
Рабочие настройки Codex при проверке не изменяются.
