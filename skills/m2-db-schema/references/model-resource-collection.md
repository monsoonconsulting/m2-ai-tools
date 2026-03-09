# Model / ResourceModel / Collection Templates

> Companion file for m2-db-schema. Also referenced by m2-api-builder and m2-admin-ui.

## Model — `Model/{Entity}.php`

```php
<?php
/**
 * Copyright © Monsoon Consulting. All rights reserved.
 * See LICENSE_MONSOON.txt for license details.
 */

declare(strict_types=1);

namespace {Vendor}\{ModuleName}\Model;

use Magento\Framework\Model\AbstractModel;
use {Vendor}\{ModuleName}\Model\ResourceModel\{Entity} as {Entity}Resource;

final class {Entity} extends AbstractModel
{
    protected function _construct(): void
    {
        $this->_init({Entity}Resource::class);
    }
}
```

### Model implementing Data Interface

When the entity has a service contract (Data Interface), the Model should implement it:

```php
<?php
/**
 * Copyright © Monsoon Consulting. All rights reserved.
 * See LICENSE_MONSOON.txt for license details.
 */

declare(strict_types=1);

namespace {Vendor}\{ModuleName}\Model;

use Magento\Framework\Model\AbstractModel;
use {Vendor}\{ModuleName}\Api\Data\{Entity}Interface;
use {Vendor}\{ModuleName}\Model\ResourceModel\{Entity} as {Entity}Resource;

final class {Entity} extends AbstractModel implements {Entity}Interface
{
    protected function _construct(): void
    {
        $this->_init({Entity}Resource::class);
    }

    public function getTitle(): ?string
    {
        return $this->getData(self::TITLE);
    }

    public function setTitle(string $title): self
    {
        return $this->setData(self::TITLE, $title);
    }

    // ... implement all interface methods as getData/setData pairs
}
```

## ResourceModel — `Model/ResourceModel/{Entity}.php`

```php
<?php
/**
 * Copyright © Monsoon Consulting. All rights reserved.
 * See LICENSE_MONSOON.txt for license details.
 */

declare(strict_types=1);

namespace {Vendor}\{ModuleName}\Model\ResourceModel;

use Magento\Framework\Model\ResourceModel\Db\AbstractDb;

final class {Entity} extends AbstractDb
{
    protected function _construct(): void
    {
        $this->_init('{table_name}', 'entity_id');
    }
}
```

## Collection — `Model/ResourceModel/{Entity}/Collection.php`

```php
<?php
/**
 * Copyright © Monsoon Consulting. All rights reserved.
 * See LICENSE_MONSOON.txt for license details.
 */

declare(strict_types=1);

namespace {Vendor}\{ModuleName}\Model\ResourceModel\{Entity};

use Magento\Framework\Model\ResourceModel\Db\Collection\AbstractCollection;
use {Vendor}\{ModuleName}\Model\{Entity};
use {Vendor}\{ModuleName}\Model\ResourceModel\{Entity} as {Entity}Resource;

final class Collection extends AbstractCollection
{
    protected function _construct(): void
    {
        $this->_init({Entity}::class, {Entity}Resource::class);
    }
}
```

## When to Create These

- **Always** create all three when your module has a `db_schema.xml` table that will be accessed via PHP code
- The Model is your entity's PHP representation
- The ResourceModel handles database CRUD operations
- The Collection handles loading multiple entities with filtering/sorting
- If using service contracts (`/m2-api-builder`), the Model should implement the Data Interface
