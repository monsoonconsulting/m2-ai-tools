# Logging Patterns

Reference for custom logging configuration used by `/m2-di-config`.

## Custom Log Handler Template

```php
<?php
/**
 * Copyright © Monsoon Consulting. All rights reserved.
 * See LICENSE_MONSOON.txt for license details.
 */

declare(strict_types=1);

namespace {Vendor}\{ModuleName}\Logger;

use Magento\Framework\Logger\Handler\Base;
use Monolog\Logger;

final class Handler extends Base
{
    protected $loggerType = Logger::DEBUG;
    protected $fileName = '/var/log/{log_file_name}';
}
```

Change `$loggerType` to set the minimum level: `Logger::DEBUG`, `Logger::INFO`, `Logger::WARNING`, `Logger::ERROR`, `Logger::CRITICAL`.

### Naming conventions

| Concept | Convention | Example |
|---------|-----------|---------|
| Log file | `var/log/{vendor}_{module}.log` | `var/log/acme_shipping.log` |
| Handler class | `Logger\Handler` | `Logger\Handler` |
| Logger virtual type | `{Vendor}{ModuleName}Logger` | `AcmeShippingLogger` |
| Handler virtual type | `{Vendor}{ModuleName}LogHandler` | `AcmeShippingLogHandler` |

## di.xml — Virtual Type Logger

```xml
<!-- Custom log handler -->
<type name="{Vendor}\{ModuleName}\Logger\Handler">
    <arguments>
        <argument name="filesystem" xsi:type="object">Magento\Framework\Filesystem\Driver\File</argument>
    </arguments>
</type>

<!-- Virtual type logger that uses our handler -->
<virtualType name="{Vendor}{ModuleName}Logger" type="Magento\Framework\Logger\Monolog">
    <arguments>
        <argument name="name" xsi:type="string">{vendor}_{module}</argument>
        <argument name="handlers" xsi:type="array">
            <item name="system" xsi:type="object">{Vendor}\{ModuleName}\Logger\Handler</item>
        </argument>
    </arguments>
</virtualType>

<!-- Inject virtual logger into classes that need it -->
<type name="{Vendor}\{ModuleName}\Service\{ServiceClass}">
    <arguments>
        <argument name="logger" xsi:type="object">{Vendor}{ModuleName}Logger</argument>
    </arguments>
</type>
```

## JSON Log Formatter

For structured logging (easier parsing by log aggregators):

```xml
<virtualType name="{Vendor}{ModuleName}JsonFormatter" type="Monolog\Formatter\JsonFormatter"/>

<type name="{Vendor}\{ModuleName}\Logger\Handler">
    <arguments>
        <argument name="filesystem" xsi:type="object">Magento\Framework\Filesystem\Driver\File</argument>
        <argument name="formatter" xsi:type="object">{Vendor}{ModuleName}JsonFormatter</argument>
    </arguments>
</type>
```

## Service Usage Pattern

```php
<?php
declare(strict_types=1);

namespace {Vendor}\{ModuleName}\Service;

use Psr\Log\LoggerInterface;

final class {ServiceClass}
{
    public function __construct(
        private readonly LoggerInterface $logger
    ) {
    }

    public function process(): void
    {
        $this->logger->info('Processing started');

        try {
            $this->logger->debug('Intermediate step', ['key' => 'value']);
            $this->logger->info('Processing completed successfully');
        } catch (\Throwable $e) {
            $this->logger->error('Processing failed: ' . $e->getMessage(), [
                'exception' => $e,
            ]);
            throw $e;
        }
    }
}
```

**Best practice:** Use structured context arrays instead of string concatenation:
- Good: `$this->logger->error('Failed', ['order_id' => $id, 'exception' => $e])`
- Bad: `$this->logger->error('Failed for order ' . $id . ': ' . $e->getMessage())`

## Log Levels Reference (PSR-3 / Monolog)

| Level | Monolog Constant | Use For |
|-------|-----------------|---------|
| `DEBUG` | `Logger::DEBUG` (100) | Detailed debug info (development only) |
| `INFO` | `Logger::INFO` (200) | Normal operations (start/complete, counts) |
| `NOTICE` | `Logger::NOTICE` (250) | Normal but significant events |
| `WARNING` | `Logger::WARNING` (300) | Unexpected but non-breaking issues |
| `ERROR` | `Logger::ERROR` (400) | Runtime errors that need attention |
| `CRITICAL` | `Logger::CRITICAL` (500) | Critical conditions (component failure) |
| `ALERT` | `Logger::ALERT` (550) | Action must be taken immediately |
| `EMERGENCY` | `Logger::EMERGENCY` (600) | System is unusable |

## Built-In Log Files

| File | Contents |
|------|---------|
| `var/log/system.log` | General system messages (INFO+) |
| `var/log/debug.log` | Debug messages (only in developer mode) |
| `var/log/exception.log` | Uncaught exceptions with stack traces |
| `var/log/support_report.log` | Support reports |
| `var/report/` | Error reports (referenced by error page IDs) |

**Log rotation:** Magento does not rotate logs automatically. Configure `logrotate` on the server for `var/log/*.log`. Recommended: daily rotation, 7-day retention, compress old files.

**Path convention:** Custom log files always go in `var/log/`. The `$fileName` property uses a path relative to Magento root (e.g., `/var/log/acme_shipping.log`).

## Debug Tips

**Enable developer mode:**
```bash
bin/magento deploy:mode:set developer
```

**Enable template hints:**
```bash
bin/magento config:set dev/debug/template_hints_storefront 1
bin/magento config:set dev/debug/template_hints_admin 1
bin/magento cache:flush
```

**Enable query logging:**
```bash
bin/magento dev:query-log:enable
# Logs to var/debug/db.log
bin/magento dev:query-log:disable
```

**Enable profiler:**
```bash
bin/magento dev:profiler:enable html
# or
bin/magento dev:profiler:enable csvfile
```

## Anti-Patterns

**Logging sensitive data.** Never log passwords, credit card numbers, API secrets, or PII.

**Using `ObjectManager` to get a logger.** Always inject `Psr\Log\LoggerInterface` via constructor.

**Excessive debug logging in production.** Set `$loggerType = Logger::INFO` or higher for production.

**Creating multiple handler classes per module.** One handler per log file is sufficient. Use log levels to differentiate messages.
