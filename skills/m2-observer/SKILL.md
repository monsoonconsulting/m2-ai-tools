---
name: m2-observer
description: >
  Generate Magento 2 event observer classes, events.xml configuration, and custom event dispatching.
  Use this skill whenever the user asks to create an observer, listen to an event, react to an event,
  or dispatch a custom event. Trigger on: "create observer", "add observer", "event listener",
  "event handler", "listen to event", "listen for", "react to event", "observe event",
  "hook into", "on save", "after save",
  "dispatch event", "custom event", "fire event", "trigger event", "events.xml", "ObserverInterface".
---

# Magento 2 Event Observer Generator

You are a Magento 2 event/observer specialist. Generate observer classes and events.xml configuration under existing modules in `app/code/{Vendor}/{ModuleName}/`.

Follow the coding conventions and file headers defined in `.claude/skills/_shared/conventions.md` and `.claude/skills/m2-module/SKILL.md`. Do not duplicate those conventions here.

**Prerequisites:** Module must exist (see `_shared/conventions.md`). If not, use `/m2-module` first.

## 1. Decision Tree: Observer vs Plugin vs Preference

**Use an observer when:**
- A Magento event already exists for your use case (check `.claude/skills/m2-observer/references/common-events.md`)
- You need to react to something happening without modifying the original behavior
- You want loose coupling — the observed class doesn't know about your code
- Multiple independent modules should react to the same action
- You need to perform side effects (logging, syncing, sending notifications)

**Use a plugin instead when:**
- You need to modify input arguments or return values of a specific method
- No event is dispatched at the point you need to hook in
- You need guaranteed execution before/after a specific method call

**Use a preference instead when:**
- You need to replace an entire class implementation
- The behavior change is fundamental, not additive

**Key rule:** If an event exists for your use case, prefer an observer over a plugin. Observers are cheaper (no interceptor generation) and provide cleaner separation of concerns.

## 2. Gather Requirements

Before generating any files, collect the following from the user.

**Required (ask if not provided):**
- **Event name** — the Magento event to observe (e.g., `catalog_product_save_after`). Consult `.claude/skills/m2-observer/references/common-events.md` if the user describes behavior rather than a specific event name.
- **Module name** — `Vendor_ModuleName` where the observer will live
- **Observer purpose** — what the observer should do (used for class naming and logic)

**Optional (use defaults if not specified):**
- **Area scope** — `global` (default), `frontend`, `adminhtml`, `webapi_rest`, `crontab`
- **Dependencies** — services the observer needs injected (e.g., logger, repository)

## 3. Naming Conventions

| Concept | Convention | Example |
|---------|-----------|---------|
| Observer class name | Describes the **action**, not the event | `SyncInventoryAfterProductSave` |
| Namespace | `{Vendor}\{ModuleName}\Observer` | `Acme\CatalogExt\Observer` |
| File path | `Observer/{ClassName}.php` | `Observer/SyncInventoryAfterProductSave.php` |
| events.xml `name` attr | `{vendor}_{modulename}_{descriptive_snake}` | `acme_catalogext_sync_inventory_after_product_save` |
| Custom event names | `{vendor}_{module}_{entity}_{action}` | `acme_warehouse_stock_updated` |

**Observer class naming rules:**
- Name describes what the observer **does**, not which event it listens to
- Use verb phrases: `SendWelcomeEmail`, `InvalidateCacheOnConfigChange`, `LogOrderStatusChange`
- Do NOT name observers after events: ~~`CatalogProductSaveAfterObserver`~~ — this says nothing about purpose
- Keep names concise but descriptive

**Subdirectory grouping:** When a module has many observers, group by domain:
- `Observer/Product/SyncInventory.php`
- `Observer/Order/SendConfirmationEmail.php`

## 4. PHP Class Templates

### 4.1 Basic Observer (No Dependencies)

```php
<?php
/**
 * Copyright © Monsoon Consulting. All rights reserved.
 * See LICENSE_MONSOON.txt for license details.
 */

declare(strict_types=1);

namespace {Vendor}\{ModuleName}\Observer;

use Magento\Framework\Event\Observer;
use Magento\Framework\Event\ObserverInterface;

final class {ClassName} implements ObserverInterface
{
    public function execute(Observer $observer): void
    {
        /** @var {DataType} ${varName} */
        ${varName} = $observer->getEvent()->getData('{data_key}');

        // Observer logic here
    }
}
```

### 4.2 Observer with Constructor Dependencies (PHP 8.2 Promotion)

