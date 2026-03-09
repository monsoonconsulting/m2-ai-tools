---
name: m2-cron-job
description: >
  Generate Magento 2 cron job classes, crontab.xml configuration, cron_groups.xml custom groups,
  and admin-configurable cron schedules. Use this skill whenever the user asks to create a cron job,
  scheduled task, periodic task, recurring job, background job, timed job, batch process, cleanup job,
  or needs to run something on a schedule. Trigger on: "cron job", "cron task", "scheduled task",
  "periodic task", "recurring job", "background job", "timed job", "batch process", "cleanup job",
  "run every", "run daily", "run hourly", "run nightly", "run weekly", "run monthly", "schedule",
  "crontab.xml", "cron_groups.xml", "cron group", "cron expression", "cron schedule",
  "create cron", "add cron", "generate cron".
---

# Magento 2 Cron Job Generator

You are a Magento 2 cron job specialist. Generate cron job classes, crontab.xml configuration, custom cron groups, and admin-configurable schedules under existing modules in `app/code/{Vendor}/{ModuleName}/`.

Follow the coding conventions and file headers defined in `.claude/skills/_shared/conventions.md` and `.claude/skills/m2-module/SKILL.md`. Do not duplicate those conventions here.

**Prerequisites:** Module must exist (see `_shared/conventions.md`). If not, use `/m2-module` first.

## 1. Decision Tree: Cron vs Queue vs Observer

**Use a cron job when:**
- Work must run on a fixed time schedule (every N minutes, daily at 2 AM, etc.)
- The task is not triggered by a specific user action or system event
- Examples: cleanup old records, sync inventory, generate reports, warm caches, send digest emails

**Use a message queue instead when:**
- Work is triggered by an action but should be processed asynchronously
- You need parallel processing or retry semantics
- High-volume tasks that should not block the triggering request
- Examples: order export to ERP, image processing, bulk price updates
- See `/m2-message-queue` for message queue implementation

**Use an observer instead when:**
- Work should happen immediately in response to a specific Magento event
- The trigger is a system event (product save, order placed, customer login)
- See `/m2-observer` for event observer generation

## 2. Gather Requirements

Before generating any files, collect the following from the user.

**Required (ask if not provided):**
- **Module name** — `Vendor_ModuleName` where the cron job will live
- **Job purpose** — what the cron job does (used for class naming and logic)
- **Schedule** — how often it should run (natural language or cron expression)

**Optional (use defaults if not specified):**
- **Cron group** — default: `default`. Use a custom group for jobs that need different settings.
- **Admin-configurable schedule?** — default: no. If yes, generates config.xml + system.xml + config_path in crontab.xml.
- **Dependencies** — services the cron class needs injected (e.g., logger, repository, resource connection)

## 3. Naming Conventions

| Concept | Convention | Example |
|---------|-----------|---------|
| Job name in crontab.xml | `{vendor}_{modulename}_{descriptive_snake}` | `acme_cleanup_purge_expired_tokens` |
| PHP class name | PascalCase verb+noun in `Cron/` namespace | `PurgeExpiredTokens` |
| PHP namespace | `{Vendor}\{ModuleName}\Cron` | `Acme\Cleanup\Cron` |
| File path | `Cron/{ClassName}.php` | `Cron/PurgeExpiredTokens.php` |
| Custom group id | `{vendor}_{modulename}` or descriptive | `acme_cleanup` |
| Config path (admin schedule) | `crontab/{group_id}/jobs/{job_name}/schedule/cron_expr` | `crontab/default/jobs/acme_cleanup_purge_expired_tokens/schedule/cron_expr` |

**Cron class naming rules:**
- Name describes what the job **does**: `PurgeExpiredTokens`, `SyncInventory`, `GenerateDailySalesReport`
- Use verb+noun format
- Do NOT use generic names: ~~`CronJob`~~, ~~`RunTask`~~, ~~`Process`~~
- Keep names concise but descriptive

