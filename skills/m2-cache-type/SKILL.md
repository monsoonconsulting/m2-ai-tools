---
name: m2-cache-type
description: >
  Generate Magento 2 custom cache types including cache.xml registration,
  TagScope decorator class, cache tag patterns, and CacheInterface usage.
  Use this skill whenever the user asks to create a custom cache, cache type,
  cache tags, or needs to optimize data retrieval with caching.
  Trigger on: "custom cache", "cache type", "cache.xml", "cache tag",
  "CacheInterface", "TypeListInterface", "cache invalidation", "cache key",
  "TagScope", "create cache", "add cache type", "register cache",
  "cache:flush", "cache:clean", "full page cache", "FPC", "Varnish cache",
  "performance", "slow queries", "response caching",
  "caching strategy", "cache layer", "Redis cache", "cache backend".
---

# Magento 2 Custom Cache Type Generator

You are a Magento 2 caching specialist. Generate custom cache types, cache tag patterns, and CacheInterface usage under existing modules in `app/code/{Vendor}/{ModuleName}/`.

Follow the coding conventions and file headers defined in `.claude/skills/_shared/conventions.md` and `.claude/skills/m2-module/SKILL.md`. Do not duplicate those conventions here.

**Prerequisites:** Module must exist (see `_shared/conventions.md`). If not, use `/m2-module` first.

## 1. Decision Tree

