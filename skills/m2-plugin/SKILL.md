---
name: m2-plugin
description: >
  Generate Magento 2 plugin (interceptor) classes and di.xml configuration.
  Use this skill whenever the user asks to create, add, or generate a plugin,
  interceptor, or method hook. Trigger on: "create plugin", "add plugin",
  "generate plugin", "interceptor", "hook method", "intercept", "before plugin",
  "after plugin", "around plugin", "wrap method", "modify method behavior",
  "plugin for", "extend method", "change return value", "modify arguments".
---

# Magento 2 Plugin (Interceptor) Generator

You are a Magento 2 plugin specialist. Generate plugin classes and di.xml configuration under existing modules in `app/code/{Vendor}/{ModuleName}/`.

Follow the coding conventions and file headers defined in `.claude/skills/_shared/conventions.md` and `.claude/skills/m2-module/SKILL.md`. Do not duplicate those conventions here.

**Prerequisites:** Module must exist (see `_shared/conventions.md`). If not, use `/m2-module` first.

## 1. Decision Tree: When to Use a Plugin

**Use a before plugin when you need to:**
- Modify arguments before they reach the original method
- Add validation or precondition checks
- Short-circuit a method by throwing an exception

**Use an after plugin when you need to:**
- Modify the return value of a method
- Perform side effects after a method executes
- Extend results (e.g., add data to an array return)

**Use an around plugin when you need to:**
- Conditionally skip the original method entirely
- Wrap the method in a try/catch or transaction
- Modify both arguments AND return value

**Do NOT use a plugin when:**
- A native event/observer exists for the use case — use an observer instead
- You need to replace the entire class — use a `<preference>` in di.xml
- The target method is `final`, `static`, `private`, or `__construct`
- The target class is `final` — plugins cannot intercept final classes
- A simpler approach exists (layout XML, config override, etc.)

## 2. Gather Requirements

Before generating any files, collect the following from the user.

**Required (ask if not provided):**
- **Target class or interface** — fully qualified (e.g., `Magento\Catalog\Api\ProductRepositoryInterface`)
- **Target method** — the public method to intercept (e.g., `save`)
- **Plugin type** — `before`, `after`, or `around`
- **Module name** — `Vendor_ModuleName` where the plugin will live

**Optional (use defaults if not specified):**
- **Area** — `global` (default), `frontend`, or `adminhtml`
- **Sort order** — integer; default: omit (Magento default is 0)
- **Plugin class name** — auto-derived from conventions below

## 3. Naming Conventions

| Concept | Convention | Example |
|---------|-----------|---------|
| Plugin class name | `{TargetShortName}{Method}{Type}` | `ProductRepositorySaveAfter` |
| Namespace | `{Vendor}\{ModuleName}\Plugin\{TargetArea}` | `Acme\CatalogExt\Plugin\Catalog` |
| File path | `Plugin/{TargetArea}/{ClassName}.php` | `Plugin/Catalog/ProductRepositorySaveAfter.php` |
| di.xml name | `{vendor}_{modulename}_{target_short}_{method}_{type}` | `acme_catalogext_productrepository_save_after` |

**Namespace grouping:** Group plugins by the Magento module area they target. For example, plugins targeting `Magento\Catalog\*` classes go under `Plugin\Catalog\`, plugins targeting `Magento\Sales\*` go under `Plugin\Sales\`.

**When a module has many plugins**, nest further: `Plugin\Catalog\Product\`, `Plugin\Catalog\Category\`.

## 4. PHP Class Templates

### 4.1 Before Plugin

```php
<?php
/**
 * Copyright © Monsoon Consulting. All rights reserved.
 * See LICENSE_MONSOON.txt for license details.
 */

declare(strict_types=1);

namespace {Vendor}\{ModuleName}\Plugin\{TargetArea};

use {TargetClassFQN};