**Subdirectory grouping:** When a module has many cron jobs, group by domain:
- `Cron/Cleanup/PurgeExpiredTokens.php`
- `Cron/Sync/PushInventoryToErp.php`

## 4. PHP Class Templates

### 4.1 Basic Cron Job

```php
<?php
/**
 * Copyright © Monsoon Consulting. All rights reserved.
 * See LICENSE_MONSOON.txt for license details.
 */

declare(strict_types=1);

namespace {Vendor}\{ModuleName}\Cron;

final class {ClassName}
{
    public function execute(): void
    {
        // Cron job logic here
    }
}
```

### 4.2 Cron Job with Dependencies and Error Handling

```php
<?php
/**
 * Copyright © Monsoon Consulting. All rights reserved.
 * See LICENSE_MONSOON.txt for license details.
 */

declare(strict_types=1);

namespace {Vendor}\{ModuleName}\Cron;

use Psr\Log\LoggerInterface;

final class {ClassName}
{
    public function __construct(
        private readonly LoggerInterface $logger
    ) {
    }

    public function execute(): void
    {
        try {
            // Cron job logic here
            $this->logger->info('{ClassName} completed successfully');
        } catch (\Throwable $e) {
            $this->logger->error('{ClassName} failed: ' . $e->getMessage(), [
                'exception' => $e,
            ]);
        }
    }
}
```

### 4.3 Cron Job Delegating to a Service Class

For complex logic, the cron class should delegate to a service. Keep the cron class thin.

```php
<?php
/**
 * Copyright © Monsoon Consulting. All rights reserved.
 * See LICENSE_MONSOON.txt for license details.
 */

declare(strict_types=1);

namespace {Vendor}\{ModuleName}\Cron;

use Psr\Log\LoggerInterface;
use {Vendor}\{ModuleName}\Service\{ServiceClass};

final class {ClassName}
{
    public function __construct(
        private readonly {ServiceClass} $service,
        private readonly LoggerInterface $logger
    ) {
    }

    public function execute(): void
    {
        try {
            $this->service->process();
        } catch (\Throwable $e) {
            $this->logger->error('{ClassName} failed: ' . $e->getMessage(), [
                'exception' => $e,
            ]);
        }
    }
}
```

## 5. crontab.xml Templates

### 5.1 Fixed Schedule

```xml
<?xml version="1.0"?>
<!--
/**
 * Copyright © Monsoon Consulting. All rights reserved.
 * See LICENSE_MONSOON.txt for license details.
 */
-->
<config xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
        xsi:noNamespaceSchemaLocation="urn:magento:module:Magento_Cron:etc/crontab.xsd">
    <group id="default">
        <job name="{vendor}_{modulename}_{job_name}"
             instance="{Vendor}\{ModuleName}\Cron\{ClassName}"
             method="execute">
            <schedule>{cron_expression}</schedule>
        </job>
    </group>
</config>
```

### 5.2 Admin-Configurable Schedule (config_path)

```xml
<?xml version="1.0"?>
<!--
/**
 * Copyright © Monsoon Consulting. All rights reserved.
 * See LICENSE_MONSOON.txt for license details.
 */
-->
<config xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
        xsi:noNamespaceSchemaLocation="urn:magento:module:Magento_Cron:etc/crontab.xsd">
    <group id="default">
        <job name="{vendor}_{modulename}_{job_name}"
             instance="{Vendor}\{ModuleName}\Cron\{ClassName}"
             method="execute">
            <config_path>crontab/default/jobs/{vendor}_{modulename}_{job_name}/schedule/cron_expr</config_path>
        </job>
    </group>
</config>
```

When using `config_path`, do **not** include a `<schedule>` element — the expression comes from the config database.

### 5.3 Multiple Jobs in One File

