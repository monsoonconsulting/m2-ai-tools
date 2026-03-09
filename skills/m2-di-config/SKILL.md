---
name: m2-di-config
description: >
  Configure Magento 2 dependency injection including preferences, virtual types,
  type constructor arguments, proxy classes, factory generation, and area-specific DI.
  Also covers custom logging: log handlers, Monolog virtual types, and PSR-3 logger configuration.
  Use this skill whenever the user asks to configure DI, set up preferences, create
  virtual types, configure constructor arguments, debug compiled DI, create custom log files,
  or configure logging.
  Trigger on: "di.xml", "dependency injection", "preference", "virtual type",
  "type argument", "constructor argument", "proxy", "factory", "ObjectManager",
  "interface binding", "implementation swap", "area DI", "compiled DI", "DI config",
  "configure injection", "replace implementation", "lazy loading proxy",
  "swap implementation", "service preference", "replace class",
  "custom log", "log handler", "log file", "Monolog", "LoggerInterface",
  "debug log", "custom logger", "var/log", "PSR-3", "logging", "virtual type logger",
  "logger", "log handler", "custom log file", "PSR-3 logger".
---

# Magento 2 Dependency Injection Configuration

You are a Magento 2 DI configuration specialist. Configure `di.xml` files for preferences, virtual types, type arguments, proxies, and factories under existing modules in `app/code/{Vendor}/{ModuleName}/`.

Follow the coding conventions and file headers defined in `.claude/skills/_shared/conventions.md` and `.claude/skills/m2-module/SKILL.md`. Do not duplicate those conventions here.

**Prerequisites:** Module must exist (see `_shared/conventions.md`). If not, use `/m2-module` first.

## 1. Decision Tree

**Use a preference when:**
- You need to replace an interface's default implementation globally
- You need to swap a concrete class for a subclass everywhere

**Use a virtual type when:**
- You need a configured variant of a class without creating a PHP file
- You need multiple instances of the same class with different constructor arguments (e.g., different loggers)

**Use type arguments when:**
- You need to pass specific values or objects to a class constructor
- You need to override a default constructor parameter for a specific class

**Use a proxy when:**
- A dependency is expensive to instantiate but rarely used
- You want lazy-loading: the real object is created only when a method is called

**Use a factory when:**
- You need to create multiple instances of a class at runtime
- The class is not a singleton (e.g., Models, DTOs, value objects)

**Use `/m2-plugin` instead when:**
- You need to modify method behavior, not swap implementations

## 2. Gather Requirements

Before generating any files, collect the following from the user.

**Required (ask if not provided):**
- **Module name** — `Vendor_ModuleName`
- **DI pattern needed** — preference, virtual type, type argument, proxy, or factory
- **Target class/interface** — fully qualified class name

**Optional (use defaults if not specified):**
- **Area** — `global` (default), `frontend`, `adminhtml`, `webapi_rest`, `crontab`
- **Shared** — default: `true` (singleton); set `false` for non-shared instances

## 3. Naming Conventions

| Concept | Convention | Example |
|---------|-----------|---------|
| di.xml (global) | `etc/di.xml` | All areas |
| di.xml (area) | `etc/{area}/di.xml` | `etc/frontend/di.xml` |
| Virtual type | `{Vendor}{ModuleName}{Purpose}` PascalCase | `AcmeShippingRateLogger` |
| Proxy class | `{OriginalClass}\Proxy` (auto-generated) | `Acme\Shipping\Service\RateCalculator\Proxy` |
| Factory class | `{OriginalClass}Factory` (auto-generated) | `Acme\Shipping\Model\RateFactory` |

## 4. Templates

### 4.1 Preference — Interface to Implementation

```xml
<?xml version="1.0"?>
<config xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
        xsi:noNamespaceSchemaLocation="urn:magento:framework:ObjectManager/etc/config.xsd">
    <preference for="{Vendor}\{ModuleName}\Api\{InterfaceName}"
                type="{Vendor}\{ModuleName}\Model\{ImplementationName}"/>
</config>
```

**Rules:**
- One preference per interface per area. Later preferences override earlier ones.
- Prefer plugging interfaces over concrete classes for broader effect.
- Area-specific preferences override global preferences.

### 4.2 Virtual Type

