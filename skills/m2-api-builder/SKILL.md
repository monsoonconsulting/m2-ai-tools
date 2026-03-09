---
name: m2-api-builder
description: >
  Generate Magento 2 REST API code including service contracts, repository
  interfaces, repository implementations, webapi.xml, and acl.xml. Use this
  skill whenever the user asks to create a REST API, expose an entity via REST,
  or build service contracts.
  Trigger on: "create API", "REST API", "repository interface",
  "service contract", "API endpoint", "webapi", "expose entity",
  "CRUD API", "build API", "getList", "search results", "webapi.xml",
  "data interface", "repository pattern", "API resource", "repository",
  "SearchCriteria", "API contract", "getById", "pagination", "search criteria filter".
  For GraphQL APIs, use /m2-graphql-builder instead.
---

# Magento 2 API Builder

You are a Magento 2 REST API specialist. Generate REST API code under existing modules in `app/code/{Vendor}/{ModuleName}/`.

Follow the coding conventions and file headers defined in `.claude/skills/_shared/conventions.md` and `.claude/skills/m2-module/SKILL.md`. Do not duplicate those conventions here.

**Prerequisites:** Module must exist (see `_shared/conventions.md`). If not, use `/m2-module` first.
- The Model, ResourceModel, and Collection classes should exist for the entity. If not, tell the user to create the database layer first with `/m2-db-schema` and then create the Model/ResourceModel/Collection classes.

## 1. Decision Tree

**Generate REST API when:**
- External systems need to integrate (ERP, PIM, mobile apps)
- You need standard CRUD endpoints with token/OAuth authentication
- The consumer expects JSON over HTTP with standard status codes

**For GraphQL APIs** — use `/m2-graphql-builder` instead.

**Do NOT use this skill when:**
- You only need an admin grid UI — use `/m2-admin-ui` instead
- The entity has no external consumers — a simple Model layer suffices
- You need to modify an existing Magento API — use `/m2-plugin`

**Model + Data Interface:** When building a REST API, the Model class should implement the Data Interface. See `references/model-resource-collection.md` in m2-db-schema for the template.

## 2. Gather Requirements

Before generating any files, collect the following from the user.

**Required (ask if not provided):**
- **Module name** — `Vendor_ModuleName`
- **Entity name** — PascalCase (e.g., `BlogPost`)
- **Properties** — name + type for each (e.g., `title:string`, `is_active:bool`)
- **API type** — `rest` (for GraphQL, use `/m2-graphql-builder`)

**Optional (use defaults if not specified):**
- **ACL resource level** — `admin` (default), `self` (customer), or `anonymous`
- **REST URL prefix** — default: `/V1/{vendor-lower}-{module-lower}`
- **Primary key column** — default: `entity_id`

## 3. Naming Conventions

| Concept | Convention | Example |
|---------|-----------|---------|
| Data Interface | `Api\Data\{Entity}Interface` | `Api\Data\BlogPostInterface` |
| Repository Interface | `Api\{Entity}RepositoryInterface` | `Api\BlogPostRepositoryInterface` |
| SearchResults Interface | `Api\Data\{Entity}SearchResultsInterface` | `Api\Data\BlogPostSearchResultsInterface` |
| SearchResults Implementation | `Model\{Entity}SearchResults` | `Model\BlogPostSearchResults` |
| Repository Implementation | `Model\{Entity}Repository` | `Model\BlogPostRepository` |
| REST URL (single) | `/V1/{vendor}-{module}/{entity-kebab}/:id` | `/V1/acme-blog/blog-post/:entityId` |
| REST URL (list) | `/V1/{vendor}-{module}/{entity-kebab-plural}` | `/V1/acme-blog/blog-posts` |
| ACL resource | `{Vendor}_{ModuleName}::{entity_snake}` | `Acme_Blog::blog_post` |

## 4. REST API Templates

### 4.1 Data Interface — `Api/Data/{Entity}Interface.php`

