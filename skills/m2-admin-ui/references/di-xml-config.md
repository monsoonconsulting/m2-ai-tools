# DI Configuration for Admin Grid

## Grid Collection Registration in `etc/di.xml`

The listing UI component uses `Magento\Framework\View\Element\UiComponent\DataProvider\DataProvider` as its data provider class. This class looks up the collection to use via `CollectionFactory`, which is configured through di.xml arguments.

Add these nodes to `etc/di.xml` (create or merge into existing):

```xml
<config xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
        xsi:noNamespaceSchemaLocation="urn:magento:framework:ObjectManager/etc/config.xsd">

    <!-- Register the grid collection with the UI component data provider -->
    <type name="Magento\Framework\View\Element\UiComponent\DataProvider\CollectionFactory">
        <arguments>
            <argument name="collections" xsi:type="array">
                <item name="{entity_snake}_listing_data_source" xsi:type="string">
                    {Vendor}\{ModuleName}\Model\ResourceModel\{Entity}\Grid\Collection
                </item>
            </argument>
        </arguments>
    </type>

    <!-- Configure the Grid Collection virtual arguments -->
    <type name="{Vendor}\{ModuleName}\Model\ResourceModel\{Entity}\Grid\Collection">
        <arguments>
            <argument name="mainTable" xsi:type="string">{table_name}</argument>
            <argument name="eventPrefix" xsi:type="string">{entity_snake}_grid_collection</argument>
            <argument name="eventObject" xsi:type="string">{entity_snake}_grid_collection</argument>
            <argument name="resourceModel" xsi:type="string">{Vendor}\{ModuleName}\Model\ResourceModel\{Entity}</argument>
        </arguments>
    </type>
</config>
```

**Key mapping:**
- `{entity_snake}_listing_data_source` — must exactly match the `<dataSource name="...">` in the listing UI component XML.
- `{table_name}` — the actual database table name (e.g., `acme_blog_post`).
- `resourceModel` — the fully qualified ResourceModel class name.

## Grid Collection Class — `Model/ResourceModel/{Entity}/Grid/Collection.php`

This class extends the entity's regular Collection and implements `SearchResultInterface`, which the UI component data provider requires.

```php
<?php
/**
 * Copyright © Monsoon Consulting. All rights reserved.
 * See LICENSE_MONSOON.txt for license details.
 */

declare(strict_types=1);

namespace {Vendor}\{ModuleName}\Model\ResourceModel\{Entity}\Grid;

use {Vendor}\{ModuleName}\Model\ResourceModel\{Entity}\Collection as {Entity}Collection;
use Magento\Framework\Api\Search\AggregationInterface;
use Magento\Framework\Api\Search\SearchResultInterface;
use Magento\Framework\Api\SearchCriteriaInterface;
use Magento\Framework\Data\Collection\Db\FetchStrategyInterface;
use Magento\Framework\Data\Collection\EntityFactoryInterface;
use Magento\Framework\DB\Adapter\AdapterInterface;
use Magento\Framework\Event\ManagerInterface;
use Magento\Framework\Model\ResourceModel\Db\AbstractDb;
use Psr\Log\LoggerInterface;

class Collection extends {Entity}Collection implements SearchResultInterface
{
    private AggregationInterface $aggregations;

    public function __construct(
        EntityFactoryInterface $entityFactory,
        LoggerInterface $logger,
        FetchStrategyInterface $fetchStrategy,
        ManagerInterface $eventManager,
        string $mainTable,
        string $eventPrefix,
        string $eventObject,
        string $resourceModel,
        string $model = \Magento\Framework\View\Element\UiComponent\DataProvider\Document::class,
        ?AdapterInterface $connection = null,
        ?AbstractDb $resource = null
    ) {
        parent::__construct($entityFactory, $logger, $fetchStrategy, $eventManager, $connection, $resource);
        $this->_eventPrefix = $eventPrefix;
        $this->_eventObject = $eventObject;
        $this->_init($model, $resourceModel);
        $this->setMainTable($mainTable);
    }

    public function getAggregations(): AggregationInterface
    {
        return $this->aggregations;
    }

    public function setAggregations($aggregations): self
    {
        $this->aggregations = $aggregations;

        return $this;
    }

    public function getSearchCriteria(): ?SearchCriteriaInterface
    {
        return null;
    }

    public function setSearchCriteria(?SearchCriteriaInterface $searchCriteria = null): self
    {
        return $this;
    }

    public function getTotalCount(): int
    {
        return $this->getSize();
    }

    public function setTotalCount($totalCount): self
    {
        return $this;
    }

    public function setItems(?array $items = null): self
    {
        return $this;
    }
}
```

## How It Works

1. The listing UI component XML declares a `<dataProvider>` with the generic `Magento\Framework\View\Element\UiComponent\DataProvider\DataProvider` class.
2. That class asks `CollectionFactory` for a collection matching the data source name (`{entity_snake}_listing_data_source`).
3. The `CollectionFactory` looks up the class from its `collections` argument in di.xml — which maps to the `Grid\Collection` class.
4. The `Grid\Collection` extends the entity's real collection but overrides the model to `Document` (required by the data provider) and implements `SearchResultInterface` (required for filtering, sorting, and pagination).

## Notes

- The `$model` defaults to `Magento\Framework\View\Element\UiComponent\DataProvider\Document` — this is the standard UI component document model. Do NOT change this.
- The `getSearchCriteria()` returning `null` and the no-op `setSearchCriteria()`/`setTotalCount()`/`setItems()` are the standard pattern from Magento core (e.g., `Magento\Cms\Model\ResourceModel\Page\Grid\Collection`).
- The `aggregations` property is used for faceted search in the grid — it's required by the interface even if not actively used.
