---
name: m2-cli-command
description: >
  Generate custom Magento 2 CLI commands for bin/magento using Symfony Console.
  Use this skill whenever the user asks to create a CLI command, console command,
  bin/magento command, or terminal command. Handles arguments, options, table
  output, progress bars, and di.xml registration.
  Trigger on: "CLI command", "console command", "bin/magento command",
  "terminal command", "custom command", "create command", "add command",
  "command class", "Symfony Console", "InputInterface", "OutputInterface",
  "ProgressBar", "Table output", "CommandList", "console", "terminal".
---

# Magento 2 CLI Command Generator

You are a Magento 2 CLI command specialist. Generate custom `bin/magento` commands using Symfony Console under existing modules in `app/code/{Vendor}/{ModuleName}/`.

Follow the coding conventions and file headers defined in `.claude/skills/_shared/conventions.md` and `.claude/skills/m2-module/SKILL.md`. Do not duplicate those conventions here.

**Prerequisites:** Module must exist (see `_shared/conventions.md`). If not, use `/m2-module` first.

## 1. Decision Tree

**Use a CLI command when:**
- Task is run manually by developers/admins on demand
- One-time or ad-hoc operations (imports, exports, data fixes)
- Debugging and diagnostic tools
- Operations that need real-time output or progress bars

**Use a cron job instead when:**
- Task must run on a schedule — see `/m2-cron-job`

**Use a message queue instead when:**
- Task is triggered by system events asynchronously — see `/m2-message-queue`

## 2. Gather Requirements

Before generating any files, collect the following from the user.

**Required (ask if not provided):**
- **Module name** — `Vendor_ModuleName`
- **Command name** — colon-separated (e.g., `acme:inventory:sync`)
- **Command purpose** — what the command does (used for class naming and description)

**Optional (use defaults if not specified):**
- **Arguments** — positional params (name, required/optional, description)
- **Options** — flags (name, shortcut, value type, description, default)
- **Output style** — plain, table, or progress bar

## 3. Naming Conventions

| Concept | Convention | Example |
|---------|-----------|---------|
| Command name | `{vendor}:{action}` or `{vendor}:{entity}:{action}` | `acme:inventory:sync` |
| PHP class name | PascalCase verb+noun + `Command` suffix | `SyncInventoryCommand` |
| PHP namespace | `{Vendor}\{ModuleName}\Console\Command` | `Acme\Inventory\Console\Command` |
| File path | `Console/Command/{ClassName}.php` | `Console/Command/SyncInventoryCommand.php` |

## 4. Templates

### 4.1 Basic Command — `Console/Command/{ClassName}.php`

```php
<?php
/**
 * Copyright © Monsoon Consulting. All rights reserved.
 * See LICENSE_MONSOON.txt for license details.
 */

declare(strict_types=1);

namespace {Vendor}\{ModuleName}\Console\Command;

use Symfony\Component\Console\Command\Command;
use Symfony\Component\Console\Input\InputInterface;
use Symfony\Component\Console\Output\OutputInterface;

final class {ClassName} extends Command
{
    protected function configure(): void
    {
        $this->setName('{command:name}');
        $this->setDescription('{Command description}');
    }

    protected function execute(InputInterface $input, OutputInterface $output): int
    {
        $output->writeln('<info>Starting {description}...</info>');

        // Command logic here

        $output->writeln('<info>Done.</info>');

        return Command::SUCCESS;
    }
}
```

### 4.2 Command with Arguments and Options

```php
<?php
// Standard file header — see _shared/conventions.md
declare(strict_types=1);

namespace {Vendor}\{ModuleName}\Console\Command;

use Symfony\Component\Console\Command\Command;
use Symfony\Component\Console\Input\InputArgument;
use Symfony\Component\Console\Input\InputInterface;
use Symfony\Component\Console\Input\InputOption;
use Symfony\Component\Console\Output\OutputInterface;

final class {ClassName} extends Command
{
    private const ARG_ENTITY_ID = 'entity-id';
    private const OPT_DRY_RUN = 'dry-run';
    private const OPT_LIMIT = 'limit';

    protected function configure(): void
    {
        $this->setName('{command:name}');
        $this->setDescription('{Command description}');
        $this->addArgument(
            self::ARG_ENTITY_ID,
            InputArgument::REQUIRED,
            'The entity ID to process'
        );
        $this->addOption(
            self::OPT_DRY_RUN,
            'd',
            InputOption::VALUE_NONE,
            'Run without making changes'
        );
        $this->addOption(
            self::OPT_LIMIT,
            'l',
            InputOption::VALUE_REQUIRED,
            'Maximum number of items to process',
            '100'
        );
    }

    protected function execute(InputInterface $input, OutputInterface $output): int
    {
        $entityId = (int) $input->getArgument(self::ARG_ENTITY_ID);
        $dryRun = (bool) $input->getOption(self::OPT_DRY_RUN);
        $limit = (int) $input->getOption(self::OPT_LIMIT);

        if ($dryRun) {
            $output->writeln('<comment>Dry-run mode — no changes will be made.</comment>');
        }

        // Command logic here

        return Command::SUCCESS;
    }
}
```

### 4.3 Command with Dependencies (Service Delegation)

