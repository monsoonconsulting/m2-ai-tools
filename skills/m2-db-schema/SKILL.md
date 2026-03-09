---
name: m2-db-schema
description: >
  Generate Magento 2 database schema (db_schema.xml), whitelist JSON, and
  data/schema patches. Use this skill whenever the user asks to create tables,
  add columns, define indexes, create foreign keys, write data migrations, or
  seed data. Trigger on: "create table", "add table", "add column", "database
  schema", "db_schema", "data patch", "schema patch", "migration", "data
  migration", "seed data", "add index", "foreign key", "modify table", "alter
  table", "whitelist", "db_schema_whitelist", "declarative schema",
  "model", "resource model", "collection", "entity class".
---

# Magento 2 Database Schema Generator

You are a Magento 2 database schema specialist. Generate `db_schema.xml`, `db_schema_whitelist.json`, and data/schema patch files under existing modules in `app/code/{Vendor}/{ModuleName}/`.

Follow the coding conventions and file headers defined in `.claude/skills/_shared/conventions.md` and `.claude/skills/m2-module/SKILL.md`. Do not duplicate those conventions here.

**Prerequisites:** Module must exist (see `_shared/conventions.md`). If not, use `/m2-module` first.

## 1. Decision Tree

**Use `db_schema.xml` when you need to:**
- Create a new table
- Add, modify, or drop columns on an existing table
- Add or remove indexes and constraints
- Define foreign key relationships

**Use a data patch (`Setup/Patch/Data/`) when you need to:**
- Insert, update, or delete rows in any table
- Set configuration values (`core_config_data`)
- Create CMS blocks/pages or other entity data
- Seed lookup/reference data

> **For EAV attributes** (product, category, customer, customer address), use `/m2-eav-attributes` instead.

**Use a schema patch (`Setup/Patch/Schema/`) when you need to:**
- Perform DDL that `db_schema.xml` cannot express (e.g., triggers, stored procedures, renaming columns in complex ways)
- This is rare — prefer `db_schema.xml` for all standard DDL

**Deprecated — never use these:**
- `InstallSchema` / `UpgradeSchema` — replaced by `db_schema.xml`
- `InstallData` / `UpgradeData` — replaced by data patches
- `PatchVersionInterface` — legacy version-based patching; use `DataPatchInterface` or `SchemaPatchInterface` instead

## 2. Gather Requirements

Before generating any files, collect the following from the user.

**For db_schema.xml (ask if not provided):**
- **Module name** — `Vendor_ModuleName` where the schema belongs
- **Table name** — lowercase, underscore-separated (e.g., `acme_blog_post`)
- **Columns** — name, type, nullable, default, comment for each
- **Primary key** — which column(s)
- **Indexes** — columns and index type (btree/fulltext/hash)
- **Foreign keys** — reference table, reference column, onDelete action

**For data patches (ask if not provided):**
- **Module name** — where the patch belongs
- **Patch purpose** — what data to insert/update/delete
- **Dependencies** — other patches that must run first (if any)

## 3. Naming Conventions

| Concept | Convention | Example |
|---------|-----------|---------|
| Table name | `{vendor}_{module}_{entity}` (lowercase, underscored) | `acme_blog_post` |
| PK column | `entity_id` (single-entity tables) or `{entity}_id` | `entity_id`, `post_id` |
| FK referenceId | `{TABLE}__{COLUMN}___{REF_TABLE}___{REF_COLUMN}` (UPPERCASE, double/triple underscores) | `ACME_BLOG_POST__STORE_ID___STORE__STORE_ID` |
| Unique constraint referenceId | `{TABLE}___{COLUMN(S)}` (UPPERCASE, triple underscores) | `ACME_BLOG_POST___URL_KEY` |
| Index referenceId | `{TABLE}___{COLUMN(S)}` (UPPERCASE, triple underscores) | `ACME_BLOG_POST___STATUS` |
| Primary key referenceId | `PRIMARY` | `PRIMARY` |
| Data patch class | Descriptive PascalCase verb+noun | `AddDefaultCategories`, `UpdateShippingConfig` |
| Data patch path | `Setup/Patch/Data/{ClassName}.php` | `Setup/Patch/Data/AddDefaultCategories.php` |
| Schema patch path | `Setup/Patch/Schema/{ClassName}.php` | `Setup/Patch/Schema/AddTriggerOnOrders.php` |

## 4. Column Types Quick Reference

Common types: `int`, `smallint`, `varchar`, `text`, `decimal`, `boolean`, `datetime`, `timestamp`, `json`. Use `identity="true"` for auto-increment PKs, `unsigned="true"` for non-negative integers.

