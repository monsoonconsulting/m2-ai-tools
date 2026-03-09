---
name: m2-message-queue
description: >
  Generate Magento 2 message queue configuration and consumer/publisher classes
  including communication.xml, queue_consumer.xml, queue_publisher.xml,
  queue_topology.xml, consumer handlers, and publisher usage patterns.
  Use this skill whenever the user asks to create an async job, message queue,
  consumer, publisher, or needs RabbitMQ/MySQL queue integration.
  Trigger on: "message queue", "async job", "consumer", "publisher", "RabbitMQ",
  "AMQP", "queue", "async processing", "background job", "communication.xml",
  "queue_consumer.xml", "queue_publisher.xml", "queue_topology.xml",
  "asynchronous", "deferred processing", "event-driven", "pub/sub".
---

# Magento 2 Message Queue Generator

You are a Magento 2 message queue specialist. Generate queue configuration (communication.xml, queue_topology.xml, queue_consumer.xml, queue_publisher.xml) and consumer/publisher classes under existing modules in `app/code/{Vendor}/{ModuleName}/`.

Follow the coding conventions and file headers defined in `.claude/skills/_shared/conventions.md` and `.claude/skills/m2-module/SKILL.md`. Do not duplicate those conventions here.

**Prerequisites:** Module must exist (see `_shared/conventions.md`). If not, use `/m2-module` first.

## 1. Decision Tree

**Use a message queue when:**
- Work is triggered by an action but should run asynchronously
- You need retry semantics or guaranteed delivery
- High-volume tasks that should not block the HTTP request
- Event-driven processing where trigger and handler are decoupled

**Use a cron job instead when:**
- Work must run on a fixed time schedule — see `/m2-cron-jobs`

**Use an observer instead when:**
- Work must happen synchronously in the same request — see `/m2-observer`

**Boundary:** queues are for event-triggered async processing; cron is for time-scheduled tasks.

See `.claude/skills/m2-message-queue/references/queue-adapters.md` for MySQL vs AMQP adapter comparison.

## 2. Gather Requirements

Before generating any files, collect the following from the user.

**Required (ask if not provided):**
- **Module name** — `Vendor_ModuleName`
- **Topic name** — what event/message this represents
- **Message data** — what data the message carries (simple string, or structured data)
- **Consumer action** — what the consumer does with the message

**Optional (use defaults if not specified):**
- **Queue adapter** — default: `db` (MySQL). Use `amqp` for RabbitMQ.
- **Max messages per invocation** — default: `1000`
- **Complex message object?** — default: no (use string). If yes, generates interface + implementation.

## 3. Naming Conventions

| Concept | Convention | Example |
|---------|-----------|---------|
| Topic name | `{vendor}.{module}.{action}.{entity}` | `acme.order.export.completed` |
| Queue name | same as topic name | `acme.order.export.completed` |
| Exchange name | `{vendor}.{module}` | `acme.order` |
| Consumer name (XML) | `{vendor}{Module}{Action}{Entity}Consumer` | `acmeOrderExportCompletedConsumer` |
| Binding ID | `{vendor}{Module}{Action}{Entity}Binding` | `acmeOrderExportCompletedBinding` |
| Consumer class | `Queue\Consumer\{Action}{Entity}` | `Queue\Consumer\ExportOrder` |
| Message interface | `Api\Data\{Message}Interface` | `Api\Data\OrderExportMessageInterface` |

## 4. Templates

### 4.1 communication.xml — `etc/communication.xml`

```xml
<?xml version="1.0"?>
<!--
/**
 * Copyright © Monsoon Consulting. All rights reserved.
 * See LICENSE_MONSOON.txt for license details.
 */
-->
<config xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
        xsi:noNamespaceSchemaLocation="urn:magento:framework:Communication/etc/communication.xsd">
    <topic name="{topic.name}" request="{Vendor}\{ModuleName}\Api\Data\{Message}Interface"/>
</config>
```

For simple string messages: `request="string"`. For arrays: `request="string[]"`.

### 4.2 queue_topology.xml — `etc/queue_topology.xml`

```xml
<?xml version="1.0"?>
<!-- Standard XML header — see _shared/conventions.md -->
<config xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
        xsi:noNamespaceSchemaLocation="urn:magento:framework-message-queue:etc/topology.xsd">
    <exchange name="{exchange.name}" type="topic" connection="{connection}">
        <binding id="{bindingId}" topic="{topic.name}"
                 destinationType="queue" destination="{queue.name}"/>
    </exchange>
</config>
```

### 4.3 queue_consumer.xml — `etc/queue_consumer.xml`

```xml
<?xml version="1.0"?>
<!-- Standard XML header — see _shared/conventions.md -->
<config xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
        xsi:noNamespaceSchemaLocation="urn:magento:framework-message-queue:etc/consumer.xsd">
    <consumer name="{consumer_name}"
              queue="{queue.name}"
              handler="{Vendor}\{ModuleName}\Queue\Consumer\{HandlerClass}::process"
              connection="{connection}"
              maxMessages="1000"/>
</config>
```

### 4.4 queue_publisher.xml — `etc/queue_publisher.xml`

```xml
<?xml version="1.0"?>
<!-- Standard XML header — see _shared/conventions.md -->
<config xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
        xsi:noNamespaceSchemaLocation="urn:magento:framework-message-queue:etc/publisher.xsd">
    <publisher topic="{topic.name}">
        <connection name="{connection}" exchange="{exchange.name}" disabled="false"/>
    </publisher>
</config>
```

### 4.5 Message Interface (Complex Messages) — `Api/Data/{Message}Interface.php`

