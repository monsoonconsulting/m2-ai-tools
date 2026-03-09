---
name: m2-graphql-builder
description: >
  Generate Magento 2 GraphQL API code including schema.graphqls, query resolvers,
  mutation resolvers, BatchResolverInterface, IdentityInterface for cache tags,
  input types, and GraphQL error handling. Use this skill whenever the user asks
  to create a GraphQL API, query, mutation, resolver, or extend existing schema.
  Trigger on: "GraphQL", "graphql", "schema.graphqls", "resolver",
  "ResolverInterface", "BatchResolverInterface", "IdentityInterface",
  "GraphQL query", "GraphQL mutation", "GraphQL type", "extend schema",
  "schema extension", "add field to product", "add field to cart",
  "extend product graphql", "extend cart graphql",
  "graphql cache", "graphql input", "create GraphQL", "add GraphQL",
  "headless", "PWA", "SPA", "Venia", "storefront API".
---

# Magento 2 GraphQL Builder

You are a Magento 2 GraphQL API specialist. Generate GraphQL schema definitions, resolvers, cache identity classes, and mutations under existing modules in `app/code/{Vendor}/{ModuleName}/`.

Follow the coding conventions and file headers defined in `.claude/skills/_shared/conventions.md` and `.claude/skills/m2-module/SKILL.md`. Do not duplicate those conventions here.

**Prerequisites:** Module must exist (see `_shared/conventions.md`). If not, use `/m2-module` first. For new entities: the repository and service contracts should exist. If not, use `/m2-api-builder` first.

## 1. Decision Tree

**Use GraphQL when:**
- A headless/PWA storefront consumes the data
- The client needs to select specific fields or nest related data
- You want to avoid over-fetching (client controls response shape)

**Use REST API instead when:**
- External systems integrate (ERP, PIM) — see `/m2-api-builder`
- You need standard HTTP methods with status codes
- The consumer expects a fixed response structure

**Extend existing schema when:**
- You need to add fields to existing Magento GraphQL types (e.g., add custom field to `ProductInterface`)

## 2. Gather Requirements

Before generating any files, collect the following from the user.

**Required (ask if not provided):**
- **Module name** — `Vendor_ModuleName`
- **Entity name** — PascalCase (e.g., `BlogPost`)
- **Fields** — name + type for each (e.g., `title:String`, `is_active:Boolean`)
- **Operations** — query, mutation, or both

**Optional (use defaults if not specified):**
- **Cache tags?** — default: yes (generates IdentityInterface)
- **Batch resolver?** — default: no. Use for list queries to prevent N+1.
- **Extend existing type?** — default: no (creates new types)

## 3. Naming Conventions

| Concept | Convention | Example |
|---------|-----------|---------|
| GraphQL type | `{Entity}` | `BlogPost` |
| GraphQL query (single) | `{entityCamel}` | `blogPost` |
| GraphQL query (list) | `{entityCamelPlural}` | `blogPosts` |
| GraphQL mutation | `create{Entity}` / `update{Entity}` / `delete{Entity}` | `createBlogPost` |
| GraphQL input | `{Entity}Input` | `BlogPostInput` |
| GraphQL filter | `{Entity}FilterInput` | `BlogPostFilterInput` |
| GraphQL list type | `{Entity}List` | `BlogPostList` |
| Query resolver class | `Model\Resolver\{Entity}` | `Model\Resolver\BlogPost` |
| List resolver class | `Model\Resolver\{Entity}List` | `Model\Resolver\BlogPostList` |
| Mutation resolver class | `Model\Resolver\Create{Entity}` | `Model\Resolver\CreateBlogPost` |
| Identity class | `Model\Resolver\{Entity}\Identity` | `Model\Resolver\BlogPost\Identity` |

## 4. Templates

### 4.1 schema.graphqls — `etc/schema.graphqls`