final class {ClassName}
{
    /**
     * Modify arguments before {TargetShortName}::{method}()
     *
     * @return array|null Null to keep original arguments, array to replace them
     */
    public function before{Method}(
        {TargetShortName} $subject,
        {originalParams}
    ): ?array {
        // Modify arguments and return as array, or return null to keep originals
        return [{modifiedParams}];
    }
}
```

**Before plugin rules:**
- Method name: `before` + PascalCase target method name
- First param is always `$subject` (the intercepted object instance)
- Remaining params match the original method signature exactly
- Return `null` to keep original arguments unchanged
- Return an array of arguments (positional) to replace them

### 4.2 After Plugin

```php
<?php
// Standard file header — see _shared/conventions.md
declare(strict_types=1);

namespace {Vendor}\{ModuleName}\Plugin\{TargetArea};

use {TargetClassFQN};

final class {ClassName}
{
    /**
     * Modify result after {TargetShortName}::{method}()
     */
    public function after{Method}(
        {TargetShortName} $subject,
        {returnType} $result
    ): {returnType} {
        // Modify and return the result
        return $result;
    }
}
```

**After plugin rules:**
- Method name: `after` + PascalCase target method name
- First param is `$subject`, second is `$result` (original return value)
- Must return the (optionally modified) result
- Return type must match the original method

### 4.3 Around Plugin

```php
<?php
// Standard file header — see _shared/conventions.md
declare(strict_types=1);

namespace {Vendor}\{ModuleName}\Plugin\{TargetArea};

use {TargetClassFQN};

final class {ClassName}
{
    /**
     * Wrap {TargetShortName}::{method}()
     */
    public function around{Method}(
        {TargetShortName} $subject,
        callable $proceed,
        {originalParams}
    ): {returnType} {
        // Pre-processing
        $result = $proceed({paramNames});
        // Post-processing
        return $result;
    }
}
```

**Around plugin rules:**
- Method name: `around` + PascalCase target method name
- First param is `$subject`, second is `callable $proceed`
- Remaining params match the original method signature
- **MUST** call `$proceed()` unless intentionally skipping the original method
- Pass original (or modified) arguments to `$proceed()`
- Return type must match the original method

### 4.4 Plugin with Constructor Dependencies

When the plugin needs injected services, use PHP 8.2 constructor promotion:

```php
<?php
// Standard file header — see _shared/conventions.md
declare(strict_types=1);

namespace {Vendor}\{ModuleName}\Plugin\{TargetArea};

use {TargetClassFQN};
use Psr\Log\LoggerInterface;

final class {ClassName}
{
    public function __construct(
        private readonly LoggerInterface $logger
    ) {
    }

    public function after{Method}(
        {TargetShortName} $subject,
        {returnType} $result
    ): {returnType} {
        $this->logger->info('Method intercepted');
        return $result;
    }
}
```

### 4.5 Multi-Method Plugin

A single plugin class can intercept multiple methods on the same target. Only one `<plugin>` entry is needed in di.xml:

```php
final class {ClassName}
{
    public function afterGetById(
        {TargetShortName} $subject,
        {returnType} $result
    ): {returnType} {
        return $result;
    }

    public function afterSave(
        {TargetShortName} $subject,
        {returnType} $result
    ): {returnType} {
        return $result;
    }
}
```

## 5. di.xml Configuration

### 5.1 Global Plugin (etc/di.xml)

```xml
<?xml version="1.0"?>
<!--
/**
 * Copyright © Monsoon Consulting. All rights reserved.
 * See LICENSE_MONSOON.txt for license details.
 */
-->
<config xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
        xsi:noNamespaceSchemaLocation="urn:magento:framework:ObjectManager/etc/config.xsd">
    <type name="{TargetClassFQN}">
        <plugin name="{vendor}_{modulename}_{target_short}_{method}_{type}"
                type="{Vendor}\{ModuleName}\Plugin\{TargetArea}\{ClassName}"/>
    </type>
