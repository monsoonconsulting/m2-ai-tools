# Form DataProvider Template

## `Model/{Entity}/DataProvider.php`

Extends `Magento\Ui\DataProvider\ModifierPoolDataProvider`. Uses the entity collection for loading and `DataPersistor` for form error recovery.

```php
<?php
/**
 * Copyright © Monsoon Consulting. All rights reserved.
 * See LICENSE_MONSOON.txt for license details.
 */

declare(strict_types=1);

namespace {Vendor}\{ModuleName}\Model\{Entity};

use {Vendor}\{ModuleName}\Model\ResourceModel\{Entity}\CollectionFactory;
use Magento\Framework\App\Request\DataPersistorInterface;
use Magento\Ui\DataProvider\ModifierPoolDataProvider;
use Magento\Ui\DataProvider\Modifier\PoolInterface;

class DataProvider extends ModifierPoolDataProvider
{
    private ?array $loadedData = null;

    public function __construct(
        string $name,
        string $primaryFieldName,
        string $requestFieldName,
        CollectionFactory $collectionFactory,
        private readonly DataPersistorInterface $dataPersistor,
        array $meta = [],
        array $data = [],
        ?PoolInterface $pool = null
    ) {
        $this->collection = $collectionFactory->create();
        parent::__construct($name, $primaryFieldName, $requestFieldName, $meta, $data, $pool);
    }

    public function getData(): array
    {
        if ($this->loadedData !== null) {
            return $this->loadedData;
        }

        $this->loadedData = [];
        $items = $this->collection->getItems();

        foreach ($items as $entity) {
            $this->loadedData[$entity->getId()] = $entity->getData();
        }

        $data = $this->dataPersistor->get('{entity_snake}');
        if (!empty($data)) {
            $entity = $this->collection->getNewEmptyItem();
            $entity->setData($data);
            $this->loadedData[$entity->getId()] = $entity->getData();
            $this->dataPersistor->clear('{entity_snake}');
        }

        return $this->loadedData;
    }
}
```

## How It Works

1. **Normal load:** The collection loads the entity matching the request ID. `getData()` returns its data keyed by entity ID.
2. **Error recovery:** If the Save controller failed and stored data via `DataPersistor::set('{entity_snake}', $data)`, the DataProvider picks it up and repopulates the form so the user doesn't lose their input.
3. **`$this->loadedData` cache:** Prevents redundant collection loads on repeated `getData()` calls during the same request.

## Notes

- The `{entity_snake}` key in `DataPersistor` must match the key used in the Save controller.
- `$this->collection` is set directly in the constructor (before `parent::__construct()`) because `ModifierPoolDataProvider` expects it as a property.
- The `$pool` parameter enables modifier plugins to transform form data (e.g., image URL processing). Pass `null` if no modifiers are needed.
- Do NOT use `Magento\Framework\Registry` (core registry) — it is deprecated. DataPersistor is the correct approach.