```graphql
# Copyright © Monsoon Consulting. All rights reserved.
# See LICENSE_MONSOON.txt for license details.

type Query {
    {entityCamel}(entity_id: Int! @doc(description: "Entity ID")): {Entity}
        @resolver(class: "{Vendor}\\{ModuleName}\\Model\\Resolver\\{Entity}")
        @doc(description: "Get a single {entity} by ID")
        @cache(cacheIdentity: "{Vendor}\\{ModuleName}\\Model\\Resolver\\{Entity}\\Identity")
    {entityCamelPlural}(
        filter: {Entity}FilterInput @doc(description: "Filter criteria")
        pageSize: Int = 20 @doc(description: "Page size")
        currentPage: Int = 1 @doc(description: "Current page")
    ): {Entity}List
        @resolver(class: "{Vendor}\\{ModuleName}\\Model\\Resolver\\{Entity}List")
        @doc(description: "Get a list of {entity-plural}")
        @cache(cacheIdentity: "{Vendor}\\{ModuleName}\\Model\\Resolver\\{Entity}\\Identity")
}

type Mutation {
    create{Entity}(input: {Entity}Input!): {Entity}
        @resolver(class: "{Vendor}\\{ModuleName}\\Model\\Resolver\\Create{Entity}")
        @doc(description: "Create a new {entity}")
    update{Entity}(entity_id: Int!, input: {Entity}Input!): {Entity}
        @resolver(class: "{Vendor}\\{ModuleName}\\Model\\Resolver\\Update{Entity}")
        @doc(description: "Update an existing {entity}")
    delete{Entity}(entity_id: Int!): Boolean
        @resolver(class: "{Vendor}\\{ModuleName}\\Model\\Resolver\\Delete{Entity}")
        @doc(description: "Delete a {entity}")
}

type {Entity} @doc(description: "{Entity} data") {
    entity_id: Int @doc(description: "Entity ID")
    title: String @doc(description: "Title")
    is_active: Boolean @doc(description: "Is Active")
}

type {Entity}List @doc(description: "List of {entity-plural}") {
    items: [{Entity}] @doc(description: "{Entity} items")
    total_count: Int @doc(description: "Total count")
}

input {Entity}FilterInput @doc(description: "Filter input for {entity-plural}") {
    entity_id: FilterTypeInput @doc(description: "Entity ID")
    title: FilterTypeInput @doc(description: "Title")
    is_active: FilterTypeInput @doc(description: "Is Active")
}

input {Entity}Input @doc(description: "Input for creating/updating a {entity}") {
    title: String @doc(description: "Title")
    is_active: Boolean @doc(description: "Is Active")
}
```

Add fields to `{Entity}`, `{Entity}FilterInput`, and `{Entity}Input` for each property.

### 4.2 Query Resolver — `Model/Resolver/{Entity}.php`

```php
<?php
/**
 * Copyright © Monsoon Consulting. All rights reserved.
 * See LICENSE_MONSOON.txt for license details.
 */

declare(strict_types=1);

namespace {Vendor}\{ModuleName}\Model\Resolver;

use {Vendor}\{ModuleName}\Api\{Entity}RepositoryInterface;
use Magento\Framework\Exception\NoSuchEntityException;
use Magento\Framework\GraphQl\Config\Element\Field;
use Magento\Framework\GraphQl\Exception\GraphQlInputException;
use Magento\Framework\GraphQl\Exception\GraphQlNoSuchEntityException;
use Magento\Framework\GraphQl\Query\ResolverInterface;
use Magento\Framework\GraphQl\Schema\Type\ResolveInfo;

final class {Entity} implements ResolverInterface
{
    public function __construct(
        private readonly {Entity}RepositoryInterface $repository
    ) {
    }

    public function resolve(Field $field, $context, ResolveInfo $info, ?array $value = null, ?array $args = null): array
    {
        if (!isset($args['entity_id'])) {
            throw new GraphQlInputException(__('entity_id is required.'));
        }

        try {
            $entity = $this->repository->getById((int) $args['entity_id']);
        } catch (NoSuchEntityException $e) {
            throw new GraphQlNoSuchEntityException(__($e->getMessage()), $e);
        }

        return $entity->getData();
    }
}
```

**CRITICAL:** Resolvers must return **arrays**, not objects. Use `$entity->getData()` to convert.

### 4.3 List Resolver — `Model/Resolver/{Entity}List.php`

