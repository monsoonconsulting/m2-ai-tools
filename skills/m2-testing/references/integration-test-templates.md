# Integration Test Extended Templates

Reference file for `.claude/skills/m2-testing/SKILL.md`. Contains detailed integration test templates, fixture patterns, and admin controller tests.

## Admin Controller Integration Test

Uses `AbstractBackendController` which handles admin authentication automatically.

```php
<?php
/**
 * Copyright © Monsoon Consulting. All rights reserved.
 * See LICENSE_MONSOON.txt for license details.
 */

declare(strict_types=1);

namespace {Vendor}\{ModuleName}\Test\Integration\Controller\Adminhtml;

use Magento\TestFramework\TestCase\AbstractBackendController;

/**
 * @magentoDbIsolation enabled
 * @magentoAppArea adminhtml
 */
final class {ActionName}Test extends AbstractBackendController
{
    /**
     * @var string
     */
    protected $resource = '{Vendor}_{ModuleName}::{acl_resource}';

    /**
     * @var string
     */
    protected $uri = 'backend/{frontName}/{controller}/{action}';

    /**
     * @var string
     */
    protected $httpMethod = 'GET';

    public function testAclDeniesUnauthorizedAccess(): void
    {
        // AbstractBackendController tests ACL automatically via testAclHasAccess() and
        // testAclNoAccess() — these are inherited. Just define $resource and $uri above.
    }

    /**
     * @magentoDataFixture {Vendor}_{ModuleName}::Test/Integration/_files/{fixture}.php
     */
    public function testIndexPageLoadsGrid(): void
    {
        $this->dispatch($this->uri);

        $this->assertSame(200, $this->getResponse()->getHttpResponseCode());
        $this->assertStringContainsString('listing', $this->getResponse()->getBody());
    }

    public function testEditPageReturns404ForInvalidId(): void
    {
        $this->getRequest()->setParam('id', 99999);

        $this->dispatch('backend/{frontName}/{controller}/edit');

        $this->assertRedirect($this->stringContains('{frontName}/{controller}'));
    }

    public function testSaveActionPersistsData(): void
    {
        $this->getRequest()->setMethod('POST');
        $this->getRequest()->setPostValue([
            'name' => 'Test Entity',
            'status' => 1,
        ]);

        $this->dispatch('backend/{frontName}/{controller}/save');

        $this->assertRedirect($this->stringContains('{frontName}/{controller}'));
        $this->assertSessionMessages(
            $this->containsEqual('You saved the entity.'),
            \Magento\Framework\Message\MessageInterface::TYPE_SUCCESS
        );
    }
}
```

## Fixture File + Rollback Pair

### Fixture: `Test/Integration/_files/product_with_custom_price.php`

```php
<?php
/**
 * Copyright © Monsoon Consulting. All rights reserved.
 * See LICENSE_MONSOON.txt for license details.
 */

declare(strict_types=1);

use Magento\Catalog\Api\Data\ProductInterfaceFactory;
use Magento\Catalog\Api\ProductRepositoryInterface;
use Magento\Catalog\Model\Product\Attribute\Source\Status;
use Magento\Catalog\Model\Product\Type;
use Magento\Catalog\Model\Product\Visibility;
use Magento\TestFramework\Helper\Bootstrap;

$objectManager = Bootstrap::getObjectManager();

/** @var ProductInterfaceFactory $productFactory */
$productFactory = $objectManager->get(ProductInterfaceFactory::class);

/** @var ProductRepositoryInterface $productRepository */
$productRepository = $objectManager->get(ProductRepositoryInterface::class);

$product = $productFactory->create();
$product->setTypeId(Type::TYPE_SIMPLE)
    ->setAttributeSetId(4)
    ->setSku('test-product-custom-price')
    ->setName('Test Product With Custom Price')
    ->setPrice(99.99)
    ->setStatus(Status::STATUS_ENABLED)
    ->setVisibility(Visibility::VISIBILITY_BOTH)
    ->setStockData([
        'qty' => 100,
        'is_in_stock' => 1,
    ]);

$productRepository->save($product);
```

### Rollback: `Test/Integration/_files/product_with_custom_price_rollback.php`

```php
<?php
/**
 * Copyright © Monsoon Consulting. All rights reserved.
 * See LICENSE_MONSOON.txt for license details.
 */

declare(strict_types=1);

use Magento\Catalog\Api\ProductRepositoryInterface;
use Magento\Framework\Exception\NoSuchEntityException;
use Magento\Framework\Registry;
use Magento\TestFramework\Helper\Bootstrap;

$objectManager = Bootstrap::getObjectManager();

/** @var Registry $registry */
$registry = $objectManager->get(Registry::class);
$registry->unregister('isSecureArea');
$registry->register('isSecureArea', true);

/** @var ProductRepositoryInterface $productRepository */
$productRepository = $objectManager->get(ProductRepositoryInterface::class);

try {
    $product = $productRepository->get('test-product-custom-price');
    $productRepository->delete($product);
} catch (NoSuchEntityException) {
    // Already deleted — ignore
}

$registry->unregister('isSecureArea');
$registry->register('isSecureArea', false);
```

