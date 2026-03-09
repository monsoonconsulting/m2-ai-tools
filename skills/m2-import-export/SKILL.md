---
name: m2-import-export
description: >
  Generate custom Magento 2 entity import/export code including import.xml registration,
  import entity classes, export entity classes, column validation, and batch processing.
  Use this skill when the user asks to create custom import, custom export, bulk import,
  CSV import, or entity import/export functionality.
  Trigger on: "import", "export", "CSV import", "bulk import", "import entity",
  "export entity", "import.xml", "AbstractEntity", "ImportInterface",
  "custom import", "custom export", "data import", "file import",
  "mass import", "batch import", "import validation", "import behavior".
---

# Magento 2 Custom Entity Import/Export Generator

You are a Magento 2 import/export specialist. Generate custom entity import and export classes, XML registration, validation logic, and batch processing under existing modules in `app/code/{Vendor}/{ModuleName}/`.

Follow the coding conventions and file headers defined in `.claude/skills/_shared/conventions.md` and `.claude/skills/m2-module/SKILL.md`. Do not duplicate those conventions here.

**Prerequisites:** Module must exist (see `_shared/conventions.md`). If not, use `/m2-module` first. The module must require `magento/module-import-export`.

## 1. Decision Tree

**Use custom import/export when:**
- You need to bulk import/export entities via CSV through the admin System > Import/Export interface
- The entity has a flat data structure that maps well to CSV columns
- You need validation, error aggregation, and batch processing for large datasets
- You want to leverage Magento's built-in import behaviors (append, replace, delete)

**Use data patches (`/m2-db-schema`) instead when:**
- You need a one-time data migration during module setup
- The data is static and does not come from external files

**Use REST API (`/m2-api-builder`) instead when:**
- You need programmatic real-time entity creation/updates from external systems
- The data source is an API, not a CSV file

**Use message queues (`/m2-message-queue`) instead when:**
- You need async background processing of individual records
- Import is triggered by events rather than file uploads

## 2. Gather Requirements

Before generating any files, collect the following from the user.

**Required (ask if not provided):**
- **Module name** — `Vendor_ModuleName`
- **Entity type code** — unique identifier for the import entity (e.g., `custom_entity`)
- **Entity label** — human-readable name shown in admin import dropdown (e.g., "Custom Entities")
- **CSV columns** — list of columns with types and validation rules

**Optional (use defaults if not specified):**
- **Import behaviors** — default: `append`, `replace`, `delete` (all three)
- **Batch size** — default: `100`
- **Unique identifier column** — default: first column (used for replace/delete matching)
- **Export support** — default: no (import only)
- **Target table** — default: derive from entity type code

## 3. Naming Conventions

| Concept | Convention | Example |
|---------|-----------|---------|
| Entity type code | `{snake_case}` | `custom_entity` |
| Import model class | `Model\Import\{EntityName}` | `Model\Import\CustomEntity` |
| Export model class | `Model\Export\{EntityName}` | `Model\Export\CustomEntity` |
| Import XML | `etc/import.xml` | |
| Export XML | `etc/export.xml` | |
| Validator class | `Model\Import\{EntityName}\Validator` | `Model\Import\CustomEntity\Validator` |

## 4. Import Entity XML — `etc/import.xml`

```xml
<?xml version="1.0"?>
<!--
/**
 * Copyright © Monsoon Consulting. All rights reserved.
 * See LICENSE_MONSOON.txt for license details.
 */
-->
<config xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
        xsi:noNamespaceSchemaLocation="urn:magento:module:Magento_ImportExport:etc/import.xsd">
    <entity name="{entity_type_code}"
            label="{Entity Label}"
            model="{Vendor}\{ModuleName}\Model\Import\{EntityName}"
            behaviorModel="Magento\ImportExport\Model\Source\Import\Behavior\Basic"/>
</config>
```

If `etc/import.xml` already exists, append the new `<entity>` inside the existing `<config>` root.

### Behavior Models

| Behavior Model | Supported Behaviors | Use When |
|---------------|--------------------|-|
| `Basic` | append, replace, delete | Standard entity with unique identifier |
| `Custom` | append, delete | Entities that don't support full replace |

## 5. Import Entity Class — `Model/Import/{EntityName}.php`