```php
<?php
/**
 * Copyright © Monsoon Consulting. All rights reserved.
 * See LICENSE_MONSOON.txt for license details.
 */

declare(strict_types=1);

namespace {Vendor}\{ModuleName}\Api\Data;

/**
 * @api
 */
interface {Entity}Interface
{
    public const ENTITY_ID = 'entity_id';
    public const TITLE = 'title';
    public const IS_ACTIVE = 'is_active';

    /**
     * @return int|null
     */
    public function getEntityId(): ?int;

    /**
     * @param int $entityId
     * @return $this
     */
    public function setEntityId(int $entityId): self;

    /**
     * @return string|null
     */
    public function getTitle(): ?string;

    /**
     * @param string $title
     * @return $this
     */
    public function setTitle(string $title): self;

    /**
     * @return bool
     */
    public function getIsActive(): bool;

    /**
     * @param bool $isActive
     * @return $this
     */
    public function setIsActive(bool $isActive): self;
}
```

**Repeat the constant + getter + setter pattern for each property.** The Model class implements this interface using simple get/set methods backed by `getData()`/`setData()`.

**CRITICAL:** Every getter/setter must have a `@return` / `@param` docblock with the fully qualified type. Magento's REST serializer uses reflection on these docblocks — not PHP type hints — to serialize/deserialize JSON. Without FQN docblocks, the API returns empty or broken responses.

### 4.2 Repository Interface — `Api/{Entity}RepositoryInterface.php`

```php
<?php
/**
 * Copyright © Monsoon Consulting. All rights reserved.
 * See LICENSE_MONSOON.txt for license details.
 */

declare(strict_types=1);

namespace {Vendor}\{ModuleName}\Api;

use {Vendor}\{ModuleName}\Api\Data\{Entity}Interface;
use {Vendor}\{ModuleName}\Api\Data\{Entity}SearchResultsInterface;
use Magento\Framework\Api\SearchCriteriaInterface;
use Magento\Framework\Exception\CouldNotDeleteException;
use Magento\Framework\Exception\CouldNotSaveException;
use Magento\Framework\Exception\NoSuchEntityException;

/**
 * @api
 */
interface {Entity}RepositoryInterface
{
    /**
     * @param int $entityId
     * @return \{Vendor}\{ModuleName}\Api\Data\{Entity}Interface
     * @throws \Magento\Framework\Exception\NoSuchEntityException
     */
    public function getById(int $entityId): {Entity}Interface;

    /**
     * @param \{Vendor}\{ModuleName}\Api\Data\{Entity}Interface $entity
     * @return \{Vendor}\{ModuleName}\Api\Data\{Entity}Interface
     * @throws \Magento\Framework\Exception\CouldNotSaveException
     */
    public function save({Entity}Interface $entity): {Entity}Interface;

    /**
     * @param \{Vendor}\{ModuleName}\Api\Data\{Entity}Interface $entity
     * @return bool
     * @throws \Magento\Framework\Exception\CouldNotDeleteException
     */
    public function delete({Entity}Interface $entity): bool;

    /**
     * @param int $entityId
     * @return bool
     * @throws \Magento\Framework\Exception\CouldNotDeleteException
     * @throws \Magento\Framework\Exception\NoSuchEntityException
     */
    public function deleteById(int $entityId): bool;

    /**
     * @param \Magento\Framework\Api\SearchCriteriaInterface $searchCriteria
     * @return \{Vendor}\{ModuleName}\Api\Data\{Entity}SearchResultsInterface
     */
    public function getList(SearchCriteriaInterface $searchCriteria): {Entity}SearchResultsInterface;
}
```

Same FQN docblock rule as the Data Interface applies here — all `@param`/`@return` must use fully qualified class names with leading `\`.

### 4.3 SearchResults Interface & Implementation

**Interface — `Api/Data/{Entity}SearchResultsInterface.php`:**

```php
<?php
/**
 * Copyright © Monsoon Consulting. All rights reserved.
 * See LICENSE_MONSOON.txt for license details.
 */

declare(strict_types=1);

namespace {Vendor}\{ModuleName}\Api\Data;

use Magento\Framework\Api\SearchResultsInterface;

/**
 * @api
 */
interface {Entity}SearchResultsInterface extends SearchResultsInterface
{
    /**
     * @return \{Vendor}\{ModuleName}\Api\Data\{Entity}Interface[]
     */
    public function getItems(): array;