**Price:** `decimal` with `precision="20" scale="4"`. **Timestamps:** `timestamp` with `default="CURRENT_TIMESTAMP"` and `on_update="true"` for updated_at.

See `references/column-types-and-constraints.md` for the full type table with MySQL mappings, attributes, and common patterns.

## 5. Constraints & Indexes Quick Reference

**Primary key:** `<constraint xsi:type="primary" referenceId="PRIMARY">`. **Foreign key:** `<constraint xsi:type="foreign" referenceId="{TABLE}__{COL}___{REF_TABLE}___{REF_COL}">` with `onDelete="CASCADE|SET NULL|NO ACTION"`. **Index:** `<index referenceId="{TABLE}___{COL}" indexType="btree|fulltext|hash">`.

See `references/column-types-and-constraints.md` for full constraint/index templates and naming conventions.

## 6. Templates

### 6.1 db_schema.xml — Single Table with Timestamps and Indexes

```xml
<?xml version="1.0"?>
<!--
/**
 * Copyright © Monsoon Consulting. All rights reserved.
 * See LICENSE_MONSOON.txt for license details.
 */
-->
<schema xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
        xsi:noNamespaceSchemaLocation="urn:magento:framework:Setup/Declaration/Schema/etc/schema.xsd">
    <table name="{table_name}" resource="default" engine="innodb" comment="{Table Comment}">
        <column xsi:type="int" name="entity_id" unsigned="true" nullable="false" identity="true" comment="Entity ID"/>
        <column xsi:type="varchar" name="title" length="255" nullable="false" comment="Title"/>
        <column xsi:type="text" name="content" nullable="true" comment="Content"/>
        <column xsi:type="smallint" name="status" unsigned="true" nullable="false" default="0" comment="Status"/>
        <column xsi:type="timestamp" name="created_at" nullable="false" default="CURRENT_TIMESTAMP" comment="Created At"/>
        <column xsi:type="timestamp" name="updated_at" nullable="false" default="CURRENT_TIMESTAMP" on_update="true" comment="Updated At"/>

        <constraint xsi:type="primary" referenceId="PRIMARY">
            <column name="entity_id"/>
        </constraint>

        <index referenceId="{TABLE_UPPER}___STATUS" indexType="btree">
            <column name="status"/>
        </index>
        <index referenceId="{TABLE_UPPER}___CREATED_AT" indexType="btree">
            <column name="created_at"/>
        </index>
    </table>
</schema>
```

### 6.2 db_schema.xml — Two Tables with Foreign Key (Store Linkage)

```xml
<?xml version="1.0"?>
<!-- Standard XML header — see _shared/conventions.md -->
<schema xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
        xsi:noNamespaceSchemaLocation="urn:magento:framework:Setup/Declaration/Schema/etc/schema.xsd">
    <!-- Main entity table -->
    <table name="{entity_table}" resource="default" engine="innodb" comment="{Entity Comment}">
        <column xsi:type="int" name="entity_id" unsigned="true" nullable="false" identity="true" comment="Entity ID"/>
        <column xsi:type="varchar" name="title" length="255" nullable="false" comment="Title"/>
        <column xsi:type="boolean" name="is_active" nullable="false" default="true" comment="Is Active"/>
        <column xsi:type="timestamp" name="created_at" nullable="false" default="CURRENT_TIMESTAMP" comment="Created At"/>
        <column xsi:type="timestamp" name="updated_at" nullable="false" default="CURRENT_TIMESTAMP" on_update="true" comment="Updated At"/>

        <constraint xsi:type="primary" referenceId="PRIMARY">
            <column name="entity_id"/>
        </constraint>
    </table>

    <!-- Store linkage table (many-to-many with store) -->
    <table name="{entity_table}_store" resource="default" engine="innodb" comment="{Entity} Store Linkage">
        <column xsi:type="int" name="entity_id" unsigned="true" nullable="false" comment="Entity ID"/>
        <column xsi:type="smallint" name="store_id" unsigned="true" nullable="false" comment="Store ID"/>

        <constraint xsi:type="primary" referenceId="PRIMARY">
            <column name="entity_id"/>
            <column name="store_id"/>
        </constraint>

        <constraint xsi:type="foreign"
                    referenceId="{ENTITY_TABLE}_STORE__ENTITY_ID___{ENTITY_TABLE}___ENTITY_ID"
                    table="{entity_table}_store"
                    column="entity_id"
                    referenceTable="{entity_table}"
                    referenceColumn="entity_id"
                    onDelete="CASCADE"/>

        <constraint xsi:type="foreign"
                    referenceId="{ENTITY_TABLE}_STORE__STORE_ID___STORE__STORE_ID"
                    table="{entity_table}_store"
                    column="store_id"
                    referenceTable="store"
                    referenceColumn="store_id"
                    onDelete="CASCADE"/>
    </table>
</schema>
```

