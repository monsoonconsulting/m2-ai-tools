---
name: m2-indexer
description: >
  Generate Magento 2 custom indexers with indexer.xml, mview.xml, ActionInterface
  implementation, and flat table patterns. Use this skill whenever the user asks
  to create a custom indexer, materialized view, flat table, or needs to
  denormalize data for performance.
  Trigger on: "custom indexer", "indexer.xml", "mview.xml", "mview", "indexer",
  "reindex", "flat table", "denormalize", "materialized view", "ActionInterface",
  "executeFull", "executeList", "executeRow", "changelog", "subscription",
  "indexer:reindex", "create indexer", "add indexer", "index table".
---

# Magento 2 Custom Indexer Generator

You are a Magento 2 indexer specialist. Generate custom indexers with indexer.xml, mview.xml, ActionInterface implementations, and flat table patterns under existing modules in `app/code/{Vendor}/{ModuleName}/`.

Follow the coding conventions and file headers defined in `.claude/skills/_shared/conventions.md` and `.claude/skills/m2-module/SKILL.md`. Do not duplicate those conventions here.

**Prerequisites:** Module must exist (see `_shared/conventions.md`). If not, use `/m2-module` first. The source table must exist. If not, use `/m2-db-schema` first.

## 1. Decision Tree

**Use a custom indexer when:**
- You need to denormalize data from multiple tables into a flat table for fast reads
- Complex queries are too slow and you need pre-computed results
- You need real-time or on-schedule materialized views of source data

**Use a cron job instead when:**
- The task is periodic cleanup, not data denormalization — see `/m2-cron-jobs`

**Use a message queue instead when:**
- The task is event-triggered and one-off, not a full/partial reindex — see `/m2-message-queue`

**Indexer modes:**
- **Update on Save** (`realtime`) — indexer runs immediately when source data changes (via mview changelog). Best for low-volume changes.
- **Update by Schedule** (`schedule`) — indexer runs via cron using the mview changelog. Best for high-volume or expensive indexes.

## 2. Gather Requirements

Before generating any files, collect the following from the user.

**Required (ask if not provided):**
- **Module name** — `Vendor_ModuleName`
- **Indexer purpose** — what data is being denormalized/indexed
- **Source table(s)** — which table(s) the indexer reads from
- **Index (flat) table** — the destination table for denormalized data

**Optional (use defaults if not specified):**
- **Default mode** — default: `schedule` (Update by Schedule)
- **Mview subscriptions** — default: derived from source table(s)
- **Batch size** — default: `1000`

## 3. Naming Conventions

| Concept | Convention | Example |
|---------|-----------|---------|
| Indexer ID | `{vendor}_{modulename}_{descriptive}` | `acme_catalog_product_flat` |
| Indexer class | `Indexer\{Name}` | `Indexer\ProductFlat` |
| Action class | `Indexer\{Name}` (same class, implements `ActionInterface`) | `Indexer\ProductFlat` |
| View ID (mview) | `{vendor}_{modulename}_{descriptive}` | `acme_catalog_product_flat` |
| Flat table name | `{vendor}_{module}_{entity}_flat` | `acme_catalog_product_flat` |
| Changelog table | Auto-generated: `{view_id}_cl` | `acme_catalog_product_flat_cl` |

## 4. Templates

### 4.1 indexer.xml — `etc/indexer.xml`

```xml
<?xml version="1.0"?>
<!--
/**
 * Copyright © Monsoon Consulting. All rights reserved.
 * See LICENSE_MONSOON.txt for license details.
 */
-->
<config xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
        xsi:noNamespaceSchemaLocation="urn:magento:framework:Indexer/etc/indexer.xsd">
    <indexer id="{indexer_id}"
             view_id="{view_id}"
             class="{Vendor}\{ModuleName}\Indexer\{ClassName}"
             shared_index="">
        <title>{Indexer Title}</title>
        <description>{Indexer Description}</description>
    </indexer>
</config>
```

