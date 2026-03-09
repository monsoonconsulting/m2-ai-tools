---
name: m2-testing
description: >
  Generate PHPUnit tests and fix code quality issues for Magento 2 modules.
  Use this skill whenever the user asks to write, create, or generate tests, fix code quality,
  or run static analysis. Trigger on: "write test", "create test", "unit test", "integration test",
  "generate test", "add test", "test class", "test coverage", "PHPUnit", "phpunit", "TestCase",
  "fix phpcs", "fix phpstan", "fix phpmd", "code quality", "coding standard", "static analysis",
  "code sniffer", "mess detector", "php-cs-fixer", "mock", "createMock", "data fixture",
  "magentoDataFixture", "magentoConfigFixture", "test for", "test this", "test coverage", "TDD".
---

# Magento 2 Testing & Code Quality

You are a Magento 2 testing specialist. Generate PHPUnit test classes, fixtures, and fix code quality issues for modules in `app/code/{Vendor}/{ModuleName}/`.

Follow the coding conventions and file headers defined in `.claude/skills/_shared/conventions.md` and `.claude/skills/m2-module/SKILL.md`. Do not duplicate those conventions here.

Test run commands and code quality tool invocations are documented in the project `CLAUDE.md` — reference those instead of duplicating them.

**Prerequisites:** Module must exist (see `_shared/conventions.md`). If not, use `/m2-module` first.

## 1. Decision Tree: What Type of Test?

**Unit test when:**
- Testing a single class in isolation (service, plugin, observer, ViewModel, helper)
- All dependencies can be mocked
- No database, filesystem, or Magento framework bootstrap needed
- Fast feedback loop is desired

**Integration test when:**
- Testing interaction between multiple classes through Magento's DI
- Testing database operations (repositories, resource models)
- Testing controller responses (dispatch, assert status code, assert body)
- Testing configuration fixtures (`@magentoConfigFixture`)
- The class under test needs the Magento application bootstrapped

**Static analysis (not a test class — run tools directly) when:**
- Fixing coding standard violations (PHPCS/PHPCBF)
- Fixing type errors (PHPStan)
- Fixing code complexity issues (PHPMD)
- Formatting code (PHP CS Fixer)

## 2. Gather Requirements

Before generating any test files, collect the following from the user.

**Required (ask if not provided):**
- **Class under test** — fully qualified class name (e.g., `Acme\CatalogExt\Service\PriceCalculator`)
- **Test type** — unit or integration
- **What to test** — specific methods, behaviors, or "full coverage"

**Optional (use defaults if not specified):**
- **Module name** — derived from the class namespace
- **Test method names** — auto-derived from public methods + edge cases

## 3. Naming Conventions

| Concept | Convention | Example |
|---------|-----------|---------|
| Unit test class | `{ClassName}Test` | `PriceCalculatorTest` |
| Unit test namespace | `{Vendor}\{Module}\Test\Unit\{SubPath}` | `Acme\CatalogExt\Test\Unit\Service` |
| Unit test file | `Test/Unit/{SubPath}/{ClassName}Test.php` | `Test/Unit/Service/PriceCalculatorTest.php` |
| Integration test class | `{ClassName}Test` | `ProductControllerTest` |
| Integration test namespace | `{Vendor}\{Module}\Test\Integration\{SubPath}` | `Acme\CatalogExt\Test\Integration\Controller` |
| Integration test file | `Test/Integration/{SubPath}/{ClassName}Test.php` | `Test/Integration/Controller/ProductControllerTest.php` |
| Fixture file | `Test/Integration/_files/{descriptive_name}.php` | `Test/Integration/_files/product_with_custom_price.php` |
| Rollback file | `Test/Integration/_files/{name}_rollback.php` | `Test/Integration/_files/product_with_custom_price_rollback.php` |
| Test method name | `test{Behavior}` or `test{Method}{Scenario}` | `testCalculatePriceWithDiscount` |

**Path mirroring rule:** Test files mirror the source structure. A class at `Service/PriceCalculator.php` has its unit test at `Test/Unit/Service/PriceCalculatorTest.php`.

## 4. Unit Test Templates

### 4.1 Service / Model Unit Test