### 6.3 Adding a Column to an Existing Table

To add a column to an existing table, redeclare the table in your module's `db_schema.xml` with only the new column. Magento merges declarations across modules.

```xml
<schema xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
        xsi:noNamespaceSchemaLocation="urn:magento:framework:Setup/Declaration/Schema/etc/schema.xsd">
    <table name="existing_table_name">
        <column xsi:type="varchar" name="new_column" length="255" nullable="true" comment="New Column"/>
    </table>
</schema>
```

Update `db_schema_whitelist.json` to include the new column. Existing columns/constraints from the original module's schema are preserved automatically.

### 6.4 Dropping a Column

Remove the column from `db_schema.xml` and ensure the column is listed in `db_schema_whitelist.json` (Magento only drops whitelisted columns). Run `setup:upgrade` to apply.

### 6.5 db_schema_whitelist.json

Generate alongside `db_schema.xml`. List every table, column, constraint, and index declared in the schema.

```json
{
    "{table_name}": {
        "column": {
            "entity_id": true,
            "title": true,
            "content": true,
            "status": true,
            "created_at": true,
            "updated_at": true
        },
        "constraint": {
            "PRIMARY": true,
            "{FK_REFERENCE_ID}": true
        },
        "index": {
            "{INDEX_REFERENCE_ID}": true
        }
    }
}
```

When the module already has a `db_schema_whitelist.json`, **merge** the new entries into it — never overwrite existing entries.

### 6.6 Data Patch — Base Template

All data patches follow this structure. Vary the `apply()` body and constructor for different use cases.

```php
<?php
/**
 * Copyright © Monsoon Consulting. All rights reserved.
 * See LICENSE_MONSOON.txt for license details.
 */

declare(strict_types=1);

namespace {Vendor}\{ModuleName}\Setup\Patch\Data;

use Magento\Framework\Setup\ModuleDataSetupInterface;
use Magento\Framework\Setup\Patch\DataPatchInterface;

final class {PatchClassName} implements DataPatchInterface
{
    public function __construct(
        private readonly ModuleDataSetupInterface $moduleDataSetup
    ) {
    }

    public function apply(): self
    {
        $this->moduleDataSetup->startSetup();

        // --- Insert records ---
        $this->moduleDataSetup->getConnection()->insertMultiple(
            $this->moduleDataSetup->getTable('{table_name}'),
            [
                ['column_a' => 'value1', 'column_b' => 'value2'],
                ['column_a' => 'value3', 'column_b' => 'value4'],
            ]
        );

        $this->moduleDataSetup->endSetup();

        return $this;
    }

    public static function getDependencies(): array
    {
        return [];
    }

    public function getAliases(): array
    {
        return [];
    }
}
```

### 6.7 Data Patch — apply() Variations

**Update config values:**
```php
    public function apply(): self
    {
        $this->moduleDataSetup->startSetup();
        $this->moduleDataSetup->getConnection()->update(
            $this->moduleDataSetup->getTable('core_config_data'),
            ['value' => '{new_value}'],
            ['path = ?' => '{config/path}']
        );
        $this->moduleDataSetup->endSetup();
        return $this;
    }
```

**With dependencies** — list patches that must run first:
```php
    public static function getDependencies(): array
    {
        return [
            \{Vendor}\{ModuleName}\Setup\Patch\Data\{DependencyPatchClass}::class,
        ];
    }
```

### 6.8 Data Patch — With Additional DI Dependencies

When the patch needs services beyond `ModuleDataSetupInterface`, add them to the constructor:

```php
<?php
// Standard file header — see _shared/conventions.md
declare(strict_types=1);

namespace {Vendor}\{ModuleName}\Setup\Patch\Data;

use Magento\Cms\Api\BlockRepositoryInterface;
use Magento\Cms\Api\Data\BlockInterfaceFactory;
use Magento\Framework\Setup\ModuleDataSetupInterface;
use Magento\Framework\Setup\Patch\DataPatchInterface;

final class {PatchClassName} implements DataPatchInterface
{
    public function __construct(
        private readonly ModuleDataSetupInterface $moduleDataSetup,
        private readonly BlockInterfaceFactory $blockFactory,
        private readonly BlockRepositoryInterface $blockRepository
    ) {
    }

    public function apply(): self
    {
        $this->moduleDataSetup->startSetup();
        $block = $this->blockFactory->create();
        $block->setIdentifier('{block_identifier}')
            ->setTitle('{Block Title}')
            ->setContent('{block_content}')
            ->setIsActive(true)
            ->setStoreId([0]);
        $this->blockRepository->save($block);
        $this->moduleDataSetup->endSetup();
        return $this;
    }

    // getDependencies() and getAliases() same as base template
}
```