```php
<?php
// Standard file header — see _shared/conventions.md
declare(strict_types=1);

namespace {Vendor}\{ModuleName}\Model\Resolver;

use {Vendor}\{ModuleName}\Model\ResourceModel\{Entity}\CollectionFactory;
use Magento\Framework\GraphQl\Config\Element\Field;
use Magento\Framework\GraphQl\Query\ResolverInterface;
use Magento\Framework\GraphQl\Schema\Type\ResolveInfo;

final class {Entity}List implements ResolverInterface
{
    public function __construct(
        private readonly CollectionFactory $collectionFactory
    ) {
    }

    public function resolve(Field $field, $context, ResolveInfo $info, ?array $value = null, ?array $args = null): array
    {
        $collection = $this->collectionFactory->create();

        if (isset($args['filter'])) {
            foreach ($args['filter'] as $filterField => $condition) {
                $collection->addFieldToFilter($filterField, $condition);
            }
        }

        $pageSize = $args['pageSize'] ?? 20;
        $currentPage = $args['currentPage'] ?? 1;
        $collection->setPageSize($pageSize);
        $collection->setCurPage($currentPage);

        $items = [];
        foreach ($collection->getItems() as $item) {
            $items[] = $item->getData();
        }

        return [
            'items' => $items,
            'total_count' => $collection->getSize(),
        ];
    }
}
```

### 4.4 Mutation Resolver — `Model/Resolver/Create{Entity}.php`

```php
<?php
// Standard file header — see _shared/conventions.md
declare(strict_types=1);

namespace {Vendor}\{ModuleName}\Model\Resolver;

use {Vendor}\{ModuleName}\Api\{Entity}RepositoryInterface;
use {Vendor}\{ModuleName}\Api\Data\{Entity}InterfaceFactory;
use Magento\Framework\GraphQl\Config\Element\Field;
use Magento\Framework\GraphQl\Exception\GraphQlInputException;
use Magento\Framework\GraphQl\Query\ResolverInterface;
use Magento\Framework\GraphQl\Schema\Type\ResolveInfo;

final class Create{Entity} implements ResolverInterface
{
    public function __construct(
        private readonly {Entity}RepositoryInterface $repository,
        private readonly {Entity}InterfaceFactory $entityFactory
    ) {
    }

    public function resolve(Field $field, $context, ResolveInfo $info, ?array $value = null, ?array $args = null): array
    {
        if (empty($args['input'])) {
            throw new GraphQlInputException(__('Input data is required.'));
        }

        $entity = $this->entityFactory->create();
        $entity->setData($args['input']);
        $saved = $this->repository->save($entity);

        return $saved->getData();
    }
}
```

For `Update{Entity}`: load via `getById()`, apply `$args['input']` with `setData`, save, return `getData()`.
For `Delete{Entity}`: load via `getById()`, delete, return `true`.

### 4.5 Cache Identity — `Model/Resolver/{Entity}/Identity.php`

```php
<?php
// Standard file header — see _shared/conventions.md
declare(strict_types=1);

namespace {Vendor}\{ModuleName}\Model\Resolver\{Entity};

use Magento\Framework\GraphQl\Query\Resolver\IdentityInterface;

final class Identity implements IdentityInterface
{
    private const CACHE_TAG = '{vendor}_{entity_snake}';

    public function getIdentities(array $resolvedData): array
    {
        $ids = [];

        if (isset($resolvedData['entity_id'])) {
            $ids[] = self::CACHE_TAG . '_' . $resolvedData['entity_id'];
        }

        if (isset($resolvedData['items'])) {
            foreach ($resolvedData['items'] as $item) {
                if (isset($item['entity_id'])) {
                    $ids[] = self::CACHE_TAG . '_' . $item['entity_id'];
                }
            }
        }

        return empty($ids) ? [] : $ids;
    }
}
```

### 4.6 Extending Existing Schema

To add fields to existing Magento GraphQL types (e.g., `ProductInterface`):

```graphql
# etc/schema.graphqls
type ProductInterface {
    custom_field: String @doc(description: "Custom field value")
        @resolver(class: "{Vendor}\\{ModuleName}\\Model\\Resolver\\Product\\CustomField")
}
```

The resolver receives the parent product data in `$value`:
```php
public function resolve(Field $field, $context, ResolveInfo $info, ?array $value = null, ?array $args = null): ?string
{
    if (!isset($value['entity_id'])) {
        return null;
    }

    return $this->getCustomFieldValue((int) $value['entity_id']);
}
```