The `view_id` links this indexer to an mview configuration. The `class` must implement `ActionInterface`.

**`shared_index` attribute:** When multiple indexers write to the same flat table, set `shared_index="{group_name}"` on each. This tells Magento to coordinate their execution and avoid table locking conflicts. Leave empty (`shared_index=""`) for indexers with their own dedicated table.

### 4.2 mview.xml — `etc/mview.xml`

```xml
<?xml version="1.0"?>
<!-- Standard XML header — see _shared/conventions.md -->
<config xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
        xsi:noNamespaceSchemaLocation="urn:magento:framework:Mview/etc/mview.xsd">
    <view id="{view_id}"
          class="{Vendor}\{ModuleName}\Indexer\{ClassName}"
          group="indexer">
        <subscriptions>
            <table name="{source_table}" entity_column="entity_id"/>
        </subscriptions>
    </view>
</config>
```

**Subscriptions:** Each `<table>` entry tells Magento to track changes (INSERT/UPDATE/DELETE) on that table. The `entity_column` is the column whose changed IDs are logged to the changelog table (`{view_id}_cl`).

Multiple subscriptions for multiple source tables:
```xml
<subscriptions>
    <table name="catalog_product_entity" entity_column="entity_id"/>
    <table name="cataloginventory_stock_item" entity_column="product_id"/>
</subscriptions>
```

**Indexer dependencies:** If your indexer depends on another indexer's output, add a `<dependencies>` block in `indexer.xml`:
```xml
<indexer id="{indexer_id}" view_id="{view_id}" class="...">
    <title>...</title>
    <description>...</description>
    <dependencies>
        <indexer id="catalog_product_attribute"/>
    </dependencies>
</indexer>
```
This ensures the dependency runs first during full reindex.

### 4.3 Indexer Class — `Indexer/{ClassName}.php`

```php
<?php
/**
 * Copyright © Monsoon Consulting. All rights reserved.
 * See LICENSE_MONSOON.txt for license details.
 */

declare(strict_types=1);

namespace {Vendor}\{ModuleName}\Indexer;

use Magento\Framework\Indexer\ActionInterface as IndexerActionInterface;
use Magento\Framework\Mview\ActionInterface as MviewActionInterface;
use Psr\Log\LoggerInterface;
use {Vendor}\{ModuleName}\Model\ResourceModel\Indexer\{ClassName} as IndexerResource;

final class {ClassName} implements IndexerActionInterface, MviewActionInterface
{
    private const BATCH_SIZE = 1000;

    public function __construct(
        private readonly IndexerResource $resource,
        private readonly LoggerInterface $logger
    ) {
    }

    /**
     * Full reindex — rebuild entire flat table.
     */
    public function executeFull(): void
    {
        try {
            $this->resource->reindexAll();
        } catch (\Throwable $e) {
            $this->logger->error('Full reindex failed: ' . $e->getMessage(), ['exception' => $e]);
            throw $e;
        }
    }

    /**
     * Partial reindex by ID list — called by mview (Update by Schedule).
     *
     * @param int[] $ids
     */
    public function executeList(array $ids): void
    {
        if (empty($ids)) {
            return;
        }

        foreach (array_chunk($ids, self::BATCH_SIZE) as $batch) {
            $this->resource->reindexByIds($batch);
        }
    }

    /**
     * Single row reindex — called for Update on Save mode.
     */
    public function executeRow($id): void
    {
        if ($id === null) {
            return;
        }

        $this->resource->reindexByIds([(int) $id]);
    }

    /**
     * Mview execute — called by the mview subsystem with changed entity IDs.
     *
     * @param int[] $ids
     */
    public function execute($ids): void
    {
        $this->executeList($ids);
    }
}
```

### 4.4 Indexer Resource Model — `Model/ResourceModel/Indexer/{ClassName}.php`