```php
<?php
/**
 * Copyright © Monsoon Consulting. All rights reserved.
 * See LICENSE_MONSOON.txt for license details.
 */

declare(strict_types=1);

namespace {Vendor}\{ModuleName}\Test\Unit\{SubPath};

use PHPUnit\Framework\MockObject\MockObject;
use PHPUnit\Framework\TestCase;
use {Vendor}\{ModuleName}\{SubPath}\{ClassName};

final class {ClassName}Test extends TestCase
{
    private {ClassName} $subject;
    private {DependencyInterface}&MockObject $dependencyMock;

    protected function setUp(): void
    {
        $this->dependencyMock = $this->createMock({DependencyInterface}::class);

        $this->subject = new {ClassName}(
            $this->dependencyMock
        );
    }

    public function testMethodReturnsExpectedResult(): void
    {
        $this->dependencyMock
            ->expects($this->once())
            ->method('someMethod')
            ->willReturn('expected');

        $result = $this->subject->methodUnderTest();

        $this->assertSame('expected', $result);
    }

    public function testMethodThrowsOnInvalidInput(): void
    {
        $this->expectException(\InvalidArgumentException::class);
        $this->expectExceptionMessage('Expected message');

        $this->subject->methodUnderTest(null);
    }
}
```

### 4.2 Plugin Unit Test

```php
<?php
// Standard file header — see _shared/conventions.md
declare(strict_types=1);

namespace {Vendor}\{ModuleName}\Test\Unit\Plugin\{TargetArea};

use PHPUnit\Framework\MockObject\MockObject;
use PHPUnit\Framework\TestCase;
use {Vendor}\{ModuleName}\Plugin\{TargetArea}\{PluginClassName};
use {TargetClassFQN};

final class {PluginClassName}Test extends TestCase
{
    private {PluginClassName} $subject;
    private {TargetShortName}&MockObject $targetMock;

    protected function setUp(): void
    {
        $this->targetMock = $this->createMock({TargetShortName}::class);

        $this->subject = new {PluginClassName}(
            // inject mocked dependencies
        );
    }

    public function testAfterMethodModifiesResult(): void
    {
        $originalResult = 'original';

        $result = $this->subject->after{Method}(
            $this->targetMock,
            $originalResult
        );

        $this->assertSame('modified', $result);
    }
}
```

### 4.3 Observer Unit Test

```php
<?php
// Standard file header — see _shared/conventions.md
declare(strict_types=1);

namespace {Vendor}\{ModuleName}\Test\Unit\Observer;

use Magento\Framework\Event;
use Magento\Framework\Event\Observer;
use PHPUnit\Framework\MockObject\MockObject;
use PHPUnit\Framework\TestCase;
use {Vendor}\{ModuleName}\Observer\{ObserverClassName};

final class {ObserverClassName}Test extends TestCase
{
    private {ObserverClassName} $subject;
    private Observer&MockObject $observerMock;
    private Event&MockObject $eventMock;

    protected function setUp(): void
    {
        $this->eventMock = $this->createMock(Event::class);
        $this->observerMock = $this->createMock(Observer::class);
        $this->observerMock->method('getEvent')->willReturn($this->eventMock);

        $this->subject = new {ObserverClassName}(
            // inject mocked dependencies
        );
    }

    public function testExecuteProcessesEventData(): void
    {
        $this->eventMock
            ->method('getData')
            ->with('{data_key}')
            ->willReturn($mockEntity);

        $this->subject->execute($this->observerMock);

        // Assert side effects (logger called, service invoked, etc.)
    }
}
```

### 4.4 @dataProvider Example

```php
/**
 * @dataProvider priceCalculationProvider
 */
public function testPriceCalculation(float $basePrice, float $discount, float $expected): void
{
    $result = $this->calculator->calculate($basePrice, $discount);
    $this->assertEqualsWithDelta($expected, $result, 0.01);
}

/**
 * @return array<string, array{float, float, float}>
 */
public static function priceCalculationProvider(): array
{
    return [
        'no discount'   => [100.00, 0.0, 100.00],
        '10% discount'  => [100.00, 10.0, 90.00],
        'full discount' => [100.00, 100.0, 0.00],
    ];
}
```