```php
<?php
// Standard file header — see _shared/conventions.md
declare(strict_types=1);

namespace {Vendor}\{ModuleName}\Console\Command;

use Psr\Log\LoggerInterface;
use Symfony\Component\Console\Command\Command;
use Symfony\Component\Console\Input\InputInterface;
use Symfony\Component\Console\Output\OutputInterface;
use {Vendor}\{ModuleName}\Service\{ServiceClass};

final class {ClassName} extends Command
{
    public function __construct(
        private readonly {ServiceClass} $service,
        private readonly LoggerInterface $logger
    ) {
        parent::__construct();
    }

    protected function configure(): void
    {
        $this->setName('{command:name}');
        $this->setDescription('{Command description}');
    }

    protected function execute(InputInterface $input, OutputInterface $output): int
    {
        try {
            $this->service->process();
            $output->writeln('<info>Completed successfully.</info>');

            return Command::SUCCESS;
        } catch (\Throwable $e) {
            $this->logger->error('Command failed: ' . $e->getMessage(), ['exception' => $e]);
            $output->writeln('<error>' . $e->getMessage() . '</error>');

            return Command::FAILURE;
        }
    }
}
```

### 4.4 Table Output Helper

```php
    protected function execute(InputInterface $input, OutputInterface $output): int
    {
        $table = new \Symfony\Component\Console\Helper\Table($output);
        $table->setHeaders(['ID', 'Name', 'Status']);
        $table->addRows([
            ['1', 'Item One', '<info>Active</info>'],
            ['2', 'Item Two', '<error>Inactive</error>'],
        ]);
        $table->render();

        return Command::SUCCESS;
    }
```

### 4.5 Progress Bar Helper

```php
    protected function execute(InputInterface $input, OutputInterface $output): int
    {
        $items = $this->getItems();
        $progressBar = new \Symfony\Component\Console\Helper\ProgressBar($output, count($items));
        $progressBar->start();

        foreach ($items as $item) {
            $this->processItem($item);
            $progressBar->advance();
        }

        $progressBar->finish();
        $output->writeln(''); // Newline after progress bar

        return Command::SUCCESS;
    }
```

### 4.6 di.xml — Register Command

```xml
<?xml version="1.0"?>
<!--
/**
 * Copyright © Monsoon Consulting. All rights reserved.
 * See LICENSE_MONSOON.txt for license details.
 */
-->
<config xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
        xsi:noNamespaceSchemaLocation="urn:magento:framework:ObjectManager/etc/config.xsd">
    <type name="Magento\Framework\Console\CommandListInterface">
        <arguments>
            <argument name="commands" xsi:type="array">
                <item name="{vendor}_{modulename}_{command_snake}" xsi:type="object">{Vendor}\{ModuleName}\Console\Command\{ClassName}</item>
            </argument>
        </arguments>
    </type>
</config>
```

## 5. Output Formatting Reference

| Tag | Renders As | Use For |
|-----|-----------|---------|
| `<info>text</info>` | Green | Success messages |
| `<comment>text</comment>` | Yellow | Warnings, notes |
| `<error>text</error>` | White on red | Errors |
| `<question>text</question>` | Black on cyan | Prompts |
| Plain text | Default color | Normal output |

## 6. Return Codes

| Constant | Value | Meaning |
|----------|-------|---------|
| `Command::SUCCESS` | `0` | Command succeeded |
| `Command::FAILURE` | `1` | Command failed |
| `Command::INVALID` | `2` | Invalid input/usage |

## 7. Area Code Pattern (Common Gotcha)

Commands that use Magento services requiring an area (e.g., email sending, store emulation) must set the area code:

```php
use Magento\Framework\App\State;

public function __construct(
    private readonly State $state
) {
    parent::__construct();
}

protected function execute(InputInterface $input, OutputInterface $output): int
{
    $this->state->setAreaCode(\Magento\Framework\App\Area::AREA_ADMINHTML);
    // Now safe to use services that require an area
    return Command::SUCCESS;
}
```

Without this, you get: "Area code is not set". Wrap in try/catch if the area might already be set.

## 8. Interactive Input (QuestionHelper)

```php
use Symfony\Component\Console\Question\ConfirmationQuestion;

protected function execute(InputInterface $input, OutputInterface $output): int
{
    $helper = $this->getHelper('question');
    $question = new ConfirmationQuestion('Continue? (y/N) ', false);

    if (!$helper->ask($input, $output, $question)) {
        $output->writeln('Aborted.');
        return Command::SUCCESS;
    }

    // proceed...
    return Command::SUCCESS;
}
```

## 9. Generation Rules

Follow this sequence when generating a CLI command:

1. **Verify the module exists** — check `app/code/{Vendor}/{ModuleName}/registration.php`. If missing, instruct user to run `/m2-module`.

2. **Create the command class** in `Console/Command/`.

3. **Register the command in di.xml** — add the command to `CommandListInterface` arguments. Create or append to existing di.xml.

4. **Remind the user** to run post-generation commands.

## 10. Anti-Patterns

**Forgetting `parent::__construct()`.**
When the command has injected dependencies, you MUST call `parent::__construct()` in the constructor body. Without it, Symfony Console throws a LogicException.

**Not registering in di.xml.**
The command must be registered under `CommandListInterface` in di.xml. Without it, the command won't appear in `bin/magento list`.

**Using ObjectManager directly.**
All dependencies must be injected via constructor. Never call `ObjectManager::getInstance()`.

**Putting business logic in the command class.**
Commands should delegate to service classes. Keep them thin — input parsing and output formatting only. This makes the logic testable and reusable from cron jobs or API.

**Not handling exceptions.**
Unhandled exceptions produce ugly stack traces. Wrap in try/catch, log the error, write a user-friendly `<error>` message, and return `Command::FAILURE`.

**Using `exit()` or `die()`.**
Always return an integer exit code from `execute()`. Never call `exit()` — it prevents proper cleanup.

## 11. Post-Generation Steps

Follow `.claude/skills/_shared/post-generation.md` for: di.xml, new module enable.

**Verification:** `bin/magento {command:name} --help` — verify command is registered and shows usage info.
