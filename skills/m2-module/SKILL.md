---
name: m2-module
description: >
  Scaffold a new Magento 2 module with proper structure and all required files.
  Use this skill whenever the user asks to create a module, generate module boilerplate,
  scaffold an extension, start a new extension, or add a module. Trigger on: "new module",
  "create module", "create extension", "scaffold module", "generate module", "add module",
  "module boilerplate", "init module", "bootstrap module", "setup module".
---

# Magento 2 Module Scaffolding

You are a Magento 2 module scaffolding specialist. Generate modules under `app/code/{Vendor}/{ModuleName}/` following the exact conventions of this Magento 2.

Follow the coding conventions and file headers defined in `.claude/skills/_shared/conventions.md` and `.claude/skills/m2-module/SKILL.md`. Do not duplicate those conventions here.

> **Note:** For Hyva-ecosystem modules, the `hyva-*` skills use their own scaffolding via `hyva-create-module`.

## 1. Gather Requirements

Before generating any files, collect the following from the user.

**Required (ask if not provided):**
- **Vendor name** — PascalCase (e.g., `Acme`)
- **Module name** — PascalCase (e.g., `CustomShipping`)

If the user provides `Vendor_ModuleName` format, parse both from it.

**Optional (use defaults if not specified):**
- Description — default: brief module purpose
- Version — default: `1.0.0`
- License — default: `proprietary`
- Sequence dependencies — default: none
- Scope: admin UI / frontend UI / API only — default: ask
- Needs database tables? — default: no
- Modifies existing Magento behavior (plugins/observers)? — default: no

## 2. Naming Conventions

| Concept | Format | Example |
|---------|--------|---------|
| Module identifier | `{Vendor}_{ModuleName}` | `Acme_CustomShipping` |
| PHP namespace | `{Vendor}\{ModuleName}` | `Acme\CustomShipping` |
| Composer package | `{vendor-lower}/module-{kebab-case}` | `acme/module-custom-shipping` |
| Module path | `app/code/{Vendor}/{ModuleName}/` | `app/code/Acme/CustomShipping/` |
| Route frontName | lowercase, no separators | `customshipping` |

**Composer name conversion rules:**
- Vendor: lowercase (`Acme` → `acme`)
- Module: split PascalCase, lowercase, hyphenate, prefix with `module-` (`CustomShipping` → `module-custom-shipping`)

## 3. Core File Templates (Always Generated)

### 3.1 `registration.php`

```php
<?php
/**
 * Copyright © Monsoon Consulting. All rights reserved.
 * See LICENSE_MONSOON.txt for license details.
 */

use Magento\Framework\Component\ComponentRegistrar;

ComponentRegistrar::register(ComponentRegistrar::MODULE, '{Vendor}_{ModuleName}', __DIR__);
```

Note: No `declare(strict_types=1)` in registration.php — consistent with all Magento core modules.

### 3.2 `etc/module.xml`

**Without dependencies:**
```xml
<?xml version="1.0"?>
<!--
/**
 * Copyright © Monsoon Consulting. All rights reserved.
 * See LICENSE_MONSOON.txt for license details.
 */
-->
<config xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
        xsi:noNamespaceSchemaLocation="urn:magento:framework:Module/etc/module.xsd">
    <module name="{Vendor}_{ModuleName}"/>
</config>
```

**With dependencies:**
```xml
<?xml version="1.0"?>
<!-- Standard XML header — see _shared/conventions.md -->
<config xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
        xsi:noNamespaceSchemaLocation="urn:magento:framework:Module/etc/module.xsd">
    <module name="{Vendor}_{ModuleName}">
        <sequence>
            <module name="Magento_Catalog"/>
        </sequence>
    </module>
</config>
```

Important: Do NOT add `setup_version` attribute — Magento 2 uses composer version and declarative schema instead.

### 3.3 `composer.json`

```json
{
    "name": "{vendor-lower}/module-{module-kebab}",
    "description": "{description}",
    "type": "magento2-module",
    "license": [
        "{license}"
    ],
    "version": "{version}",
    "require": {
        "php": "~8.2.0||~8.3.0||~8.4.0",
        "magento/framework": "103.0.*"
    },
    "autoload": {
        "files": [
            "registration.php"
        ],
        "psr-4": {
            "{Vendor}\\{ModuleName}\\": ""
        }
    }
}
```

Add additional `magento/module-*` requirements as needed based on sequence dependencies.

## 4. Coding Conventions

See `.claude/skills/_shared/conventions.md` for the full conventions reference (file headers, strict types, final classes, PHP 8.2+, constructor DI only, ViewModels over Blocks, declarative schema only, data patches only).

### PHP Class File Header

See `_shared/conventions.md` for the template.

### XML File Header

See `_shared/conventions.md` for the template.

## 5. File Generation Order

Generate files in this order when the user requests additional features beyond the base module:

1. `registration.php` + `etc/module.xml` + `composer.json` *(always)*
2. `etc/di.xml` — preferences, plugins, virtual types
3. `etc/frontend/routes.xml` or `etc/adminhtml/routes.xml` — if controllers needed
4. Domain layer: `Api/` interfaces → `Model/` → `Model/ResourceModel/` → `Model/ResourceModel/{Entity}/Collection.php`
5. `etc/db_schema.xml` — for new database tables
6. `Controller/`, `ViewModel/` classes
7. `view/{area}/layout/` XML, `view/{area}/templates/` phtml
8. `etc/acl.xml`, `etc/adminhtml/menu.xml` — if admin features needed

## 6. Optional File Templates

### `etc/di.xml`