```php
<?php
// Standard file header — see _shared/conventions.md
declare(strict_types=1);

namespace {Vendor}\{ModuleName}\Observer;

use Magento\Framework\Event\Observer;
use Magento\Framework\Event\ObserverInterface;
use Psr\Log\LoggerInterface;

final class {ClassName} implements ObserverInterface
{
    public function __construct(
        private readonly LoggerInterface $logger
    ) {
    }

    public function execute(Observer $observer): void
    {
        /** @var {DataType} ${varName} */
        ${varName} = $observer->getEvent()->getData('{data_key}');

        // Observer logic here
        $this->logger->info('Event observed', ['key' => ${varName}]);
    }
}
```

### 4.3 Observer Delegating to a Service Class

For complex logic, the observer should delegate to a service class. Keep the observer thin.

```php
<?php
// Standard file header — see _shared/conventions.md
declare(strict_types=1);

namespace {Vendor}\{ModuleName}\Observer;

use Magento\Framework\Event\Observer;
use Magento\Framework\Event\ObserverInterface;
use {Vendor}\{ModuleName}\Service\{ServiceClass};

final class {ClassName} implements ObserverInterface
{
    public function __construct(
        private readonly {ServiceClass} $service
    ) {
    }

    public function execute(Observer $observer): void
    {
        /** @var {DataType} ${varName} */
        ${varName} = $observer->getEvent()->getData('{data_key}');

        $this->service->process(${varName});
    }
}
```

## 5. events.xml Templates

### 5.1 Global Scope (`etc/events.xml`)

```xml
<?xml version="1.0"?>
<!--
/**
 * Copyright © Monsoon Consulting. All rights reserved.
 * See LICENSE_MONSOON.txt for license details.
 */
-->
<config xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
        xsi:noNamespaceSchemaLocation="urn:magento:framework:Event/etc/events.xsd">
    <event name="{event_name}">
        <observer name="{vendor}_{modulename}_{descriptive_snake}"
                  instance="{Vendor}\{ModuleName}\Observer\{ClassName}"/>
    </event>
</config>
```

### 5.2 Area-Specific (`etc/{area}/events.xml`)

Use area-specific events.xml when the observer should only run in a particular area (frontend, adminhtml, webapi_rest, crontab).

```xml
<?xml version="1.0"?>
<!-- Standard XML header — see _shared/conventions.md -->
<config xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
        xsi:noNamespaceSchemaLocation="urn:magento:framework:Event/etc/events.xsd">
    <event name="{event_name}">
        <observer name="{vendor}_{modulename}_{descriptive_snake}"
                  instance="{Vendor}\{ModuleName}\Observer\{ClassName}"/>
    </event>
</config>
```

Place in `etc/frontend/events.xml`, `etc/adminhtml/events.xml`, etc.

### 5.3 Multiple Observers for the Same Event

```xml
<event name="{event_name}">
    <observer name="{vendor}_{modulename}_{first_action}"
              instance="{Vendor}\{ModuleName}\Observer\{FirstObserver}"/>
    <observer name="{vendor}_{modulename}_{second_action}"
              instance="{Vendor}\{ModuleName}\Observer\{SecondObserver}"/>
</event>
```

Each observer must have a unique `name` attribute globally. Use separate observer classes — one concern per observer.

### 5.4 Disabling a Third-Party Observer

```xml
<event name="{event_name}">
    <observer name="{third_party_observer_name}" disabled="true"/>
</event>
```

Use this to disable an observer from another module without modifying its code.

## 6. Dispatching Custom Events

When the user needs to fire their own events from custom code, inject `Magento\Framework\Event\ManagerInterface` and call `dispatch()`.

### 6.1 Dispatching in a Model or Service

```php
use Magento\Framework\Event\ManagerInterface as EventManager;

final class {ClassName}
{
    public function __construct(
        private readonly EventManager $eventManager
    ) {
    }

    public function someMethod(): void
    {
        // ... business logic ...

        $this->eventManager->dispatch('{vendor}_{module}_{entity}_{action}', [
            '{entity}' => $entityObject,
            '{data_key}' => $additionalData,
        ]);
    }
}
```

### 6.2 Custom Event Naming Rules

| Rule | Example |
|------|---------|
| Prefix with vendor and module (lowercase, underscore-separated) | `acme_warehouse_` |
| Include entity name | `acme_warehouse_stock_` |
| End with action | `acme_warehouse_stock_updated` |
| Use `_before` / `_after` suffixes for paired events | `acme_warehouse_stock_import_before`, `acme_warehouse_stock_import_after` |

### 6.3 Document the Data Keys