## Config Fixture Integration Test

```php
<?php
/**
 * Copyright © Monsoon Consulting. All rights reserved.
 * See LICENSE_MONSOON.txt for license details.
 */

declare(strict_types=1);

namespace {Vendor}\{ModuleName}\Test\Integration\Service;

use Magento\TestFramework\Helper\Bootstrap;
use PHPUnit\Framework\TestCase;
use {Vendor}\{ModuleName}\Service\{ClassName};

/**
 * @magentoDbIsolation enabled
 * @magentoAppArea frontend
 */
final class {ClassName}Test extends TestCase
{
    private {ClassName} $subject;

    protected function setUp(): void
    {
        $this->subject = Bootstrap::getObjectManager()->get({ClassName}::class);
    }

    /**
     * @magentoConfigFixture current_store {section}/{group}/{field} 1
     */
    public function testBehaviorWhenFeatureEnabled(): void
    {
        $result = $this->subject->isFeatureActive();

        $this->assertTrue($result);
    }

    /**
     * @magentoConfigFixture current_store {section}/{group}/{field} 0
     */
    public function testBehaviorWhenFeatureDisabled(): void
    {
        $result = $this->subject->isFeatureActive();

        $this->assertFalse($result);
    }

    /**
     * @magentoConfigFixture current_store {section}/{group}/{api_key} test-api-key-123
     */
    public function testServiceUsesConfiguredApiKey(): void
    {
        $result = $this->subject->getApiKey();

        $this->assertSame('test-api-key-123', $result);
    }
}
```

## Custom Entity Round-Trip Test

Tests that a custom entity can be saved and loaded through the repository.

```php
<?php
/**
 * Copyright © Monsoon Consulting. All rights reserved.
 * See LICENSE_MONSOON.txt for license details.
 */

declare(strict_types=1);

namespace {Vendor}\{ModuleName}\Test\Integration\Model;

use Magento\Framework\Exception\NoSuchEntityException;
use Magento\TestFramework\Helper\Bootstrap;
use PHPUnit\Framework\TestCase;
use {Vendor}\{ModuleName}\Api\{EntityName}RepositoryInterface;
use {Vendor}\{ModuleName}\Api\Data\{EntityName}InterfaceFactory;

/**
 * @magentoDbIsolation enabled
 */
final class {EntityName}RepositoryTest extends TestCase
{
    private {EntityName}RepositoryInterface $repository;
    private {EntityName}InterfaceFactory $factory;

    protected function setUp(): void
    {
        $objectManager = Bootstrap::getObjectManager();
        $this->repository = $objectManager->get({EntityName}RepositoryInterface::class);
        $this->factory = $objectManager->get({EntityName}InterfaceFactory::class);
    }

    public function testSaveAndGetById(): void
    {
        $entity = $this->factory->create();
        $entity->setName('Integration Test Entity');
        $entity->setStatus(1);

        $saved = $this->repository->save($entity);
        $this->assertNotNull($saved->getId());

        $loaded = $this->repository->getById((int)$saved->getId());
        $this->assertSame('Integration Test Entity', $loaded->getName());
        $this->assertSame(1, $loaded->getStatus());
    }

    public function testDeleteRemovesEntity(): void
    {
        $entity = $this->factory->create();
        $entity->setName('To Be Deleted');
        $saved = $this->repository->save($entity);
        $entityId = (int)$saved->getId();

        $this->repository->deleteById($entityId);

        $this->expectException(NoSuchEntityException::class);
        $this->repository->getById($entityId);
    }

    public function testGetByIdThrowsForNonExistent(): void
    {
        $this->expectException(NoSuchEntityException::class);

        $this->repository->getById(999999);
    }
}
```

## Fixture Conventions

| Convention | Detail |
|-----------|--------|
| Location | `Test/Integration/_files/` directory in the module |
| Naming | Descriptive snake_case: `product_with_custom_price.php` |
| Rollback | Same name with `_rollback` suffix |
| Registry | Rollback files must set `isSecureArea` to `true` before deleting |
| Reusable | Magento core fixtures can be referenced: `Magento/Catalog/_files/product_simple.php` |
| Factory pattern | Use `InterfaceFactory::create()` over `ObjectManager::create()` |
| Annotation | `@magentoDataFixture {Vendor}_{Module}::Test/Integration/_files/{name}.php` |