```php
<?php
/**
 * Copyright © Monsoon Consulting. All rights reserved.
 * See LICENSE_MONSOON.txt for license details.
 */

declare(strict_types=1);

namespace {Vendor}\{ModuleName}\Api\Data;

interface {Message}Interface
{
    /**
     * @return int
     */
    public function getEntityId(): int;

    /**
     * @param int $entityId
     * @return $this
     */
    public function setEntityId(int $entityId): self;

    /**
     * @return string
     */
    public function getAction(): string;

    /**
     * @param string $action
     * @return $this
     */
    public function setAction(string $action): self;
}
```

### 4.6 Message Implementation — `Model/Queue/{Message}.php`

```php
<?php
// Standard file header — see _shared/conventions.md
declare(strict_types=1);

namespace {Vendor}\{ModuleName}\Model\Queue;

use {Vendor}\{ModuleName}\Api\Data\{Message}Interface;

final class {Message} implements {Message}Interface
{
    private int $entityId = 0;
    private string $action = '';

    public function getEntityId(): int
    {
        return $this->entityId;
    }

    public function setEntityId(int $entityId): self
    {
        $this->entityId = $entityId;
        return $this;
    }

    public function getAction(): string
    {
        return $this->action;
    }

    public function setAction(string $action): self
    {
        $this->action = $action;
        return $this;
    }
}
```

### 4.7 Consumer Handler — `Queue/Consumer/{HandlerClass}.php`

```php
<?php
// Standard file header — see _shared/conventions.md
declare(strict_types=1);

namespace {Vendor}\{ModuleName}\Queue\Consumer;

use Psr\Log\LoggerInterface;
use {Vendor}\{ModuleName}\Api\Data\{Message}Interface;

final class {HandlerClass}
{
    public function __construct(
        private readonly LoggerInterface $logger
    ) {
    }

    public function process({Message}Interface $message): void
    {
        try {
            $entityId = $message->getEntityId();
            $action = $message->getAction();

            // Process the message here

            $this->logger->info('Processed message', [
                'entity_id' => $entityId,
                'action' => $action,
            ]);
        } catch (\Throwable $e) {
            $this->logger->error('Consumer failed: ' . $e->getMessage(), [
                'exception' => $e,
            ]);
        }
    }
}
```

### 4.8 Publishing a Message (Usage Pattern)

```php
// Inject via constructor:
use Magento\Framework\MessageQueue\PublisherInterface;

// In your service/observer/controller:
$message = $this->messageFactory->create();
$message->setEntityId($orderId);
$message->setAction('export');

$this->publisher->publish('{topic.name}', $message);
```

### 4.9 di.xml — Message Interface Preference

```xml
<config xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
        xsi:noNamespaceSchemaLocation="urn:magento:framework:ObjectManager/etc/config.xsd">
    <preference for="{Vendor}\{ModuleName}\Api\Data\{Message}Interface"
                type="{Vendor}\{ModuleName}\Model\Queue\{Message}"/>
</config>
```

## 5. Generation Rules

Follow this sequence when generating message queue code:

1. **Verify the module exists** — check `app/code/{Vendor}/{ModuleName}/registration.php`.

2. **Create `etc/communication.xml`** — define the topic and message type.

3. **Create `etc/queue_topology.xml`** — define exchange and binding.

4. **Create `etc/queue_consumer.xml`** — define consumer and handler.

5. **Create `etc/queue_publisher.xml`** — define publisher connection.

6. **If complex message:** create message interface + implementation + di.xml preference.

7. **Create consumer handler class** in `Queue/Consumer/`.

8. **Remind the user** to run post-generation commands.

## 6. Anti-Patterns

**Throwing unhandled exceptions in consumers.**
Failed messages get retried indefinitely or poison the queue. Always catch `\Throwable`, log the error, and handle gracefully.

**Mixing `db` and `amqp` connections for the same topic.**
All four XML files (communication, topology, consumer, publisher) for a topic must use the same connection type.

**Overly large message payloads.**
Messages should carry IDs/references, not full entity data. Load fresh data from the database in the consumer. This avoids stale data and keeps messages small.

**Not configuring `maxMessages`.**
Without a limit, consumers run indefinitely and may cause memory leaks. Set a reasonable limit; the cron runner restarts consumers automatically.

**Using ObjectManager in consumer classes.**
All dependencies must be injected via constructor.

**Processing order-dependent messages in parallel.**
MySQL queues process FIFO per consumer. If message order matters, use a single consumer instance.

**Retry & dead-letter pattern:** For poison messages (messages that repeatedly fail), implement retry logic in your consumer:

```php
public function process(MessageInterface $message): void
{
    try {
        $this->handler->execute($message);
    } catch (\Throwable $e) {
        $retryCount = (int) ($message->getRetryCount() ?? 0);
        if ($retryCount < self::MAX_RETRIES) {
            // Re-publish with incremented retry count
            $this->publisher->publish(self::TOPIC, $message->withRetryCount($retryCount + 1));
        } else {
            $this->logger->critical('Dead letter: ' . self::TOPIC, ['message' => $message]);
        }
    }
}
```

**Production deployment:** In production, consumers should run via `cron_consumers_runner` (configured in `env.php`) instead of manually via `queue:consumers:start`. Set in `app/etc/env.php`:
```php
'cron_consumers_runner' => [
    'cron_run' => true,
    'max_messages' => 1000,
    'consumers' => ['{vendor}_{consumer_name}'],
],
```

## 7. Post-Generation Steps

Follow `.claude/skills/_shared/post-generation.md` for: di.xml, new module enable.

**Verification:**
```bash
bin/magento queue:consumers:list                                    # Verify consumer is registered
bin/magento queue:consumers:start {consumer_name} --max-messages=1  # Test consumer
```

For production: consumers run automatically via the `consumers` cron group. Configure in `app/etc/env.php` under `cron_consumers_runner`.
