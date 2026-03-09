# Magento TestFramework Annotations & Base Classes

Reference file for `.claude/skills/m2-testing/SKILL.md`. Full reference for Magento integration test annotations, base classes, and ObjectManager usage.

## Annotations Reference

### @magentoDbIsolation

Wraps the test in a database transaction that rolls back after the test completes.

```php
/**
 * @magentoDbIsolation enabled
 */
```

| Value | Behavior |
|-------|----------|
| `enabled` | Wraps each test method in a transaction; rolls back after |
| `disabled` | No transaction wrapping (data persists between tests in the class) |

**Best practice:** Always use `enabled` unless the test explicitly needs data to persist across methods (rare). Can be set at class or method level. Method-level overrides class-level.

### @magentoDataFixture

Loads a PHP fixture file before the test method runs. The file executes arbitrary PHP to create test data.

```php
/**
 * @magentoDataFixture Magento/Catalog/_files/product_simple.php
 * @magentoDataFixture {Vendor}_{Module}::Test/Integration/_files/custom_entity.php
 */
```

**Path formats:**
- Core fixtures: `Magento/{Module}/_files/{name}.php` — resolved relative to `dev/tests/integration/testsuite/`
- Custom module fixtures: `{Vendor}_{Module}::Test/Integration/_files/{name}.php` — resolved relative to module root in `app/code/`

**Rollback:** If a file named `{name}_rollback.php` exists in the same directory, it runs automatically after the test. Rollback runs even when `@magentoDbIsolation` is enabled (for non-transactional cleanup like files or cache).

**Multiple fixtures:** Stack multiple annotations; they execute in order:
```php
/**
 * @magentoDataFixture Magento/Catalog/_files/product_simple.php
 * @magentoDataFixture Magento/Customer/_files/customer.php
 */
```

### @magentoDataFixtureBeforeTransaction

Like `@magentoDataFixture` but executes before the `@magentoDbIsolation` transaction starts. Use for fixtures that must not be rolled back (e.g., creating database tables).

```php
/**
 * @magentoDataFixtureBeforeTransaction {Vendor}_{Module}::Test/Integration/_files/schema_setup.php
 */
```

### @magentoConfigFixture

Overrides a store configuration value for the duration of the test.

```php
/**
 * @magentoConfigFixture current_store general/locale/code en_US
 * @magentoConfigFixture default/web/unsecure/base_url http://example.com/
 * @magentoConfigFixture current_store {section}/{group}/{field} {value}
 */
```

**Scope prefixes:**
| Prefix | Meaning |
|--------|---------|
| `current_store` | Current store scope (usually `default`) |
| `default/` | Default scope (global config) |
| `default_store/` | Default store |
| `current_website` | Current website scope |

**Multiple values:** Stack annotations for multiple config overrides:
```php
/**
 * @magentoConfigFixture current_store payment/free/active 1
 * @magentoConfigFixture current_store payment/free/title Free Payment
 */
```

### @magentoAppArea

Sets the Magento application area for the test.

```php
/**
 * @magentoAppArea frontend
 */
```

| Value | Use Case |
|-------|----------|
| `frontend` | Testing storefront behavior |
| `adminhtml` | Testing admin behavior |
| `global` | Default; no specific area |
| `webapi_rest` | Testing REST API behavior |
| `crontab` | Testing cron behavior |

### @magentoAppIsolation

Reinitializes the Magento application between tests. Expensive — use sparingly.

```php
/**
 * @magentoAppIsolation enabled
 */
```

Use when tests modify global state that `@magentoDbIsolation` cannot roll back (e.g., registering event observers dynamically, modifying object manager configuration).

### @magentoCache

Controls cache state during the test.

```php
/**
 * @magentoCache all disabled
 * @magentoCache config enabled
 * @magentoCache full_page disabled
 */
```

| Syntax | Effect |
|--------|--------|
| `all disabled` | Disable all cache types |
| `all enabled` | Enable all cache types |
| `{type} disabled` | Disable specific cache type |
| `{type} enabled` | Enable specific cache type |

### @magentoComponentsDir

Points to a directory containing test fixture components (modules, themes).

```php
/**
 * @magentoComponentsDir {Vendor}_{Module}::Test/Integration/_files/components
 */
```

Used when the test needs a fixture module or theme to be registered.

## Base Classes

### PHPUnit\Framework\TestCase

Standard PHPUnit base class. Use for unit tests and basic integration tests that don't need controller dispatch.