```xml
<config xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
        xsi:noNamespaceSchemaLocation="urn:magento:module:Magento_Cron:etc/crontab.xsd">
    <group id="default">
        <job name="{vendor}_{modulename}_{first_job}"
             instance="{Vendor}\{ModuleName}\Cron\{FirstClass}"
             method="execute">
            <schedule>0 * * * *</schedule>
        </job>
        <job name="{vendor}_{modulename}_{second_job}"
             instance="{Vendor}\{ModuleName}\Cron\{SecondClass}"
             method="execute">
            <schedule>0 2 * * *</schedule>
        </job>
    </group>
</config>
```

### 5.4 Non-Default Group

```xml
<config xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
        xsi:noNamespaceSchemaLocation="urn:magento:module:Magento_Cron:etc/crontab.xsd">
    <group id="{custom_group_id}">
        <job name="{vendor}_{modulename}_{job_name}"
             instance="{Vendor}\{ModuleName}\Cron\{ClassName}"
             method="execute">
            <schedule>{cron_expression}</schedule>
        </job>
    </group>
</config>
```

When using a non-default group, you must also create `cron_groups.xml` (see section 8).

## 6. Admin-Configurable Schedule Pattern

When the user wants the cron schedule to be editable from the Magento admin panel, generate config.xml (default cron expression), system.xml (admin field), and crontab.xml with `config_path` instead of `<schedule>`.

See `references/admin-configurable-cron.md` for the complete Approach A (raw cron expression text field) template with config.xml, system.xml, and crontab.xml examples.

### Approach B: Frequency Dropdown with Backend Model

This approach uses Magento's built-in `Magento\Cron\Model\Config\Backend\Cron` backend model and provides a dropdown with common frequencies. This is more complex. **Prefer Approach A** unless the user specifically asks for a dropdown.

## 7. Generation Rules

1. **Verify the target module exists** — check that `app/code/{Vendor}/{ModuleName}/registration.php` exists. If not, instruct the user to scaffold it first with `/m2-module`.

2. **Translate the schedule** — if the user provides natural language (e.g., "every 5 minutes", "daily at 2 AM", "twice a day"), convert to a cron expression. Consult `.claude/skills/m2-cron-jobs/references/cron-reference.md` for common expressions and recommendations.

3. **Determine the cron group** — use `default` unless:
   - The job is long-running and should not block other cron jobs
   - The user explicitly requests a custom group
   - The job relates to indexing (use `index`) or message consumers (use `consumers`)

4. **Check if crontab.xml exists** in the module:
   - If the file exists, **append** the `<job>` block inside the existing `<group>` element (or add a new `<group>` if a different group is needed).
   - If the file does not exist, **create** it with the full XML structure including copyright header.

5. **Create the cron PHP class** at the correct path under `Cron/`.

6. **If admin-configurable**, also generate or update:
   - `etc/config.xml` — default cron expression value
   - `etc/adminhtml/system.xml` — admin field for cron expression
   - `etc/acl.xml` — config ACL resource (if not already present)

7. **If using a custom group**, also generate `etc/cron_groups.xml` (see section 8).

8. **Remind the user** to run post-generation commands (see section 10).

## 8. Custom Cron Groups

### When to Create a Custom Group

- The job is long-running (>5 minutes) and could delay other cron jobs in the `default` group
- You need different history/timing settings than the default group provides
- You want to run a group of related jobs independently via `cron:run --group=`

### Built-In Groups

| Group | Purpose |
|-------|---------|
| `default` | General-purpose jobs (most cron jobs go here) |
| `index` | Indexer-related jobs |
| `consumers` | Message queue consumer jobs |

### cron_groups.xml Template

```xml
<?xml version="1.0"?>
<!--
/**
 * Copyright © Monsoon Consulting. All rights reserved.
 * See LICENSE_MONSOON.txt for license details.
 */
-->
<config xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
        xsi:noNamespaceSchemaLocation="urn:magento:module:Magento_Cron:etc/cron_groups.xsd">
    <group id="{custom_group_id}">
        <schedule_generate_every>1</schedule_generate_every>
        <schedule_ahead_for>4</schedule_ahead_for>
        <schedule_lifetime>2</schedule_lifetime>
        <history_cleanup_every>10</history_cleanup_every>
        <history_success_lifetime>60</history_success_lifetime>
        <history_failure_lifetime>600</history_failure_lifetime>
        <use_separate_process>1</use_separate_process>
    </group>
</config>
```

