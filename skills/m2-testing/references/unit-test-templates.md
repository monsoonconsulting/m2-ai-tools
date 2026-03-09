# Unit Test Extended Templates

Reference file for `.claude/skills/m2-testing/SKILL.md`. Contains detailed unit test templates and mock patterns too long for the main skill file.

## Repository Unit Test (Full CRUD)

```php
<?php
/**
 * Copyright © Monsoon Consulting. All rights reserved.
 * See LICENSE_MONSOON.txt for license details.
 */

declare(strict_types=1);

namespace {Vendor}\{ModuleName}\Test\Unit\Model;

use Magento\Framework\Api\SearchCriteria;
use Magento\Framework\Api\SearchCriteriaBuilder;
use Magento\Framework\Exception\CouldNotDeleteException;
use Magento\Framework\Exception\CouldNotSaveException;
use Magento\Framework\Exception\NoSuchEntityException;
use PHPUnit\Framework\MockObject\MockObject;
use PHPUnit\Framework\TestCase;
use {Vendor}\{ModuleName}\Api\Data\{EntityName}Interface;
use {Vendor}\{ModuleName}\Api\Data\{EntityName}SearchResultsInterface;
use {Vendor}\{ModuleName}\Model\{EntityName}Repository;
use {Vendor}\{ModuleName}\Model\ResourceModel\{EntityName} as {EntityName}Resource;
use {Vendor}\{ModuleName}\Model\{EntityName}Factory;
use {Vendor}\{ModuleName}\Model\ResourceModel\{EntityName}\CollectionFactory;

final class {EntityName}RepositoryTest extends TestCase
{
    private {EntityName}Repository $subject;
    private {EntityName}Resource&MockObject $resourceMock;
    private {EntityName}Factory&MockObject $factoryMock;
    private CollectionFactory&MockObject $collectionFactoryMock;

    protected function setUp(): void
    {
        $this->resourceMock = $this->createMock({EntityName}Resource::class);
        $this->factoryMock = $this->createMock({EntityName}Factory::class);
        $this->collectionFactoryMock = $this->createMock(CollectionFactory::class);

        $this->subject = new {EntityName}Repository(
            $this->resourceMock,
            $this->factoryMock,
            $this->collectionFactoryMock
        );
    }

    public function testGetByIdReturnsEntity(): void
    {
        $entityId = 42;
        $entityMock = $this->createMock({EntityName}Interface::class);
        $entityMock->method('getId')->willReturn($entityId);

        $this->factoryMock->method('create')->willReturn($entityMock);
        $this->resourceMock->method('load')->with($entityMock, $entityId);

        $result = $this->subject->getById($entityId);

        $this->assertSame($entityId, $result->getId());
    }

    public function testGetByIdThrowsWhenNotFound(): void
    {
        $entityMock = $this->createMock({EntityName}Interface::class);
        $entityMock->method('getId')->willReturn(null);

        $this->factoryMock->method('create')->willReturn($entityMock);

        $this->expectException(NoSuchEntityException::class);

        $this->subject->getById(999);
    }

    public function testSaveCallsResource(): void
    {
        $entityMock = $this->createMock({EntityName}Interface::class);

        $this->resourceMock
            ->expects($this->once())
            ->method('save')
            ->with($entityMock);

        $result = $this->subject->save($entityMock);

        $this->assertSame($entityMock, $result);
    }

    public function testSaveWrapsException(): void
    {
        $entityMock = $this->createMock({EntityName}Interface::class);

        $this->resourceMock
            ->method('save')
            ->willThrowException(new \Exception('DB error'));

        $this->expectException(CouldNotSaveException::class);

        $this->subject->save($entityMock);
    }

    public function testDeleteCallsResource(): void
    {
        $entityMock = $this->createMock({EntityName}Interface::class);

        $this->resourceMock
            ->expects($this->once())
            ->method('delete')
            ->with($entityMock);

        $result = $this->subject->delete($entityMock);

        $this->assertTrue($result);
    }

    public function testDeleteWrapsException(): void
    {
        $entityMock = $this->createMock({EntityName}Interface::class);

        $this->resourceMock
            ->method('delete')
            ->willThrowException(new \Exception('DB error'));

        $this->expectException(CouldNotDeleteException::class);

        $this->subject->delete($entityMock);
    }

    public function testDeleteByIdLoadsAndDeletes(): void
    {
        $entityId = 42;
        $entityMock = $this->createMock({EntityName}Interface::class);
        $entityMock->method('getId')->willReturn($entityId);

        $this->factoryMock->method('create')->willReturn($entityMock);

        $this->resourceMock
            ->expects($this->once())
            ->method('delete')
            ->with($entityMock);

        $result = $this->subject->deleteById($entityId);

        $this->assertTrue($result);
    }
}
```