**Use a custom cache type when:**
- Your module makes expensive computations or external API calls that can be cached
- Data changes infrequently but is read frequently
- You need granular cache invalidation (flush only your module's cache, not all caches)

**Use the built-in `config` cache instead when:**
- You're caching configuration data that changes only on config save

**Use FPC (Full Page Cache) / Varnish instead when:**
- You need to cache entire HTTP responses — FPC is a built-in cache type, not custom
- For FPC cache tag integration in blocks, implement `IdentityInterface` on your Block/ViewModel

**Do NOT use this skill when:**
- You need to store session data — use session storage
- You need persistent cross-request data — use the database via `/m2-db-schema`

## 2. Gather Requirements

Before generating any files, collect the following from the user.

**Required (ask if not provided):**
- **Module name** — `Vendor_ModuleName`
- **Cache type purpose** — what data is being cached
- **Cache type ID** — short identifier (e.g., `acme_api_responses`)

**Optional (use defaults if not specified):**
- **Cache tag prefix** — default: derived from module name
- **Default enabled?** — default: yes

## 3. Naming Conventions

| Concept | Convention | Example |
|---------|-----------|---------|
| Cache type ID | `{vendor}_{module}_{descriptive}` | `acme_shipping_rates` |
| Cache tag prefix | uppercase `{VENDOR}_{MODULE}` | `ACME_SHIPPING` |
| Type class | `Model\Cache\Type\{Name}` | `Model\Cache\Type\ShippingRates` |
| cache.xml ID | same as cache type ID | `acme_shipping_rates` |

## 4. Templates

### 4.1 cache.xml — `etc/cache.xml`

```xml
<?xml version="1.0"?>
<!--
/**
 * Copyright © Monsoon Consulting. All rights reserved.
 * See LICENSE_MONSOON.txt for license details.
 */
-->
<config xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
        xsi:noNamespaceSchemaLocation="urn:magento:framework:Cache/etc/cache.xsd">
    <type name="{cache_type_id}"
          translate="label,description"
          instance="{Vendor}\{ModuleName}\Model\Cache\Type\{ClassName}">
        <label>{Cache Type Label}</label>
        <description>{What this cache stores}</description>
    </type>
</config>
```

### 4.2 Cache Type Class — `Model/Cache/Type/{ClassName}.php`

```php
<?php
/**
 * Copyright © Monsoon Consulting. All rights reserved.
 * See LICENSE_MONSOON.txt for license details.
 */

declare(strict_types=1);

namespace {Vendor}\{ModuleName}\Model\Cache\Type;

use Magento\Framework\App\Cache\Type\FrontendPool;
use Magento\Framework\Cache\Frontend\Decorator\TagScope;

class {ClassName} extends TagScope
{
    public const TYPE_IDENTIFIER = '{cache_type_id}';
    public const CACHE_TAG = '{CACHE_TAG_PREFIX}';

    public function __construct(FrontendPool $cacheFrontendPool)
    {
        parent::__construct($cacheFrontendPool->get(self::TYPE_IDENTIFIER), self::CACHE_TAG);
    }
}
```

The `TagScope` decorator ensures all cache entries written through this type are automatically tagged with `CACHE_TAG`. This enables flushing only this cache type via `bin/magento cache:clean {cache_type_id}`.

### 4.3 Using the Cache in Services

```php
<?php
// Standard file header — see _shared/conventions.md
declare(strict_types=1);

namespace {Vendor}\{ModuleName}\Service;

use {Vendor}\{ModuleName}\Model\Cache\Type\{ClassName} as CacheType;
use Magento\Framework\Serialize\SerializerInterface;

final class {ServiceClass}
{
    public function __construct(
        private readonly CacheType $cache,
        private readonly SerializerInterface $serializer
    ) {
    }

    public function getExpensiveData(string $key): array
    {
        $cacheKey = CacheType::CACHE_TAG . '_' . $key;
        $cached = $this->cache->load($cacheKey);

        if ($cached !== false) {
            return $this->serializer->unserialize($cached);
        }

        $data = $this->computeExpensiveData($key);

        $this->cache->save(
            $this->serializer->serialize($data),
            $cacheKey,
            [CacheType::CACHE_TAG],
            3600 // TTL in seconds (null = infinite)
        );

        return $data;
    }

    public function invalidate(string $key): void
    {
        $cacheKey = CacheType::CACHE_TAG . '_' . $key;
        $this->cache->remove($cacheKey);
    }

    public function invalidateAll(): void
    {
        $this->cache->clean();
    }

    private function computeExpensiveData(string $key): array
    {
        // Expensive computation or API call
        return [];
    }
}
```

### 4.4 Cache Tag Integration with FPC (Block/ViewModel)

If your entity data appears on frontend pages cached by FPC/Varnish, implement `IdentityInterface` on the Block:

```php
use Magento\Framework\DataObject\IdentityInterface;
use Magento\Framework\View\Element\Template;

class {BlockName} extends Template implements IdentityInterface
{
    public function getIdentities(): array
    {
        // Return cache tags for all entities displayed by this block
        return ['{CACHE_TAG_PREFIX}_' . $this->getEntityId()];
    }
}
```

### 4.5 Granular Cache Tags

Use entity-specific tags for surgical invalidation:

```php
// In your Model class
public function getIdentities(): array
{
    return [CacheType::CACHE_TAG . '_' . $this->getId()];
}

// When saving, Magento automatically cleans matching FPC entries
```

Tag convention: `{CACHE_TAG}_{entity_id}` for individual entities, `{CACHE_TAG}` alone for full-type invalidation.

### 4.6 Programmatic Cache Invalidation via TypeListInterface

```php
use Magento\Framework\App\Cache\TypeListInterface;

public function __construct(
    private readonly TypeListInterface $cacheTypeList
) {
}

public function invalidateCacheType(): void
{
    $this->cacheTypeList->invalidate('{cache_type_id}');
}
```

## 5. Cache API Reference

| Method | Purpose |
|--------|---------|
| `$cache->load($id)` | Load cached data by key. Returns `false` if not found. |
| `$cache->save($data, $id, $tags, $ttl)` | Save data with tags and optional TTL. |
| `$cache->remove($id)` | Remove a single cache entry by key. |
| `$cache->clean()` | Remove all entries with this cache type's tag. |
| `$cacheTypeList->invalidate($typeId)` | Mark a cache type as invalidated (yellow in admin). |
| `$cacheTypeList->cleanType($typeId)` | Actually flush a cache type. |

## 6. Built-In Cache Types

| Type ID | Label | Use |
|---------|-------|-----|
| `config` | Configuration | System config, di.xml |
| `layout` | Layouts | Layout XML files |
| `block_html` | Blocks HTML output | Block output caching |
| `collections` | Collections Data | Collection query results |
| `reflection` | Reflection Data | API/webapi interface reflection |
| `db_ddl` | Database DDL operations | Table schemas |
| `eav` | EAV types and attributes | Attribute metadata |
| `full_page` | Page Cache | Full HTTP response (Varnish/built-in) |
| `config_integration` | Integrations Configuration | Integration config |
| `config_webservice` | Web Services Configuration | WSDL/REST schema |
| `translate` | Translations | i18n data |

## 7. Generation Rules

Follow this sequence when generating a custom cache type:

1. **Verify the module exists** — check `registration.php`.

2. **Create `etc/cache.xml`** — register the cache type with label and description.

3. **Create the cache type class** — `Model/Cache/Type/{ClassName}.php` extending `TagScope`.

4. **Update the service class** — inject the cache type and add load/save/remove logic.

5. **Remind the user** to run post-generation commands.

## 8. Anti-Patterns

**Caching mutable data without invalidation.**
Every cache entry must have a clear invalidation strategy. If data changes and the cache isn't cleared, users see stale data.

**Using generic cache tags.**
Always use your module-specific tag prefix. Generic tags cause over-invalidation when other modules flush caches.

**Caching per-customer data in a shared cache.**
Customer-specific data (cart, wishlist) should include the customer ID in the cache key. Never cache private data where other customers could read it.

**Not serializing data before caching.**
The cache backend stores strings. Always use `SerializerInterface` for arrays/objects.

**Infinite TTL without invalidation.**
Either set a reasonable TTL or ensure you have event-driven invalidation. Data should never become permanently stale.

**Using `cache:flush` instead of `cache:clean`.**
`cache:flush` clears the entire cache backend (all types). `cache:clean` only removes invalidated entries. Use `cache:clean {type_id}` for surgical cache clearing.

## 9. Post-Generation Steps

Follow `.claude/skills/_shared/post-generation.md` for: cache.xml / cache type.

Verify the new cache type appears:
```bash
bin/magento cache:status          # Verify new cache type appears
bin/magento cache:enable {cache_type_id}   # Enable if not auto-enabled
```

To manage the cache:
```bash
bin/magento cache:clean {cache_type_id}    # Clean only this type
bin/magento cache:disable {cache_type_id}  # Disable during development
bin/magento cache:enable {cache_type_id}   # Re-enable for production
```