```php
<?php
/**
 * Copyright © Monsoon Consulting. All rights reserved.
 * See LICENSE_MONSOON.txt for license details.
 */

declare(strict_types=1);

namespace {Vendor}\{ModuleName}\Model\Import;

use Magento\ImportExport\Model\Import;
use Magento\ImportExport\Model\Import\AbstractEntity;
use Magento\ImportExport\Model\Import\ErrorProcessing\ProcessingErrorAggregatorInterface;
use Magento\ImportExport\Model\ResourceModel\Helper;
use Magento\ImportExport\Model\ResourceModel\Import\Data as ImportData;
use Magento\Framework\App\ResourceConnection;
use Magento\Framework\Json\Helper\Data as JsonHelper;
use Magento\Framework\Stdlib\StringUtils;

// Cannot be final — must extend AbstractEntity and access its protected methods/properties
class {EntityName} extends AbstractEntity
{
    public const ENTITY_CODE = '{entity_type_code}';
    public const TABLE_NAME = '{table_name}';

    private const BATCH_SIZE = 100;

    protected $needColumnCheck = true;
    protected $logInHistory = true;

    /** @var string[] */
    protected $validColumnNames = [
        '{identifier_column}',
        '{column_2}',
        '{column_3}',
    ];

    private ResourceConnection $resource;

    public function __construct(
        JsonHelper $jsonHelper,
        ProcessingErrorAggregatorInterface $errorAggregator,
        ImportData $importExportData,
        ResourceConnection $resource,
        Helper $resourceHelper,
        StringUtils $string,
        array $data = []
    ) {
        $this->resource = $resource;
        parent::__construct($jsonHelper, $importExportData, $resourceHelper, $string, $errorAggregator, $data);
    }

    public function getEntityTypeCode(): string
    {
        return self::ENTITY_CODE;
    }

    public function getValidColumnNames(): array
    {
        return $this->validColumnNames;
    }

    /**
     * Validate a single row of import data.
     */
    public function validateRow(array $rowData, $rowNumber): bool
    {
        if (isset($this->_validatedRows[$rowNumber])) {
            return !$this->getErrorAggregator()->isRowInvalid($rowNumber);
        }

        $this->_validatedRows[$rowNumber] = true;

        // Required field validation
        if (empty($rowData['{identifier_column}'])) {
            $this->addRowError(
                '{identifier_column} is required',
                $rowNumber,
                '{identifier_column}'
            );
            return false;
        }

        // Add custom validation rules here
        // Example: validate data types, ranges, foreign keys

        return !$this->getErrorAggregator()->isRowInvalid($rowNumber);
    }

    /**
     * Import data — called after all rows pass validation.
     */
    protected function _importData(): bool
    {
        $behavior = $this->getBehavior();

        switch ($behavior) {
            case Import::BEHAVIOR_APPEND:
            case Import::BEHAVIOR_REPLACE:
                $this->saveEntities();
                break;
            case Import::BEHAVIOR_DELETE:
                $this->deleteEntities();
                break;
        }

        return true;
    }

    /**
     * Save (insert or update) entities in batches.
     */
    private function saveEntities(): void
    {
        $connection = $this->resource->getConnection();
        $tableName = $this->resource->getTableName(self::TABLE_NAME);
        $batch = [];

        while ($rowData = $this->_getNextBunch()) {
            foreach ($rowData as $row) {
                $batch[] = [
                    '{identifier_column}' => $row['{identifier_column}'],
                    '{column_2}' => $row['{column_2}'] ?? null,
                    '{column_3}' => $row['{column_3}'] ?? null,
                ];

                if (count($batch) >= self::BATCH_SIZE) {
                    $connection->insertOnDuplicate($tableName, $batch, ['{column_2}', '{column_3}']);
                    $this->countItemsCreated += count($batch);
                    $batch = [];
                }
            }
        }

        if (!empty($batch)) {
            $connection->insertOnDuplicate($tableName, $batch, ['{column_2}', '{column_3}']);
            $this->countItemsCreated += count($batch);
        }
    }

    /**
     * Delete entities matching the identifier column.
     */
    private function deleteEntities(): void
    {
        $connection = $this->resource->getConnection();
        $tableName = $this->resource->getTableName(self::TABLE_NAME);
        $ids = [];

        while ($rowData = $this->_getNextBunch()) {
            foreach ($rowData as $row) {
                if (!empty($row['{identifier_column}'])) {
                    $ids[] = $row['{identifier_column}'];
                }
            }
        }

        if (!empty($ids)) {
            $connection->delete($tableName, ['{identifier_column} IN (?)' => $ids]);
            $this->countItemsDeleted += count($ids);
        }
    }
}
```