### 6.9 Schema Patch

Use only when `db_schema.xml` cannot express the needed DDL (triggers, stored procedures, etc.). Same structure as data patch but implements `SchemaPatchInterface` and injects `SchemaSetupInterface`:

```php
use Magento\Framework\Setup\SchemaSetupInterface;
use Magento\Framework\Setup\Patch\SchemaPatchInterface;

final class {PatchClassName} implements SchemaPatchInterface
{
    public function __construct(
        private readonly SchemaSetupInterface $schemaSetup
    ) {
    }

    public function apply(): self
    {
        $this->schemaSetup->startSetup();
        // Raw DDL that db_schema.xml cannot express
        $this->schemaSetup->getConnection()->query('...');
        $this->schemaSetup->endSetup();
        return $this;
    }

    // getDependencies() and getAliases() same as data patch base template
}
```

### Model / ResourceModel / Collection

After creating a table, you typically need Model, ResourceModel, and Collection classes. See `references/model-resource-collection.md` for templates.

## 7. Generation Rules

Follow this sequence when generating schema and patch files:

1. **Verify the target module exists** — check that `app/code/{Vendor}/{ModuleName}/registration.php` exists. If not, instruct the user to scaffold it first with `/m2-module`.

2. **Check if `db_schema.xml` exists** at `app/code/{Vendor}/{ModuleName}/etc/db_schema.xml`:
   - If the file exists, **append** the new `<table>` block(s) inside the existing `<schema>` element, or modify the existing table definition.
   - If the file does not exist, **create** it with the full XML structure including copyright header.

3. **Check if `db_schema_whitelist.json` exists** at `app/code/{Vendor}/{ModuleName}/etc/db_schema_whitelist.json`:
   - If the file exists, **merge** new entries into the existing JSON (never remove existing entries).
   - If the file does not exist, **create** it with entries for all tables/columns/constraints/indexes in the schema.

4. **For data patches:**
   - Create the patch class at `Setup/Patch/Data/{ClassName}.php`.
   - Use a descriptive class name that reflects the action (e.g., `AddDefaultCategories`, not `Patch001`).
   - Each patch runs exactly once — Magento tracks applied patches in `patch_list` table.
   - Never modify an already-applied patch. Create a new patch class for changes.
   - If the patch depends on another, list it in `getDependencies()`.

5. **For schema patches:**
   - Only create these for DDL that `db_schema.xml` cannot handle.
   - Create at `Setup/Patch/Schema/{ClassName}.php`.

6. **Remind the user** to run post-generation commands (see section 9).

## 8. Anti-Patterns

**Wrong price precision.**
Use `precision="20" scale="4"` for prices (matches Magento core). Never use `precision="12" scale="2"` — it cannot store values in currencies with high unit counts and loses precision on tax calculations.

**Missing `unsigned="true"` on primary key integer columns.**
Auto-increment PKs should always be `unsigned` to double the positive range.

**Foreign key column type mismatch.**
The FK column must have the exact same type, size, and unsigned attribute as the referenced column. For example, `store_id` referencing `store.store_id` must be `smallint unsigned` — not `int`.

**Redundant index on unique constraint columns.**
A unique constraint already creates an index. Do not add a separate `<index>` on the same column(s).

**Missing whitelist file.**
Without `db_schema_whitelist.json`, Magento cannot safely apply destructive schema changes (drop column, drop table). Always generate it.

**Confusing table attributes with FK constraint attributes.**
`resource`, `engine`, and `comment` are table-level attributes. FK constraints use `table`, `column`, `referenceTable`, `referenceColumn`, `onDelete`. Do not mix them up.

**Using ObjectManager in patches.**
Always use constructor DI, even in setup patches. `ModuleDataSetupInterface` is injected automatically. For additional services, add them to the constructor.

**Using schema patches for standard DDL.**
Column adds, type changes, index adds — all of these belong in `db_schema.xml`. Reserve schema patches for truly unsupported DDL only.

**Missing `onDelete` on foreign keys.**
Always specify `onDelete` explicitly. The default behavior varies and being explicit prevents surprises. Choose the action based on the relationship semantics.

**Nullable FK column with `onDelete="CASCADE"`.**
If the FK column is nullable, `SET NULL` is usually the correct action, not `CASCADE`. `CASCADE` would delete the child row when the parent is deleted, which may not be the intent if the column allows null (indicating the relationship is optional).

## 9. Post-Generation Steps

Follow `.claude/skills/_shared/post-generation.md` for: db_schema.xml, data/schema patches.