### Magento\TestFramework\TestCase\AbstractController

For frontend controller integration tests. Provides `dispatch()`, `getRequest()`, `getResponse()`.

```php
use Magento\TestFramework\TestCase\AbstractController;

final class PageTest extends AbstractController
{
    public function testPageLoads(): void
    {
        $this->dispatch('cms/page/view/page_id/home');

        $this->assertSame(200, $this->getResponse()->getHttpResponseCode());
    }

    public function testRedirectOccurs(): void
    {
        $this->dispatch('some/protected/page');

        $this->assertRedirect($this->stringContains('customer/account/login'));
    }
}
```

**Key methods:**
| Method | Purpose |
|--------|---------|
| `dispatch(string $uri)` | Simulates an HTTP request to the given URI |
| `getRequest()` | Returns the `Request` object for setting method, params, post data |
| `getResponse()` | Returns the `Response` object for assertions |
| `assertRedirect($constraint)` | Assert response is a redirect matching the constraint |
| `assertSessionMessages($constraint, $type)` | Assert session messages of a given type |

### Magento\TestFramework\TestCase\AbstractBackendController

For admin controller integration tests. Extends `AbstractController` with automatic admin authentication and ACL testing.

```php
use Magento\TestFramework\TestCase\AbstractBackendController;

final class IndexTest extends AbstractBackendController
{
    protected $resource = 'Vendor_Module::entity';
    protected $uri = 'backend/vendor_module/entity/index';
    protected $httpMethod = 'GET';
}
```

**Properties to set:**
| Property | Purpose |
|----------|---------|
| `$resource` | ACL resource string — enables automatic ACL testing |
| `$uri` | Admin route URI |
| `$httpMethod` | HTTP method (`GET`, `POST`) |

**Inherited test methods:**
- `testAclHasAccess()` — verifies authorized admin can access the URI
- `testAclNoAccess()` — verifies unauthorized admin gets a 403

## ObjectManager in Integration Tests

Integration tests use `Bootstrap::getObjectManager()` to access Magento's DI container.

```php
use Magento\TestFramework\Helper\Bootstrap;

$objectManager = Bootstrap::getObjectManager();
```

### get() vs create()

| Method | Behavior | Use When |
|--------|----------|----------|
| `$objectManager->get(Class::class)` | Returns shared instance (singleton) | Loading services, repositories, configs |
| `$objectManager->create(Class::class)` | Returns new instance every time | Creating test entities, models, data objects |

**Rule of thumb:**
- `get()` for services (repositories, helpers, view models, config readers)
- `create()` for data objects (entities, models, collections)

```php
// Service — use get() (singleton)
$repository = $objectManager->get(ProductRepositoryInterface::class);

// Data object — use create() (new instance)
$product = $objectManager->create(ProductInterface::class);
```

### Configuring DI in Tests

Override DI configuration for tests by setting preferences before creating objects:

```php
$objectManager->configure([
    SomeInterface::class => [
        'instance' => SomeTestDouble::class,
    ],
]);
```

Use this sparingly — prefer real implementations in integration tests. If you need heavy mocking, write a unit test instead.

## Fixture File Patterns

### Secure Area for Deletion

Magento prevents deleting catalog entities outside "secure area". Rollback fixtures must register `isSecureArea`:

```php
$registry = $objectManager->get(\Magento\Framework\Registry::class);
$registry->unregister('isSecureArea');
$registry->register('isSecureArea', true);

// ... delete entities ...

$registry->unregister('isSecureArea');
$registry->register('isSecureArea', false);
```

### Reusing Core Fixtures

Common Magento core fixtures (in `dev/tests/integration/testsuite/`):

| Fixture | Creates |
|---------|---------|
| `Magento/Catalog/_files/product_simple.php` | Simple product (SKU: `simple`) |
| `Magento/Catalog/_files/category.php` | Category (ID: 333) |
| `Magento/Customer/_files/customer.php` | Customer (email: `customer@example.com`) |
| `Magento/Sales/_files/order.php` | Order with simple product |
| `Magento/Cms/_files/pages.php` | CMS pages |
| `Magento/Store/_files/second_website_with_two_stores.php` | Multi-store setup |
| `Magento/Catalog/_files/product_simple_with_custom_attribute.php` | Product with custom attribute |

Reference these directly in `@magentoDataFixture` without copying:
```php
/**
 * @magentoDataFixture Magento/Catalog/_files/product_simple.php
 */
```
