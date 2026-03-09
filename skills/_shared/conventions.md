# Shared Coding Conventions

All m2-* skills follow these conventions. Do not duplicate them in individual SKILL.md files.

## PHP Class File Header

```php
<?php
/**
 * Copyright © Monsoon Consulting. All rights reserved.
 * See LICENSE_MONSOON.txt for license details.
 */

declare(strict_types=1);

namespace {Vendor}\{ModuleName}\{SubNamespace};
```

Note: `registration.php` does NOT use `declare(strict_types=1)` — consistent with Magento core.

## XML File Header

```xml
<?xml version="1.0"?>
<!--
/**
 * Copyright © Monsoon Consulting. All rights reserved.
 * See LICENSE_MONSOON.txt for license details.
 */
-->
```

## Coding Conventions

- `declare(strict_types=1);` at the top of every PHP class file (except `registration.php`)
- Return types on all methods, typed properties throughout
- Constructor dependency injection only — **never** use `ObjectManager` directly
- Prefer interfaces and service contracts over concrete classes
- Use ViewModels (`Magento\Framework\View\Element\Block\ArgumentInterface`) instead of Block classes for passing data to templates
- Do NOT use `final` on classes managed by Magento's ObjectManager — the interceptor system generates proxy subclasses (Interceptors) and `final` prevents this, causing `setup:di:compile` failures. Exceptions where `final` is safe: plugin classes (Magento prohibits plugins on plugins), data/schema patches (run-once, never intercepted), observer classes (implement interface only), cron job classes (standalone), GraphQL resolvers (implement interface only), message queue handlers/DTOs, and PHPUnit test classes (not DI-managed)
- PHP 8.2+ features acceptable (readonly properties, enums, named arguments)
- Use declarative schema (`db_schema.xml`) — **never** `InstallSchema`/`UpgradeSchema`
- Use data patches (`Setup/Patch/Data/`) — **never** `InstallData`/`UpgradeData`
- Add `@api` annotation to interfaces meant for third-party use

## Module Must Exist

**Prerequisites:** The target module must exist. If it does not, tell the user to scaffold it first with `/m2-module`.

## XML File Merge Rules

When generating XML files:
- If the file already exists, **merge** new elements into the existing root. Never duplicate the root element. Preserve existing content.
- If the file does not exist, **create** it with the full XML structure including the copyright header above.
- For `di.xml`: append new `<type>`, `<preference>`, or `<virtualType>` nodes inside the existing `<config>` element.
- For `acl.xml`: parse existing tree, insert new `<resource>` nodes at the correct depth. Do not duplicate existing resource IDs.
- For `events.xml` / `crontab.xml`: append new `<event>` / `<job>` blocks inside the existing parent element.
- For `menu.xml`: append new `<add>` nodes inside the existing `<menu>` element.
- For `routes.xml`: if the route already exists, skip. Otherwise append inside `<router>`.
- For `extension_attributes.xml`: append new `<attribute>` inside existing `<extension_attributes>` or add a new `<extension_attributes for="...">` block.
- For `db_schema_whitelist.json`: merge new entries — never remove existing entries.

## Code Example Headers

In code template blocks within SKILL.md files, include the standard file header (shown above) only in the **first** code example. Subsequent examples in the same skill may start from the namespace line to reduce duplication, with a comment referencing this file:

```php
// Standard file header — see _shared/conventions.md
```