## 5. Integration Test Templates

### 5.1 Basic Integration Test

```php
<?php
// Standard file header — see _shared/conventions.md
declare(strict_types=1);

namespace {Vendor}\{ModuleName}\Test\Integration;

use Magento\TestFramework\Helper\Bootstrap;
use PHPUnit\Framework\TestCase;
use {Vendor}\{ModuleName}\{SubPath}\{ClassName};

/**
 * @magentoDbIsolation enabled
 * @magentoAppArea frontend
 */
final class {ClassName}Test extends TestCase
{
    private {ClassName} $subject;

    protected function setUp(): void
    {
        $objectManager = Bootstrap::getObjectManager();
        $this->subject = $objectManager->get({ClassName}::class);
    }

    /**
     * @magentoDataFixture {Vendor}_{ModuleName}::Test/Integration/_files/{fixture}.php
     */
    public function testMethodWithFixtureData(): void
    {
        $result = $this->subject->methodUnderTest();

        $this->assertNotEmpty($result);
    }

    /**
     * @magentoConfigFixture current_store {section}/{group}/{field} {value}
     */
    public function testMethodWithConfigOverride(): void
    {
        $result = $this->subject->methodUnderTest();

        $this->assertTrue($result);
    }
}
```

### 5.2 Controller Integration Test

```php
<?php
// Standard file header — see _shared/conventions.md
declare(strict_types=1);

namespace {Vendor}\{ModuleName}\Test\Integration\Controller;

use Magento\TestFramework\TestCase\AbstractController;

/**
 * @magentoDbIsolation enabled
 * @magentoAppArea frontend
 */
final class {ActionName}Test extends AbstractController
{
    public function testExecuteReturns200(): void
    {
        $this->dispatch('{frontName}/{controller}/{action}');

        $this->assertSame(200, $this->getResponse()->getHttpResponseCode());
        $this->assertStringContainsString(
            'Expected content',
            $this->getResponse()->getBody()
        );
    }

    public function testExecuteRedirectsUnauthenticated(): void
    {
        $this->dispatch('{frontName}/{controller}/{action}');

        $this->assertRedirect($this->stringContains('customer/account/login'));
    }
}
```

For extended templates (repository CRUD tests, admin controller tests, fixture pairs, ViewModel tests, mock patterns cheat sheet), see `.claude/skills/m2-testing/references/unit-test-templates.md` and `.claude/skills/m2-testing/references/integration-test-templates.md`.

For REST API functional test patterns (WebapiAbstract, token auth, CRUD endpoints), see `.claude/skills/m2-testing/references/api-test-patterns.md`.

## 6. Annotations Quick Reference

| Annotation | Scope | Purpose |
|-----------|-------|---------|
| `@magentoDbIsolation enabled` | Class/Method | Wraps test in transaction, rolls back after |
| `@magentoDataFixture` | Method | Loads fixture PHP file before test |
| `@magentoDataFixtureBeforeTransaction` | Method | Loads fixture before transaction starts |
| `@magentoConfigFixture` | Method | Overrides store config for the test |
| `@magentoAppArea frontend` | Class/Method | Sets application area |
| `@magentoAppIsolation enabled` | Class/Method | Reinitializes app between tests |
| `@magentoCache all disabled` | Class/Method | Disables cache during test |
| `@magentoComponentsDir` | Class | Points to test component fixtures |

For full annotation details, fixture patterns, and base class reference, see `.claude/skills/m2-testing/references/annotations-and-fixtures.md`.

## 7. Generation Rules

Follow this sequence when generating tests:

1. **Verify the target module exists** — check that `app/code/{Vendor}/{ModuleName}/registration.php` exists. If not, instruct the user to scaffold it first with `/m2-module`.

2. **Read the class under test** — open the source file, identify all public methods, constructor dependencies, and return types. The test must match the real signatures.

3. **Determine the test type** — if the user didn't specify, apply the decision tree from section 1. Default to unit tests unless the class clearly needs Magento bootstrap (repositories, controllers, config-dependent logic).

4. **Mirror the source path** — place the test file at the correct mirrored path under `Test/Unit/` or `Test/Integration/`.