For the full `AbstractEntity` contract reference including lifecycle hooks and error handling, see `references/import-entity-contract.md`.

## 6. Custom Validator (Optional) — `Model/Import/{EntityName}/Validator.php`

For complex validation rules, extract validation into a dedicated class:

```php
// Standard file header — see _shared/conventions.md

namespace {Vendor}\{ModuleName}\Model\Import\{EntityName};

final class Validator
{
    /**
     * @return string[] Array of error messages (empty if valid)
     */
    public function validate(array $rowData): array
    {
        $errors = [];

        if (empty($rowData['{identifier_column}'])) {
            $errors[] = '{identifier_column} is required';
        }

        if (isset($rowData['{column_2}']) && strlen($rowData['{column_2}']) > 255) {
            $errors[] = '{column_2} must be 255 characters or less';
        }

        // Numeric validation
        if (isset($rowData['{numeric_column}']) && !is_numeric($rowData['{numeric_column}'])) {
            $errors[] = '{numeric_column} must be a number';
        }

        return $errors;
    }
}
```

Inject the `Validator` into the import entity class constructor and call it from `validateRow()`.

## 7. Export Entity (Optional)

### 7.1 Export XML — `etc/export.xml`

```xml
<?xml version="1.0"?>
// Standard file header — see _shared/conventions.md
<config xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
        xsi:noNamespaceSchemaLocation="urn:magento:module:Magento_ImportExport:etc/export.xsd">
    <entity name="{entity_type_code}"
            label="{Entity Label}"
            model="{Vendor}\{ModuleName}\Model\Export\{EntityName}"
            entityAttributeFilterType="basic"/>
</config>
```

### 7.2 Export Entity Class — `Model/Export/{EntityName}.php`

```php
// Standard file header — see _shared/conventions.md

namespace {Vendor}\{ModuleName}\Model\Export;

use Magento\Framework\App\ResourceConnection;
use Magento\ImportExport\Model\Export\AbstractEntity;

class {EntityName} extends AbstractEntity
{
    public const ENTITY_CODE = '{entity_type_code}';
    public const TABLE_NAME = '{table_name}';

    private ResourceConnection $resource;

    public function __construct(
        \Magento\Framework\App\Config\ScopeConfigInterface $scopeConfig,
        \Magento\Store\Model\StoreManagerInterface $storeManager,
        \Magento\ImportExport\Model\Export\Factory $collectionFactory,
        \Magento\ImportExport\Model\ResourceModel\CollectionByPagesIteratorFactory $resourceColFactory,
        ResourceConnection $resource,
        array $data = []
    ) {
        $this->resource = $resource;
        parent::__construct($scopeConfig, $storeManager, $collectionFactory, $resourceColFactory, $data);
    }

    public function getEntityTypeCode(): string
    {
        return self::ENTITY_CODE;
    }

    public function export(): string
    {
        $writer = $this->getWriter();
        $connection = $this->resource->getConnection();
        $tableName = $this->resource->getTableName(self::TABLE_NAME);

        $select = $connection->select()->from($tableName);

        // Apply export filters if set
        $this->_applyFilters($select);

        $headerColumns = $this->_getHeaderColumns();
        $writer->setHeaderCols($headerColumns);

        $stmt = $connection->query($select);
        while ($row = $stmt->fetch()) {
            $writer->writeRow($this->_prepareRowData($row));
        }

        return $writer->getContents();
    }

    protected function _getHeaderColumns(): array
    {
        return ['{identifier_column}', '{column_2}', '{column_3}'];
    }

    protected function _getEntityCollection(): \Magento\Framework\Data\Collection\AbstractDb
    {
        // Not used when overriding export() directly
        throw new \RuntimeException('Not implemented');
    }

    public function getAttributeCollection(): \Magento\Framework\Data\Collection
    {
        return new \Magento\Framework\Data\Collection();
    }

    private function _applyFilters(\Magento\Framework\DB\Select $select): void
    {
        foreach ($this->_parameters[\Magento\ImportExport\Model\Export::FILTER_ELEMENT_GROUP] ?? [] as $field => $value) {
            if (!empty($value)) {
                $select->where("{$field} = ?", $value);
            }
        }
    }

    private function _prepareRowData(array $row): array
    {
        // Transform or filter columns before export
        return $row;
    }
}
```