## ViewModel Unit Test

```php
<?php
/**
 * Copyright © Monsoon Consulting. All rights reserved.
 * See LICENSE_MONSOON.txt for license details.
 */

declare(strict_types=1);

namespace {Vendor}\{ModuleName}\Test\Unit\ViewModel;

use Magento\Framework\App\Config\ScopeConfigInterface;
use PHPUnit\Framework\MockObject\MockObject;
use PHPUnit\Framework\TestCase;
use {Vendor}\{ModuleName}\ViewModel\{ViewModelName};

final class {ViewModelName}Test extends TestCase
{
    private {ViewModelName} $subject;
    private ScopeConfigInterface&MockObject $scopeConfigMock;

    protected function setUp(): void
    {
        $this->scopeConfigMock = $this->createMock(ScopeConfigInterface::class);

        $this->subject = new {ViewModelName}(
            $this->scopeConfigMock
        );
    }

    public function testIsEnabledReturnsTrueWhenConfigSet(): void
    {
        $this->scopeConfigMock
            ->method('isSetFlag')
            ->with('{section}/{group}/{field}')
            ->willReturn(true);

        $this->assertTrue($this->subject->isEnabled());
    }

    public function testIsEnabledReturnsFalseByDefault(): void
    {
        $this->scopeConfigMock
            ->method('isSetFlag')
            ->willReturn(false);

        $this->assertFalse($this->subject->isEnabled());
    }

    public function testGetTitleReturnsConfigValue(): void
    {
        $this->scopeConfigMock
            ->method('getValue')
            ->with('{section}/{group}/{title_field}')
            ->willReturn('Custom Title');

        $this->assertSame('Custom Title', $this->subject->getTitle());
    }
}
```

## Mock Patterns Cheat Sheet

### Basic Mock (Interface)

```php
$mock = $this->createMock(SomeInterface::class);
$mock->method('getValue')->willReturn('result');
```

### Mock with Expectation Count

```php
$mock->expects($this->once())->method('save');
$mock->expects($this->never())->method('delete');
$mock->expects($this->exactly(3))->method('process');
$mock->expects($this->atLeastOnce())->method('log');
```

### Mock with Argument Matching

```php
$mock->method('find')
    ->with(42)
    ->willReturn($entity);

$mock->method('find')
    ->with($this->greaterThan(0))
    ->willReturn($entity);

$mock->method('search')
    ->with($this->anything(), $this->isInstanceOf(SearchCriteria::class))
    ->willReturn($results);
```

### Consecutive Returns

```php
$mock->method('fetch')
    ->willReturnOnConsecutiveCalls('first', 'second', 'third');
```

### Return Callback

```php
$mock->method('transform')
    ->willReturnCallback(function (string $input): string {
        return strtoupper($input);
    });
```

### Throw Exception

```php
$mock->method('load')
    ->willThrowException(new NoSuchEntityException(__('Not found')));
```

### Mock Concrete Class (disable constructor)

```php
$mock = $this->getMockBuilder(ConcreteClass::class)
    ->disableOriginalConstructor()
    ->getMock();
```

### Factory Mock

Magento factories follow the pattern `{ClassName}Factory::create(): {ClassName}`. Mock them like this:

```php
$entityMock = $this->createMock(Entity::class);
$factoryMock = $this->createMock(EntityFactory::class);
$factoryMock->method('create')->willReturn($entityMock);
```

### Data Provider

```php
/**
 * @dataProvider priceDataProvider
 */
public function testCalculatePrice(float $basePrice, float $discount, float $expected): void
{
    $result = $this->subject->calculatePrice($basePrice, $discount);
    $this->assertSame($expected, $result);
}

/**
 * @return array<string, array{float, float, float}>
 */
public static function priceDataProvider(): array
{
    return [
        'no discount'     => [100.0, 0.0, 100.0],
        '10% discount'    => [100.0, 10.0, 90.0],
        '100% discount'   => [100.0, 100.0, 0.0],
        'zero price'      => [0.0, 50.0, 0.0],
    ];
}
```

### Intersection Type Mocks (PHP 8.1+)

```php
// Type-safe mock with intersection types
private SomeInterface&MockObject $mock;

protected function setUp(): void
{
    $this->mock = $this->createMock(SomeInterface::class);
}
```