    /**
     * @param \{Vendor}\{ModuleName}\Api\Data\{Entity}Interface[] $items
     * @return $this
     */
    public function setItems(array $items): self;
}
```

**Implementation — `Model/{Entity}SearchResults.php`:**

```php
<?php
/**
 * Copyright © Monsoon Consulting. All rights reserved.
 * See LICENSE_MONSOON.txt for license details.
 */

declare(strict_types=1);

namespace {Vendor}\{ModuleName}\Model;

use {Vendor}\{ModuleName}\Api\Data\{Entity}SearchResultsInterface;
use Magento\Framework\Api\SearchResults;

final class {Entity}SearchResults extends SearchResults implements {Entity}SearchResultsInterface
{
}
```

### 4.4 Repository Implementation — `Model/{Entity}Repository.php`

See `references/repository-implementation.md` for the full Repository class template including SearchCriteria usage.

### 4.5 XML Configuration (webapi.xml, di.xml, acl.xml)

See `references/api-xml-config.md` for webapi.xml routes, di.xml preferences, and acl.xml templates.

**ACL resource options:**
- Custom ACL ID — admin-only (requires integration or admin token)
- `self` — authenticated customer accessing own data
- `anonymous` — public access, no authentication required

## 5. Generation Rules

Follow this sequence when generating API code:

1. **Verify the module exists** — check `app/code/{Vendor}/{ModuleName}/registration.php`. If missing, instruct user to run `/m2-module`.

2. **Verify the Model layer exists** — check that `Model/{Entity}.php`, `Model/ResourceModel/{Entity}.php`, and `Model/ResourceModel/{Entity}/Collection.php` exist. If missing, instruct the user to create them (use `/m2-db-schema` for the table first, then create Model/ResourceModel/Collection).

3. **Create Data Interface** — `Api/Data/{Entity}Interface.php` with constants, getters, setters, and FQN docblocks.

4. **Create Repository Interface** — `Api/{Entity}RepositoryInterface.php` with FQN docblocks on every method.

5. **Create SearchResults Interface + Implementation** — `Api/Data/{Entity}SearchResultsInterface.php` and `Model/{Entity}SearchResults.php`.

6. **Create Repository Implementation** — `Model/{Entity}Repository.php`.

7. **Update di.xml** — add `<preference>` entries for all three interfaces. Create or append.

8. **Create or update webapi.xml** — add all 5 CRUD routes. Create or append.

9. **Create or update acl.xml** — add the entity-level ACL resource. Create or append.

10. **Make the Model implement the Data Interface** — update the existing `Model/{Entity}.php` to `implements {Entity}Interface` and add the getter/setter methods if not already present.

## 6. Anti-Patterns

**Missing FQN in docblocks.**
Magento REST serialization uses reflection on `@param`/`@return` docblocks. Always use fully qualified class names with leading `\`. Without this, the API returns empty responses or errors.

**Using ObjectManager in repository classes.** Use constructor injection. The repository receives ResourceModel, Factory, CollectionFactory, and CollectionProcessor through DI.

**Business logic in repositories.** Repositories are persistence-only. Validation, business rules, and side effects belong in service classes or plugins.

**`@api` on implementations.** Only add `@api` to interfaces, never to concrete classes. The interface is the stable contract.

**Wrong ACL resource selection:**
- `anonymous` — use only for public-facing read-only data (store config, CMS content)
- `self` — customer accessing their own data (orders, addresses, wishlist)
- Custom ACL ID — admin/integration access (most common for custom entities)

**Extending existing APIs:** To add custom fields to existing Magento API responses (Order, Product, Customer, etc.) rather than creating new endpoints, use `/m2-extension-attributes`.

## 7. Post-Generation Steps

After generating API code, remind the user to run:

```bash
bin/magento module:enable {Vendor}_{ModuleName}  # If not yet enabled
bin/magento setup:upgrade && bin/magento setup:di:compile && bin/magento cache:flush
```

**Quick smoke test:** `curl -X GET https://magento.test/rest/V1/{vendor}-{module}/{entity-kebab}/1 -H "Authorization: Bearer <token>"`