## 8. Import Behaviors

| Behavior | Constant | Description |
|----------|----------|-------------|
| Append | `Import::BEHAVIOR_APPEND` | Insert new rows. Update existing rows matched by identifier. |
| Replace | `Import::BEHAVIOR_REPLACE` | Delete all existing rows, then insert all CSV rows. |
| Delete | `Import::BEHAVIOR_DELETE` | Delete rows matching the identifier column from CSV. |

When using **Append** behavior with `insertOnDuplicate()`, the second argument specifies which columns to update on duplicate key. The identifier column acts as the unique key.

## 9. Sample CSV Documentation

When generating an import entity, also provide a sample CSV header for the user:

```csv
{identifier_column},{column_2},{column_3}
"value1","Value Two","Value Three"
"value2","Another","Example"
```

Include this as a comment in the import class or as a separate reference for users.

## 10. Generation Rules

Follow this sequence when generating import/export code:

1. **Verify the module exists** — check `registration.php`.

2. **Check module dependency** — ensure `Magento_ImportExport` is listed in `etc/module.xml` sequence. If not, add it.

3. **Create `etc/import.xml`** — register the import entity with entity code, label, model class, and behavior model. If the file exists, append the new `<entity>` element.

4. **Create the import entity class** — `Model/Import/{EntityName}.php` extending `AbstractEntity`. Implement `validateRow()`, `_importData()`, `getEntityTypeCode()`, and `getValidColumnNames()`.

5. **Create validator class** (if complex validation) — `Model/Import/{EntityName}/Validator.php`.

6. **Create export XML and class** (if export requested) — `etc/export.xml` and `Model/Export/{EntityName}.php`.

7. **Document sample CSV** — provide column names and example rows.

8. **Remind the user** to run post-generation commands.

## 11. Anti-Patterns

**No validation in `validateRow()`.**
Always validate required fields, data types, and value ranges. The `validateRow()` method runs before `_importData()` — it is the gatekeeper. Skipping validation leads to corrupt data and SQL errors.

**Missing error aggregation.**
Use `$this->addRowError()` to register validation errors with row numbers. This gives admins clear feedback on which rows failed and why. Never silently skip invalid rows.

**Loading the entire CSV into memory.**
Always use `$this->_getNextBunch()` to process data in batches. Magento splits the CSV into bunches (default 5000 rows). Processing one bunch at a time keeps memory usage constant regardless of file size.

**Using raw SQL instead of `insertOnDuplicate()`.**
The `insertOnDuplicate()` method handles both insert and update in a single query, is injection-safe, and is optimized for batch operations. Manual SQL string building is error-prone and unsafe.

**Not counting created/updated/deleted items.**
Increment `$this->countItemsCreated`, `$this->countItemsUpdated`, and `$this->countItemsDeleted` to provide accurate import summary statistics in the admin UI.

**Ignoring the delete behavior.**
If your import.xml uses `Basic` behavior model, you must handle `Import::BEHAVIOR_DELETE` in `_importData()`. Otherwise, the delete option in the admin will silently do nothing.

**Hardcoding table names without `getTableName()`.**
Always use `$this->resource->getTableName()` to resolve table names. This ensures table prefix compatibility.

## 12. Post-Generation Steps

After generating the import/export code, remind the user to run:

```bash
bin/magento setup:upgrade
bin/magento setup:di:compile
bin/magento cache:flush
```

If the module was not yet enabled:
```bash
bin/magento module:enable {Vendor}_{ModuleName}
bin/magento setup:upgrade
bin/magento setup:di:compile
bin/magento cache:flush
```

**Verification:**
- **Import:** Go to **System > Data Transfer > Import**. The new entity type should appear in the "Entity Type" dropdown. Upload a sample CSV and verify validation and import results.
- **Export:** Go to **System > Data Transfer > Export**. The new entity type should appear in the "Entity Type" dropdown. Run an export and verify the CSV output.
