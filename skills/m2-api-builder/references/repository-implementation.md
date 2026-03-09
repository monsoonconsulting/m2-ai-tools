# Repository Implementation Template

## Model/{Entity}Repository.php

```php
<?php
/**
 * Copyright © Monsoon Consulting. All rights reserved.
 * See LICENSE_MONSOON.txt for license details.
 */

declare(strict_types=1);

namespace {Vendor}\{ModuleName}\Model;

use {Vendor}\{ModuleName}\Api\{Entity}RepositoryInterface;
use {Vendor}\{ModuleName}\Api\Data\{Entity}Interface;
use {Vendor}\{ModuleName}\Api\Data\{Entity}SearchResultsInterface;
use {Vendor}\{ModuleName}\Api\Data\{Entity}SearchResultsInterfaceFactory;
use {Vendor}\{ModuleName}\Model\ResourceModel\{Entity} as {Entity}Resource;
use {Vendor}\{ModuleName}\Model\ResourceModel\{Entity}\CollectionFactory;
use Magento\Framework\Api\SearchCriteria\CollectionProcessorInterface;
use Magento\Framework\Api\SearchCriteriaInterface;
use Magento\Framework\Exception\CouldNotDeleteException;
use Magento\Framework\Exception\CouldNotSaveException;
use Magento\Framework\Exception\NoSuchEntityException;

final class {Entity}Repository implements {Entity}RepositoryInterface
{
    public function __construct(
        private readonly {Entity}Resource $resource,
        private readonly {Entity}Factory $entityFactory,
        private readonly CollectionFactory $collectionFactory,
        private readonly CollectionProcessorInterface $collectionProcessor,
        private readonly {Entity}SearchResultsInterfaceFactory $searchResultsFactory
    ) {
    }

    public function getById(int $entityId): {Entity}Interface
    {
        $entity = $this->entityFactory->create();
        $this->resource->load($entity, $entityId);

        if (!$entity->getEntityId()) {
            throw new NoSuchEntityException(
                __('The entity with id "%1" does not exist.', $entityId)
            );
        }

        return $entity;
    }

    public function save({Entity}Interface $entity): {Entity}Interface
    {
        try {
            $this->resource->save($entity);
        } catch (\Exception $e) {
            throw new CouldNotSaveException(__('Could not save the entity: %1', $e->getMessage()), $e);
        }

        return $entity;
    }

    public function delete({Entity}Interface $entity): bool
    {
        try {
            $this->resource->delete($entity);
        } catch (\Exception $e) {
            throw new CouldNotDeleteException(__('Could not delete the entity: %1', $e->getMessage()), $e);
        }

        return true;
    }

    public function deleteById(int $entityId): bool
    {
        return $this->delete($this->getById($entityId));
    }

    public function getList(SearchCriteriaInterface $searchCriteria): {Entity}SearchResultsInterface
    {
        $collection = $this->collectionFactory->create();
        $this->collectionProcessor->process($searchCriteria, $collection);

        $searchResults = $this->searchResultsFactory->create();
        $searchResults->setSearchCriteria($searchCriteria);
        $searchResults->setItems($collection->getItems());
        $searchResults->setTotalCount($collection->getSize());

        return $searchResults;
    }
}
```

**SearchCriteria usage note:** The `CollectionProcessorInterface` handles filtering, sorting, and pagination automatically from SearchCriteria. API consumers use query parameters like `?searchCriteria[filterGroups][0][filters][0][field]=is_active&searchCriteria[filterGroups][0][filters][0][value]=1&searchCriteria[pageSize]=20&searchCriteria[currentPage]=1`. No additional pagination code is needed in the repository.