When dispatching a custom event, always document what data keys are available to observers. Add a comment above the dispatch call:

```php
/**
 * Dispatches: acme_warehouse_stock_updated
 *
 * Event data:
 * - 'product' (\Magento\Catalog\Api\Data\ProductInterface) — the updated product
 * - 'old_qty' (float) — quantity before update
 * - 'new_qty' (float) — quantity after update
 */
$this->eventManager->dispatch('acme_warehouse_stock_updated', [
    'product' => $product,
    'old_qty' => $oldQty,
    'new_qty' => $newQty,
]);
```

## 7. Generation Rules

Follow this sequence when generating an observer:

1. **Verify the target module exists** — check that `app/code/{Vendor}/{ModuleName}/registration.php` exists. If not, instruct the user to scaffold it first with `/m2-module`.

2. **Identify the correct event** — if the user describes behavior (e.g., "after a product is saved"), look up the event name in `.claude/skills/m2-observer/references/common-events.md`. If the event isn't listed, search `vendor/` for the dispatch call to confirm the event name and available data keys.

3. **Determine the scope** — decide whether the observer should be global or area-specific:
   - Frontend-only behavior → `etc/frontend/events.xml`
   - Admin-only behavior → `etc/adminhtml/events.xml`
   - Universal behavior → `etc/events.xml`
   - When unsure, default to global and mention the option to scope it

4. **Check if events.xml exists** for the target scope:
   - If the file exists, **append** the `<event>` block inside the existing `<config>` element.
   - If the file does not exist, **create** it with the full XML structure including copyright header.

5. **Create the Observer PHP class** at the correct path under `Observer/`.

6. **Verify the event data keys** — look up what data the event provides so the observer accesses the correct keys. For model events, this is typically the model object via the `_eventPrefix` key (e.g., `product`, `order`, `customer`).

7. **Remind the user** to run post-generation commands (see section 10).

## 8. Scope Selection Guide

| Scope | events.xml Location | When to Use |
|-------|-------------------|-------------|
| Global | `etc/events.xml` | Observer needed in all areas (model events, data sync) |
| Frontend | `etc/frontend/events.xml` | Storefront-only behavior (layout, display logic) |
| Adminhtml | `etc/adminhtml/events.xml` | Admin-only behavior (admin grids, form processing) |
| Webapi REST | `etc/webapi_rest/events.xml` | REST API-only behavior |
| Crontab | `etc/crontab/events.xml` | Cron context only |

**Rule of thumb:** Use the narrowest scope possible. A frontend-only observer registered globally wastes resources on admin and API requests.

## 9. Anti-Patterns and Pitfalls

**Heavy logic in observers — delegate to services.**
Observers should be thin dispatchers. Extract complex business logic into service classes and have the observer call the service. This makes the logic testable and reusable.

**Modifying data when a plugin would be correct.**
Observers receive event data but are not designed to modify method arguments or return values. If you need to change what a method receives or returns, use a plugin. Observers that modify objects passed by reference work but create hidden coupling.

**Using ObjectManager directly.**
Never use `ObjectManager::getInstance()` inside an observer. Use constructor injection for all dependencies.

**Global scope when area-specific would suffice.**
Registering an observer globally means it loads on every request in every area. If the observer is only relevant to the frontend, use `etc/frontend/events.xml`.

**Multiple concerns in one observer.**
Each observer should do one thing. If you need to send an email AND update inventory when an order is placed, create two separate observers for the same event.

**Relying on observer execution order.**
Magento does not guarantee observer execution order for the same event. Unlike plugins, observers have no `sortOrder`. If execution order matters, use a single observer that calls services in sequence, or use plugins instead.

**Using `_save_after` when `_save_commit_after` is needed.**
`_save_after` fires inside the database transaction. If your observer makes external API calls or dispatches async operations, use `_save_commit_after` instead — it fires after the transaction commits, so the data is guaranteed to be persisted.

**Duplicate observer names across modules.**
Observer names in events.xml are global. If two modules use the same observer name for the same event, one silently overrides the other. Always prefix with `{vendor}_{modulename}_`.

**Throwing exceptions in observers.**
Unhandled exceptions in observers can break the observed operation. If an observer's failure should not prevent the main operation, wrap the logic in a try/catch and log the error. Only throw if the observer's failure must halt the process.

## 10. Post-Generation Steps

Follow `.claude/skills/_shared/post-generation.md` for: layout XML / templates / config changes, new module enable.

Observers do **not** require `setup:di:compile` unless the observer class introduces new DI dependencies that need compilation (proxies, factories, etc.). In most cases, a cache flush is sufficient.
