# Data Migration Patterns Reference

> Companion file for m2-db-schema. Covers patterns for large-scale data migrations.

## Chunked Data Patches

Process large datasets in batches to avoid memory exhaustion:

```php
// Standard file header — see _shared/conventions.md
namespace Vendor\ModuleName\Setup\Patch\Data;

use Magento\Framework\App\ResourceConnection;
use Magento\Framework\Setup\Patch\DataPatchInterface;

final class MigrateLargeDataset implements DataPatchInterface
{
    private const BATCH_SIZE = 1000;

    public function __construct(private readonly ResourceConnection $resourceConnection) {}

    public function apply(): self
    {
        $connection = $this->resourceConnection->getConnection();
        $table = $this->resourceConnection->getTableName('my_table');
        $lastId = 0;

        do {
            $select = $connection->select()->from($table, ['entity_id', 'old_column'])
                ->where('entity_id > ?', $lastId)->where('new_column IS NULL')
                ->order('entity_id ASC')->limit(self::BATCH_SIZE);
            $rows = $connection->fetchAll($select);
            foreach ($rows as $row) {
                $connection->update($table, [
                    'new_column' => $this->transform($row['old_column']),
                ], ['entity_id = ?' => $row['entity_id']]);
                $lastId = (int)$row['entity_id'];
            }
        } while (count($rows) === self::BATCH_SIZE);

        return $this;
    }

    public static function getDependencies(): array { return []; }
    public function getAliases(): array { return []; }
}
```

## Recurring Data Patches

Recurring patches run on every `setup:upgrade`. For true recurring execution, use `Setup/RecurringData.php` implementing `\Magento\Framework\Setup\InstallDataInterface` -- Magento runs this on every `setup:upgrade` regardless of patch history.

```php
// Standard file header — see _shared/conventions.md
namespace Vendor\ModuleName\Setup;

use Magento\Framework\Setup\InstallDataInterface;
use Magento\Framework\Setup\ModuleContextInterface;
use Magento\Framework\Setup\ModuleDataSetupInterface;

final class RecurringData implements InstallDataInterface
{
    public function install(ModuleDataSetupInterface $setup, ModuleContextInterface $context): void
    {
        // Runs on every setup:upgrade — refresh lookup tables, sync static data, etc.
    }
}
```

## Safe Migration Strategies

### Transaction Boundaries

```php
$connection->beginTransaction();
try {
    $connection->delete($table, ['status = ?' => 'obsolete']);
    $connection->insertMultiple($table, $newRows);
    $connection->commit();
} catch (\Throwable $e) {
    $connection->rollBack();
    throw $e;
}
```

### Dry-Run Mode

Use a config flag to test migrations without committing:

```php
if ($this->scopeConfig->isSetFlag('vendor_module/migration/dry_run')) {
    $this->logger->info('Dry run: would update ' . count($rows) . ' rows');
    return $this;
}
```

### Rollback Strategies

- **Backup table:** `CREATE TABLE my_table_bak AS SELECT * FROM my_table` before destructive changes.
- **Soft deletes:** Add `is_deleted` flag instead of removing rows. Purge after verification.
- **Versioned columns:** Keep both `old_column` and `new_column` during transition. Drop old in a subsequent release.

## Performance Tips

### Disable Indexers During Migration

```php
$indexer = $this->indexerRegistry->get('catalog_product_price');
$wasScheduled = $indexer->isScheduled();
$indexer->setScheduled(true); // switch to "Update by Schedule"
// ... perform migration ...
$indexer->setScheduled($wasScheduled); // restore
```

### Bulk Operations

```php
// Insert many rows in one query
$connection->insertMultiple($table, $batchOfRows);

// Upsert: insert or update on duplicate key
$connection->insertOnDuplicate($table, $batchOfRows, ['name', 'updated_at']);
```

### Memory Management with Generators

```php
private function fetchInChunks(string $table, int $size): \Generator
{
    $lastId = 0;
    $connection = $this->resourceConnection->getConnection();
    do {
        $select = $connection->select()->from($table)
            ->where('entity_id > ?', $lastId)->order('entity_id ASC')->limit($size);
        $rows = $connection->fetchAll($select);
        foreach ($rows as $row) {
            $lastId = (int)$row['entity_id'];
            yield $row;
        }
    } while (count($rows) === $size);
}
```

Unset large arrays after each batch: `unset($rows);`

## Data Conversion Patterns

### Serialized to JSON

Magento provides a built-in converter:

```php
$fieldConverter = $this->fieldDataConverterFactory->create(
    \Magento\Framework\DB\DataConverter\SerializedToJson::class
);
$fieldConverter->convert($connection, $table, 'entity_id', 'serialized_column');
```

### Column Type Change with Data Preservation

When changing a column type in `db_schema.xml`, create a data patch that runs **before** the schema change (use `getDependencies()`). Copy data to a temp column, let schema alter the original, then backfill.

### Flat to EAV Migration

1. Create the EAV attribute via a data patch (use `/m2-eav-attributes`).
2. Query the flat table for source data.
3. Insert into the EAV value table (`catalog_product_entity_varchar`, etc.) using `insertOnDuplicate()` keyed on `entity_id` + `attribute_id` + `store_id` for idempotency.