### 4.7 BatchResolverInterface (N+1 Prevention)

```php
<?php
declare(strict_types=1);

namespace {Vendor}\{ModuleName}\Model\Resolver;

use Magento\Framework\GraphQl\Config\Element\Field;
use Magento\Framework\GraphQl\Query\Resolver\BatchResolverInterface;
use Magento\Framework\GraphQl\Query\Resolver\BatchResponse;
use Magento\Framework\GraphQl\Query\Resolver\ContextInterface;
use Magento\Framework\GraphQl\Query\Resolver\BatchRequestItemInterface;

final class {ResolverName} implements BatchResolverInterface
{
    public function resolve(ContextInterface $context, Field $field, array $requests): BatchResponse
    {
        // Collect all IDs from batch requests
        $ids = [];
        foreach ($requests as $request) {
            $ids[] = (int) $request->getValue()['entity_id'];
        }

        // Single query for all IDs
        $dataByIds = $this->loadDataByIds(array_unique($ids));

        // Map results back to requests
        $response = new BatchResponse();
        foreach ($requests as $request) {
            $id = (int) $request->getValue()['entity_id'];
            $response->addResponse($request, $dataByIds[$id] ?? null);
        }

        return $response;
    }
}
```

**Auth context:** Access customer context via `$context->getExtensionAttributes()->getIsCustomer()` and `$context->getUserId()`. Throw `GraphQlAuthorizationException` for unauthorized access.

**Mutation errors:** Throw `GraphQlInputException` for validation errors — these return user-friendly messages. Use `GraphQlNoSuchEntityException` for missing resources.

For GraphQL testing patterns, see `.claude/skills/m2-graphql-builder/references/graphql-testing.md`.

## 5. GraphQL Type Mapping

| PHP Type | GraphQL Type |
|----------|-------------|
| `string` | `String` |
| `int` | `Int` |
| `float` | `Float` |
| `bool` | `Boolean` |
| `array` | Custom type or `[Type]` |
| `null` allowed | Omit `!` (fields are nullable by default) |
| required | Append `!` (e.g., `Int!`) |

## 6. Generation Rules

Follow this sequence when generating GraphQL code:

1. **Verify the module exists** — check `registration.php`.

2. **Verify the repository exists** — the repository interface and implementation should exist for new entities. If not, tell the user to create them with `/m2-api-builder`.

3. **Create `etc/schema.graphqls`** — define types, queries, mutations, inputs, and filters.

4. **Create query resolver(s)** — single entity and list resolvers.

5. **Create mutation resolver(s)** — create, update, delete resolvers.

6. **Create cache Identity class** — for `@cache` directive on queries.

7. **Remind the user** to run post-generation commands.

## 7. Anti-Patterns

**Returning objects from resolvers.**
Resolvers must return arrays. Use `$entity->getData()` to convert. Returning a Model object causes serialization failures.

**N+1 query problem in list resolvers.**
When resolving nested fields, each item triggers a separate query. Use `BatchResolverInterface` or `DataProvider` pattern for batch loading.

**Missing `@doc` directives.**
Every type, field, query, mutation, and input should have `@doc(description: "...")` for schema introspection.

**Throwing generic exceptions.**
Use GraphQL-specific exceptions: `GraphQlInputException`, `GraphQlNoSuchEntityException`, `GraphQlAuthorizationException`, `GraphQlAuthenticationException`. Generic exceptions expose internal details.

**Missing cache identity.**
Without `@cache(cacheIdentity: "...")`, query results are not cached by Varnish/FPC. Always add an Identity class for read queries.

**Not validating input in mutations.**
Always validate `$args['input']` before processing. Throw `GraphQlInputException` for missing or invalid fields.

## 8. Post-Generation Steps

Follow `.claude/skills/_shared/post-generation.md` for: di.xml, new module enable.

**Verification:** Quick smoke test:
```bash
curl -X POST https://magento.test/graphql \
  -H "Content-Type: application/json" \
  -d '{"query":"{ {entityCamel}(entity_id: 1) { entity_id title is_active } }"}'
```