```php
<?php
// Standard file header — see _shared/conventions.md
declare(strict_types=1);

namespace {Vendor}\{ModuleName}\Model\ResourceModel\Indexer;

use Magento\Framework\App\ResourceConnection;
use Magento\Framework\DB\Adapter\AdapterInterface;

final class {ClassName}
{
    private const FLAT_TABLE = '{flat_table_name}';
    private const SOURCE_TABLE = '{source_table_name}';

    public function __construct(
        private readonly ResourceConnection $resource
    ) {
    }

    public function reindexAll(): void
    {
        $connection = $this->getConnection();
        $flatTable = $this->resource->getTableName(self::FLAT_TABLE);
        $sourceTable = $this->resource->getTableName(self::SOURCE_TABLE);

        $connection->truncateTable($flatTable);

        $select = $connection->select()
            ->from($sourceTable, ['{columns}']);

        $connection->query(
            $connection->insertFromSelect($select, $flatTable, ['{columns}'])
        );
    }

    public function reindexByIds(array $ids): void
    {
        $connection = $this->getConnection();
        $flatTable = $this->resource->getTableName(self::FLAT_TABLE);
        $sourceTable = $this->resource->getTableName(self::SOURCE_TABLE);

        $connection->delete($flatTable, ['entity_id IN (?)' => $ids]);

        $select = $connection->select()
            ->from($sourceTable, ['{columns}'])
            ->where('entity_id IN (?)', $ids);

        $connection->query(
            $connection->insertFromSelect($select, $flatTable, ['{columns}'])
        );
    }

    private function getConnection(): AdapterInterface
    {
        return $this->resource->getConnection();
    }
}
```

## 5. Generation Rules

Follow this sequence when generating a custom indexer:

1. **Verify the module exists** — check `registration.php`.

2. **Verify or create the flat table** — the destination table must exist in `db_schema.xml`. If not, instruct the user to create it with `/m2-db-schema`.

3. **Create `etc/indexer.xml`** — register the indexer with title and description.

4. **Create `etc/mview.xml`** — define the view with source table subscriptions.

5. **Create the Indexer class** — implements both `ActionInterface` interfaces (Indexer + Mview).

6. **Create the Indexer Resource Model** — contains the actual SQL logic for `reindexAll()` and `reindexByIds()`.

7. **Remind the user** to run post-generation commands.

## 6. Anti-Patterns

**Putting SQL logic in the Indexer class.**
The Indexer class should delegate to a Resource Model. Keep the Indexer thin — it handles batching and error logging.

**Not implementing both ActionInterfaces.**
The indexer class must implement BOTH `Magento\Framework\Indexer\ActionInterface` (for `executeFull`/`executeList`/`executeRow`) AND `Magento\Framework\Mview\ActionInterface` (for `execute`). Without both, either manual reindex or scheduled reindex will fail.

**Missing `executeRow` implementation.**
Even if you primarily use `executeList`, `executeRow` is called in "Update on Save" mode. It must work correctly.

**Not batching large reindex operations.**
`executeList` can receive thousands of IDs. Always batch with `array_chunk()` to avoid memory issues and long-running queries.

**Using `TRUNCATE` in partial reindex.**
Only `reindexAll()` should truncate. Partial reindex (`reindexByIds`) should DELETE+INSERT only affected rows.

**Forgetting to handle empty ID arrays.**
Both `executeList` and `execute` should return early if the IDs array is empty.

**Not matching view_id between indexer.xml and mview.xml.**
The `view_id` attribute in `indexer.xml` must exactly match the `id` attribute in `mview.xml`.

## 7. Post-Generation Steps

Follow `.claude/skills/_shared/post-generation.md` for: di.xml, new module enable.

**Verification:**
```bash
bin/magento indexer:info                                # Verify indexer appears in list
bin/magento indexer:reindex {indexer_id}                # Test full reindex
bin/magento indexer:set-mode schedule {indexer_id}      # Set to Update by Schedule
```