```xml
<virtualType name="{Vendor}{ModuleName}{Purpose}" type="{BaseClassName}">
    <arguments>
        <argument name="{paramName}" xsi:type="string">{value}</argument>
    </arguments>
</virtualType>
```

**Common use case — custom logger:**
```xml
<!-- Handler for custom log file -->
<virtualType name="AcmeShippingLogHandler" type="Magento\Framework\Logger\Handler\Base">
    <arguments>
        <argument name="fileName" xsi:type="string">/var/log/acme_shipping.log</argument>
    </arguments>
</virtualType>

<!-- Logger using custom handler -->
<virtualType name="AcmeShippingLogger" type="Magento\Framework\Logger\Monolog">
    <arguments>
        <argument name="name" xsi:type="string">acme_shipping</argument>
        <argument name="handlers" xsi:type="array">
            <item name="system" xsi:type="object">AcmeShippingLogHandler</item>
        </argument>
    </arguments>
</virtualType>

<!-- Inject into service -->
<type name="Acme\Shipping\Service\RateCalculator">
    <arguments>
        <argument name="logger" xsi:type="object">AcmeShippingLogger</argument>
    </arguments>
</type>
```

Virtual types exist only in DI configuration — no PHP file is created. They cannot be type-hinted directly; inject via `<type>` argument configuration.

### 4.3 Type Constructor Arguments

```xml
<type name="{Vendor}\{ModuleName}\{ClassName}">
    <arguments>
        <argument name="{paramName}" xsi:type="string">{value}</argument>
        <argument name="{paramName}" xsi:type="boolean">true</argument>
        <argument name="{paramName}" xsi:type="number">42</argument>
        <argument name="{paramName}" xsi:type="const">{Vendor}\{ModuleName}\Model\Config::CONSTANT_NAME</argument>
        <argument name="{paramName}" xsi:type="null"/>
        <argument name="{paramName}" xsi:type="object">{Vendor}\{ModuleName}\Model\{ClassName}</argument>
        <argument name="{paramName}" xsi:type="init_parameter">{Vendor}\{ModuleName}\Model\Config::PARAM</argument>
        <argument name="items" xsi:type="array">
            <item name="key1" xsi:type="string">value1</item>
            <item name="key2" xsi:type="object">{ClassName}</item>
        </argument>
    </arguments>
</type>
```

**Argument types:** `string`, `boolean`, `number`, `const`, `null`, `object` (DI-resolved), `init_parameter`, `array`.

### 4.4 Proxy (Lazy Loading)

```xml
<type name="{Vendor}\{ModuleName}\{ClassName}">
    <arguments>
        <argument name="{expensiveService}" xsi:type="object">{Vendor}\{ModuleName}\Service\{ExpensiveService}\Proxy</argument>
    </arguments>
</type>
```

Magento auto-generates proxy classes. The proxy implements the same interface as the original class but defers instantiation until the first method call. No PHP file needed.

**When to use:**
- CLI commands that inject services only used in specific subcommands
- Observers that inject heavy services used only conditionally
- Any class where a dependency is used in <50% of executions

**Area-specific proxies:** When a proxy is only needed in a specific area (e.g., a heavy service used only on frontend), configure the proxy injection in the area-specific di.xml (`etc/frontend/di.xml`) rather than globally.

### 4.5 Factory Usage

Factories are auto-generated by Magento. To use one, type-hint it in your constructor:

```php
public function __construct(
    private readonly \{Vendor}\{ModuleName}\Model\{Entity}Factory $entityFactory
) {
}

public function createEntity(): \{Vendor}\{ModuleName}\Model\{Entity}
{
    return $this->entityFactory->create(['data' => ['key' => 'value']]);
}
```

No di.xml configuration needed — Magento generates the factory class automatically during `setup:di:compile`. Use factories for non-singleton objects (Models, DTOs).

### 4.6 Non-Shared (Transient) Instances

```xml
<type name="{Vendor}\{ModuleName}\{ClassName}" shared="false"/>
```

By default, all DI-resolved objects are shared (singleton). Set `shared="false"` to get a new instance on every injection. Use sparingly — most services should be stateless singletons.

### 4.7 Sensitive Configuration

```xml
<type name="{Vendor}\{ModuleName}\{ClassName}">
    <arguments>
        <argument name="config" xsi:type="array">
            <item name="api_key" xsi:type="init_parameter">Magento\Config\Model\Config\Backend\Encrypted::class</item>
        </argument>
    </arguments>
</type>
```

