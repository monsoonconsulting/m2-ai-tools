# AbstractEntity Contract Reference

The `Magento\ImportExport\Model\Import\Entity\AbstractEntity` base class defines the contract for custom import entities. Your import class extends this and implements the required methods.

## Required Methods

| Method | Signature | Description |
|--------|-----------|-------------|
| `getEntityTypeCode()` | `public function getEntityTypeCode(): string` | Return the entity type code matching `etc/import.xml` |
| `validateRow()` | `public function validateRow(array $rowData, $rowNumber): bool` | Validate a single CSV row; return `true` if valid |
| `_importData()` | `protected function _importData(): bool` | Process all validated data; return `true` on success |
| `getValidColumnNames()` | `public function getValidColumnNames(): array` | Return array of valid CSV column names |

## Key Properties

| Property | Type | Description |
|----------|------|-------------|
| `$validColumnNames` | `string[]` | Allowed column names for the CSV |
| `$needColumnCheck` | `bool` | Whether to validate column headers (default: `true`) |
| `$logInHistory` | `bool` | Whether to log import in history (default: `true`) |
| `$_validatedRows` | `array` | Cache of already-validated row numbers |
| `$countItemsCreated` | `int` | Counter for newly created items |
| `$countItemsUpdated` | `int` | Counter for updated items |
| `$countItemsDeleted` | `int` | Counter for deleted items |

## Lifecycle Hooks

The import process follows this order:

1. **Column validation** — Magento validates CSV headers against `getValidColumnNames()` if `$needColumnCheck` is `true`.
2. **Row validation** — `validateRow()` is called for every row in the CSV. Errors are collected in the error aggregator.
3. **Import execution** — If validation passes (within error threshold), `_importData()` is called.
4. **Summary** — Magento displays counts from `$countItemsCreated`, `$countItemsUpdated`, `$countItemsDeleted`.

## Error Handling

### Adding Row Errors

```php
$this->addRowError(
    'Error message or error code',  // string — error message
    $rowNumber,                      // int — CSV row number (0-based)
    $columnName                      // string|null — column that caused error
);
```

### Error Aggregator

Access via `$this->getErrorAggregator()`:

```php
// Check if a row has errors
$this->getErrorAggregator()->isRowInvalid($rowNumber);

// Get total error count
$this->getErrorAggregator()->getErrorsCount();

// Check if import should stop (exceeds allowed error count)
$this->getErrorAggregator()->hasToBeTerminated();
```

### Error Levels

| Level | Constant | Effect |
|-------|----------|--------|
| Critical | `ProcessingError::ERROR_LEVEL_CRITICAL` | Import stops immediately |
| Not Critical | `ProcessingError::ERROR_LEVEL_NOT_CRITICAL` | Row skipped, import continues |

## Batch Processing with `_getNextBunch()`

```php
while ($bunch = $this->_getNextBunch()) {
    foreach ($bunch as $rowNumber => $rowData) {
        // Process each row
    }
}
```

The `_getNextBunch()` method returns the next batch of validated rows from the temporary import table. Batch size is configured in the admin under **System > Import** (default: 5000 rows per bunch). Always process bunches in a while loop until `null` is returned.

## Getting Import Behavior

```php
$behavior = $this->getBehavior();

// Compare against constants:
// \Magento\ImportExport\Model\Import::BEHAVIOR_APPEND
// \Magento\ImportExport\Model\Import::BEHAVIOR_REPLACE
// \Magento\ImportExport\Model\Import::BEHAVIOR_DELETE
```