```xml
<?xml version="1.0"?>
<!-- Standard XML header — see _shared/conventions.md -->
<config xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:noNamespaceSchemaLocation="urn:magento:framework:ObjectManager/etc/config.xsd">
</config>
```

### `etc/acl.xml`

For CRUD ACL hierarchies (e.g., separate permissions for view/create/edit/delete), see `/m2-admin-ui`.

```xml
<?xml version="1.0"?>
<!-- Standard XML header — see _shared/conventions.md -->
<config xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:noNamespaceSchemaLocation="urn:magento:framework:Acl/etc/acl.xsd">
    <acl>
        <resources>
            <resource id="Magento_Backend::admin">
                <resource id="{Vendor}_{ModuleName}::config" title="{ModuleName}" sortOrder="100"/>
            </resource>
        </resources>
    </acl>
</config>
```

### `etc/frontend/routes.xml`

```xml
<?xml version="1.0"?>
<!-- Standard XML header — see _shared/conventions.md -->
<config xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:noNamespaceSchemaLocation="urn:magento:framework:App/etc/routes.xsd">
    <router id="standard">
        <route id="{route_id}" frontName="{frontname}">
            <module name="{Vendor}_{ModuleName}"/>
        </route>
    </router>
</config>
```

### `etc/adminhtml/routes.xml`

```xml
<?xml version="1.0"?>
<!-- Standard XML header — see _shared/conventions.md -->
<config xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:noNamespaceSchemaLocation="urn:magento:framework:App/etc/routes.xsd">
    <router id="admin">
        <route id="{route_id}" frontName="{frontname}">
            <module name="{Vendor}_{ModuleName}"/>
        </route>
    </router>
</config>
```

For controller classes, best practices, and HTTP verb interfaces, see `/m2-controller`.

### `etc/events.xml`

Use `/m2-observer` for detailed observer generation including common events lookup.

```xml
<?xml version="1.0"?>
<!-- Standard XML header — see _shared/conventions.md -->
<config xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:noNamespaceSchemaLocation="urn:magento:framework:Event/etc/events.xsd">
    <event name="{event_name}">
        <observer name="{vendor}_{modulename}_{observer_name}" instance="{Vendor}\{ModuleName}\Observer\{ObserverClass}"/>
    </event>
</config>
```

### `etc/db_schema.xml`

```xml
<?xml version="1.0"?>
<!-- Standard XML header — see _shared/conventions.md -->
<schema xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:noNamespaceSchemaLocation="urn:magento:framework:Setup/Declaration/Schema/etc/schema.xsd">
    <table name="{table_name}" resource="default" engine="innodb" comment="{Table Comment}">
        <column xsi:type="int" name="entity_id" unsigned="true" nullable="false" identity="true" comment="Entity ID"/>
        <constraint xsi:type="primary" referenceId="PRIMARY">
            <column name="entity_id"/>
        </constraint>
    </table>
</schema>
```

After creating `db_schema.xml`, remind the user to generate the whitelist:
```bash
bin/magento setup:db-declaration:generate-whitelist --module-name={Vendor}_{ModuleName}
```

### `etc/adminhtml/system.xml`

```xml
<?xml version="1.0"?>
<!-- Standard XML header — see _shared/conventions.md -->
<config xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:noNamespaceSchemaLocation="urn:magento:module:Magento_Config:etc/system_file.xsd">
    <system>
        <!-- For complete system.xml generation with field types, source models, etc., use /m2-system-config -->
    </system>
</config>
```

For complete system.xml generation, use `/m2-system-config`.

### `etc/config.xml`

```xml
<?xml version="1.0"?>
<!-- Standard XML header — see _shared/conventions.md -->
<config xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:noNamespaceSchemaLocation="urn:magento:module:Magento_Store:etc/config.xsd">
    <default>
        <{section_id}>
            <general>
                <enabled>0</enabled>
            </general>
        </{section_id}>
    </default>
</config>
```

### `etc/crontab.xml`

Use `/m2-cron-job` for detailed cron job generation including schedule expressions, custom groups, and admin-configurable schedules.

```xml
<?xml version="1.0"?>
<!-- Standard XML header — see _shared/conventions.md -->
<config xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:noNamespaceSchemaLocation="urn:magento:module:Magento_Cron:etc/crontab.xsd">
    <group id="default">
        <job name="{vendor}_{modulename}_{job_name}" instance="{Vendor}\{ModuleName}\Cron\{CronClass}" method="execute">
            <schedule>0 * * * *</schedule>
        </job>
    </group>
</config>
```

### `etc/webapi.xml`

```xml
<?xml version="1.0"?>
<!-- Standard XML header — see _shared/conventions.md -->
<routes xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:noNamespaceSchemaLocation="urn:magento:module:Magento_Webapi:etc/webapi.xsd">
    <route url="/V1/{vendor-lower}-{module-lower}/{resource}" method="GET">
        <service class="{Vendor}\{ModuleName}\Api\{ServiceInterface}" method="{methodName}"/>
        <resources>
            <resource ref="anonymous"/>
        </resources>
    </route>
</routes>
```

## 7. Directory Structure Reference

See `references/directory-structure.md` for the full module directory tree.

## 8. Post-Scaffold Steps

See `.claude/skills/_shared/post-generation.md` for the full command reference.

**Skill-specific verification:**
- Run `bin/magento module:enable {Vendor}_{ModuleName}` and `bin/magento setup:upgrade`
- Verify the module appears in `app/etc/config.php` after enabling
- If `db_schema.xml` was created, generate the whitelist: `bin/magento setup:db-declaration:generate-whitelist --module-name={Vendor}_{ModuleName}`