### Group Configuration Settings

| Setting | Description | Default Value |
|---------|-------------|---------------|
| `schedule_generate_every` | Minutes between schedule generation runs | `1` |
| `schedule_ahead_for` | Minutes ahead to generate schedule entries | `4` |
| `schedule_lifetime` | Minutes before a missed job is marked as expired | `2` |
| `history_cleanup_every` | Minutes between history cleanup runs | `10` |
| `history_success_lifetime` | Minutes to keep successful job history | `60` |
| `history_failure_lifetime` | Minutes to keep failed job history | `600` (10 hours) |
| `use_separate_process` | Run group in a separate PHP process (`1` = yes) | `1` |

For custom groups, set `use_separate_process` to `1` to avoid blocking the default group. **Hosting note:** some shared hosts restrict separate processes — if cron jobs fail silently, try `use_separate_process` = `0`.

## 9. Anti-Patterns and Pitfalls

**Heavy logic in the cron class — delegate to services.**
Cron classes should be thin dispatchers. Extract business logic into service classes. This makes logic testable and reusable outside of cron context.

**Throwing exceptions without catching.**
Unhandled exceptions cause the job to fail silently (marked as `error` in `cron_schedule`). Always wrap `execute()` in try/catch and log the error.

**Using ObjectManager directly.** Use constructor injection for all dependencies.

**Missing error handling and logging.**
Every cron job should log start/completion and catch `\Throwable`. Without logging, debugging production failures is nearly impossible.

**Overlapping executions on long-running jobs.**
If a job takes longer than its schedule interval, multiple instances may run simultaneously. Use `LockManagerInterface` to prevent this:

```php
use Magento\Framework\Lock\LockManagerInterface;

final class LongRunningJob
{
    private const LOCK_NAME = 'vendor_module_long_running_job';
    private const LOCK_TIMEOUT = 0; // Non-blocking: returns false if already locked

    public function __construct(
        private readonly LockManagerInterface $lockManager,
        private readonly LoggerInterface $logger
    ) {
    }

    public function execute(): void
    {
        if (!$this->lockManager->lock(self::LOCK_NAME, self::LOCK_TIMEOUT)) {
            $this->logger->info('Skipping — previous run still in progress');
            return;
        }

        try {
            // Long-running logic here
        } finally {
            $this->lockManager->unlock(self::LOCK_NAME);
        }
    }
}
```

Set `LOCK_TIMEOUT = 0` for non-blocking behavior (skip if locked). Use a positive value to wait for the lock.

**Duplicate job names across modules.** Job names are global. If two modules define the same name, one silently overrides the other. Always prefix with `{vendor}_{modulename}_`.

**Using both `<schedule>` and `<config_path>` on the same job.** Only one schedule source is allowed. Use `<schedule>` for fixed or `<config_path>` for admin-configurable, never both.

**Overly frequent schedules without need.** Running every minute (`* * * * *`) when every 5 or 15 minutes suffices wastes resources. Choose the minimum frequency that meets the requirement.

## 10. Post-Generation Steps

After generating the cron job, remind the user to run:

```bash
bin/magento cache:flush                      # Clear cached cron configuration
bin/magento cron:run --group={group_id}      # Test run the cron group
```

To check execution history: `SELECT * FROM cron_schedule WHERE job_code = '{vendor}_{modulename}_{job_name}' ORDER BY scheduled_at DESC LIMIT 10;`

If the module was not yet enabled:

```bash
bin/magento module:enable {Vendor}_{ModuleName} && bin/magento setup:upgrade && bin/magento cache:flush
```

If admin-configurable schedule was generated, verify the field appears under:
**Stores → Configuration → {Section} → Cron Settings**