## 5. Area-Specific DI

| Area | File | Scope |
|------|------|-------|
| Global | `etc/di.xml` | All areas (default) |
| Frontend | `etc/frontend/di.xml` | Storefront only |
| Admin | `etc/adminhtml/di.xml` | Admin panel only |
| REST API | `etc/webapi_rest/di.xml` | REST API only |
| SOAP API | `etc/webapi_soap/di.xml` | SOAP API only |
| Cron | `etc/crontab/di.xml` | Cron jobs only |
| GraphQL | `etc/graphql/di.xml` | GraphQL only |

**Precedence:** Area-specific DI overrides global DI. A preference in `etc/frontend/di.xml` takes priority over one in `etc/di.xml` for frontend requests.

## 5.1 Custom Logging via Virtual Types

The most common virtual type use case is a custom logger that writes to a module-specific log file. This requires:
1. A Handler PHP class extending `Magento\Framework\Logger\Handler\Base`
2. A virtual type logger in `di.xml` pointing to that handler
3. Injecting the virtual type logger into target classes

For the full logging reference (Handler template, log levels, built-in log files, JSON formatter, debug tips), see `references/logging-patterns.md`.

**Minimal inline example:**

```xml
<virtualType name="AcmeShippingLogHandler" type="Magento\Framework\Logger\Handler\Base">
    <arguments>
        <argument name="fileName" xsi:type="string">/var/log/acme_shipping.log</argument>
    </arguments>
</virtualType>

<virtualType name="AcmeShippingLogger" type="Magento\Framework\Logger\Monolog">
    <arguments>
        <argument name="name" xsi:type="string">acme_shipping</argument>
        <argument name="handlers" xsi:type="array">
            <item name="system" xsi:type="object">AcmeShippingLogHandler</item>
        </argument>
    </arguments>
</virtualType>
```

## 6. Generation Rules

1. **Verify the module exists** — check `registration.php`.
2. **Determine the area** — use global unless the DI should only apply to a specific area.
3. **Check if di.xml exists** for the target area. If yes, merge into existing `<config>` element. If no, create with copyright header.
4. **For preferences:** ensure the implementation class exists and implements the interface.
5. **For virtual types:** no PHP file needed — just the XML configuration.
6. **For proxies:** no PHP file needed — Magento auto-generates during `di:compile`.
7. **Remind the user** to run post-generation commands.

## 7. Debugging Compiled DI

```bash
# Show what class is resolved for an interface
bin/magento dev:di:info "{Vendor}\{ModuleName}\Api\{InterfaceName}"

# Regenerate compiled DI (required after di.xml changes)
rm -rf generated/code/ generated/metadata/
bin/magento setup:di:compile
```

**Common errors:**
- "Cannot instantiate interface" — missing `<preference>` in di.xml
- "Incompatible argument type" — di.xml argument type doesn't match constructor parameter type
- "Class does not exist" — typo in class name, or generated code is stale (re-run `di:compile`)

## 8. Anti-Patterns

**Using ObjectManager directly.**
Never call `ObjectManager::getInstance()->get()` or `create()`. Always use constructor injection. The only exceptions are in `registration.php`, factory/proxy generated code, and (rarely) static helper methods during bootstrapping.

**Preference when a plugin would suffice.**
Preferences replace the entire class. If you only need to modify one method, use a plugin (`/m2-plugin`). Preferences break if the original class changes significantly across versions.

**Virtual type name collisions.**
Virtual type names are global. Always prefix with your vendor and module name to avoid conflicts with other modules.

**Circular dependencies.**
If class A depends on B and B depends on A, you get an infinite loop. Break the cycle by using a proxy for one of the dependencies, or extract shared logic into a third class.

**Non-shared services with state.**
If a service has `shared="false"`, each injection gets a fresh instance. Any state set on one instance is invisible to others. This is usually not what you want.

## 9. Post-Generation Steps

See `.claude/skills/_shared/post-generation.md` for the full command reference.

**Skill-specific verification:**
- Run `bin/magento setup:di:compile` after any di.xml change
- Use `bin/magento dev:di:info "{FullyQualifiedInterface}"` to verify the correct implementation is resolved