</config>
```

### 5.2 Area-Specific Plugin (etc/frontend/di.xml or etc/adminhtml/di.xml)

```xml
<?xml version="1.0"?>
<!-- Standard XML header — see _shared/conventions.md -->
<config xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
        xsi:noNamespaceSchemaLocation="urn:magento:framework:ObjectManager/etc/config.xsd">
    <type name="{TargetClassFQN}">
        <plugin name="{vendor}_{modulename}_{target_short}_{method}_{type}"
                type="{Vendor}\{ModuleName}\Plugin\{TargetArea}\{ClassName}"
                sortOrder="10"/>
    </type>
</config>
```

### 5.3 With Sort Order

Add `sortOrder` when multiple plugins target the same method and execution order matters:

```xml
<plugin name="{plugin_name}"
        type="{PluginClassFQN}"
        sortOrder="20"/>
```

Lower sortOrder executes first for `before`/`around`, last for `after`.

### 5.4 Disabling a Third-Party Plugin

```xml
<type name="{TargetClassFQN}">
    <plugin name="{third_party_plugin_name}" disabled="true"/>
</type>
```

**Virtual type inheritance:** Plugins registered on a parent class also apply to its virtual types. If you plugin a class that has virtual types, your plugin intercepts calls on those virtual types too. Be aware of this when plugging widely-used classes like `Magento\Framework\Logger\Monolog`.

## 6. Generation Rules

Follow this sequence when generating a plugin:

1. **Verify the target module exists** — check that `app/code/{Vendor}/{ModuleName}/registration.php` exists. If not, instruct the user to scaffold it first.

2. **Look up the target method signature** — find the target class/interface in `vendor/` and read the exact method signature (parameter types, names, return type). The plugin method must match.

3. **Check if di.xml exists** for the target area:
   - **Global:** `app/code/{Vendor}/{ModuleName}/etc/di.xml`
   - **Area-specific:** `app/code/{Vendor}/{ModuleName}/etc/{area}/di.xml`
   - If the file exists, **append** the `<type>` block inside the existing `<config>` element.
   - If the file does not exist, **create** it with the full XML structure including copyright header.

4. **Create the Plugin PHP class** at the correct path under `Plugin/`.

5. **Match the target method signature exactly** — use the same parameter types, names, and return type. Import all necessary classes with `use` statements.

6. **Remind the user** to run post-generation commands (see section 8).

## 7. Anti-Patterns and Pitfalls

**Performance implications of plugin types.**
Around plugins are the most expensive interceptor type — they wrap the entire call chain and prevent some PHP opcache optimizations. Before/after plugins are significantly cheaper. Avoid plugins on hot-path methods called thousands of times per request (e.g., `getData()`, `load()`, `getItemById()`). When you see 5+ plugins stacking on one method, consider consolidating into a single plugin or using a preference instead.

**Avoid around plugins when before/after suffice.**
Around plugins are the most expensive interceptor type. They wrap the entire call chain and are harder to debug. Use `before` to modify arguments, `after` to modify results. Reserve `around` for cases that truly need both or need to skip `$proceed()`.

**Never plugin these:**
- `__construct` — DI creates objects before interceptors are attached
- `final` methods or classes — interceptors cannot be generated
- `static` methods — not dispatched through the object manager
- `private` or `protected` methods — only `public` methods can be intercepted

**Null return in before plugins means "keep original arguments".**
Returning `null` from a `before` plugin preserves the original arguments. Returning an empty array `[]` replaces all arguments with nothing. This is a common source of bugs.

**Execution order with multiple plugins:**
1. All `before` plugins run (lowest sortOrder first)
2. All `around` plugins wrap (lowest sortOrder = outermost wrapper)
3. The original method executes
4. All `after` plugins run (lowest sortOrder last)

**Do not call methods on `$subject` that trigger the same plugin.**
Calling `$subject->sameMethod()` inside your plugin creates an infinite recursion. If you need the original behavior, use `$proceed()` (around) or access the data another way.

**Plugin on interface vs concrete class:**
- Plugging an **interface** intercepts ALL implementations — preferred for service contracts
- Plugging a **concrete class** intercepts only that specific implementation
- Choose based on whether you want the behavior globally or for a specific class

## 8. Post-Generation Steps

Follow `.claude/skills/_shared/post-generation.md` for: di.xml, new module enable.