5. **Mock all constructor dependencies for unit tests** — use `createMock()` for interfaces, `getMockBuilder()->disableOriginalConstructor()->getMock()` only when needed for concrete classes.

6. **Create one test method per behavior**, not per source method. A method with 3 code paths gets 3 test methods. Name them `test{Method}{Scenario}` (e.g., `testSaveWithValidData`, `testSaveThrowsOnDuplicate`).

7. **For integration tests**, create fixture files if the test needs specific data. Always create a matching rollback file.

8. **Use strict assertions** — prefer `assertSame` over `assertEquals`, `assertInstanceOf` over type-checking, `assertCount` over counting manually.

9. **Run the test** after generating it to verify it passes. Use the commands from project `CLAUDE.md`.

## 8. What to Test (Priority)

| Priority | What | Why |
|----------|------|-----|
| **High** | Service classes / business logic | Core value, most likely to break |
| **High** | Repository implementations | Data integrity, CRUD correctness |
| **High** | Plugins that modify data | Hidden behavior changes, hard to debug |
| **Medium** | Observers with side effects | Ensure side effects trigger correctly |
| **Medium** | ViewModels | Template data correctness |
| **Medium** | Data patches | One-shot code that must work first time |
| **Low** | Simple getters/setters | Low value, unlikely to break |
| **Low** | Configuration readers | Mostly framework wiring |
| **Skip** | Generated code (factories, proxies) | Auto-generated, tested by framework |
| **Skip** | Layout XML, di.xml | Static config, validated by `setup:di:compile` |

## 9. Anti-Patterns

**Testing implementation instead of behavior.**
Don't assert that a mock was called 3 times if what matters is the return value. Test the contract, not the internals.

**Using `ObjectManager` in unit tests.**
Unit tests must never bootstrap Magento. Instantiate the class directly with mocked dependencies. `ObjectManager` belongs only in integration tests.

**Skipping `@magentoDbIsolation`.**
Always use `@magentoDbIsolation enabled` on integration tests that touch the database. Without it, test data leaks between tests and causes flaky failures.

**Missing rollback fixtures.**
Every `@magentoDataFixture` should have a matching `_rollback.php` file. Even with `@magentoDbIsolation`, rollbacks handle non-transactional resources (filesystem, cache).

**Over-mocking — mocking the class under test.**
Never mock the class you're testing. If you need to mock a method on the subject, the class has a design problem — extract the dependency.

**Huge setUp methods.**
If `setUp()` has 15+ mocks, the class under test has too many dependencies. Suggest refactoring or use data providers to reduce repetition.

**Using `around` plugin test patterns for `before`/`after` plugins.**
Before/after plugins don't have `$proceed`. Don't add it to the test. Match the actual plugin method signature exactly.

**Not testing exception paths.**
Every `throw` in the source code should have a corresponding `expectException()` test. Missing these leads to undetected broken error handling.

## 10. Code Quality: Fix Workflow

When the user asks to fix PHPCS, PHPStan, PHPMD, or PHP CS Fixer issues:

1. **Run the tool first** to see current violations (commands in project `CLAUDE.md`).
2. **For auto-fixable issues** (PHPCBF, PHP CS Fixer), run the auto-fixer and review changes.
3. **For manual fixes** (PHPStan type errors, PHPMD complexity), read each violation, then edit the source file to fix it.
4. **Re-run the tool** to verify all violations are resolved.
5. **Do not suppress warnings** (`@phpcs:ignore`, `@phpstan-ignore`) unless the violation is a known false positive. Explain why when suppressing.

## 11. Post-Generation Steps

Test run commands are documented in the project `CLAUDE.md`. After generating tests:

**Skill-specific verification:**
- Run the generated unit test: `vendor/bin/phpunit -c dev/tests/unit/phpunit.xml.dist app/code/{Vendor}/{ModuleName}/Test/Unit/{path}`
- Run the generated integration test: `vendor/bin/phpunit -c dev/tests/integration/phpunit.xml.dist app/code/{Vendor}/{ModuleName}/Test/Integration/{path}`
- Integration tests require a separate database configured in `dev/tests/integration/etc/install-config-mysql.php`
- Always use `@magentoDbIsolation enabled` on integration tests that touch the database
