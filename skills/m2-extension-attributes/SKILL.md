---
name: m2-extension-attributes
description: >
  Generate Magento 2 extension attributes for adding custom data to existing
  entities like orders, products, customers, and carts. Use this skill whenever
  the user asks to add custom fields to Magento entities, extend API responses,
  or add data to existing service contracts.
  Trigger on: "extension attribute", "extension_attributes.xml", "add field to order",
  "add field to product API", "add custom data to entity", "extend API response",
  "custom order field", "custom quote field", "join directive", "extra field on entity",
  "add attribute to API", "getExtensionAttributes", "order comment",
  "custom shipping data", "add data to quote", "hydration", "hydrate",
  "afterGet", "afterGetList", "quote to order", "fieldset",
  "augment API", "API field",
  "custom product field", "API response field", "add data to entity".
---

# Magento 2 Extension Attributes Generator

You are a Magento 2 extension attributes specialist. Generate extension attribute declarations, hydration plugins, and persistence logic under existing modules in `app/code/{Vendor}/{ModuleName}/`.

Follow the coding conventions and file headers defined in `.claude/skills/_shared/conventions.md` and `.claude/skills/m2-module/SKILL.md`. Do not duplicate those conventions here.

**Prerequisites:** Module must exist (see `_shared/conventions.md`). If not, use `/m2-module` first.

## 1. Decision Tree

**Use extension attributes when:**
- Adding data to entities owned by other modules (Order, Product, Customer, Quote)
- Exposing custom data via REST/GraphQL on existing entities
- The data comes from a custom column on the entity table or a related table
- You need the field available in API responses without modifying core code

**Use EAV attributes instead when:**
- The entity is EAV-based AND you need admin UI / storefront rendering (use `/m2-eav-attributes`)
- You need the attribute in product grid filters or layered navigation

**Use a plugin instead when:**
- You need to modify method behavior, not add data — for general plugin patterns and concepts, see `/m2-plugin`

**Boundary:** This skill EXTENDS existing entities with custom data. Use `/m2-api-builder` when you need to CREATE entirely new API endpoints.

## 2. Gather Requirements

Before generating any files, collect the following from the user.

**Required (ask if not provided):**
- **Module name** — `Vendor_ModuleName` where the extension attribute will be declared
- **Target entity interface** — fully qualified (e.g., `Magento\Sales\Api\Data\OrderInterface`)
- **Attribute name** — snake_case (e.g., `custom_delivery_date`)
- **Attribute type** — `string`, `int`, `float`, `boolean`, or FQN for complex types (e.g., `Vendor\Module\Api\Data\CustomInterface` or `string[]` for arrays)

**Optional (use defaults if not specified):**
- **Data source** — same-table column (default), join from another table, or computed at runtime
- **Writable via API?** — default: yes (adds persistence plugin)
- **ACL restrictions?** — default: none (inherits parent entity ACL)
- **Areas** — default: global (both REST API and frontend)

## 3. Naming Conventions

| Concept | Convention | Example |
|---------|-----------|---------|
| Extension attribute name | snake_case | `custom_delivery_date` |
| extension_attributes.xml path | `etc/extension_attributes.xml` | |
| Plugin class (hydration) | `Plugin\Add{AttributePascal}To{EntityShort}` | `Plugin\AddCustomDeliveryDateToOrder` |
| Plugin di.xml target | Repository interface | `Magento\Sales\Api\OrderRepositoryInterface` |
| di.xml plugin name | `{vendor}_{modulename}_add_{attribute_code}` | `acme_delivery_add_custom_delivery_date` |

## 4. Common Target Entities

| Entity | Interface | Repository Interface |
|--------|-----------|---------------------|
| Order | `Magento\Sales\Api\Data\OrderInterface` | `Magento\Sales\Api\OrderRepositoryInterface` |
| Order Item | `Magento\Sales\Api\Data\OrderItemInterface` | (use Order repo plugin) |
| Product | `Magento\Catalog\Api\Data\ProductInterface` | `Magento\Catalog\Api\ProductRepositoryInterface` |
| Customer | `Magento\Customer\Api\Data\CustomerInterface` | `Magento\Customer\Api\CustomerRepositoryInterface` |
| Cart/Quote | `Magento\Quote\Api\Data\CartInterface` | `Magento\Quote\Api\CartRepositoryInterface` |
| Cart Item | `Magento\Quote\Api\Data\CartItemInterface` | (use Cart repo plugin) |
| Invoice | `Magento\Sales\Api\Data\InvoiceInterface` | `Magento\Sales\Api\InvoiceRepositoryInterface` |
| Shipment | `Magento\Sales\Api\Data\ShipmentInterface` | `Magento\Sales\Api\ShipmentRepositoryInterface` |
| Credit Memo | `Magento\Sales\Api\Data\CreditmemoInterface` | `Magento\Sales\Api\CreditmemoRepositoryInterface` |

## 5. Templates

### 5.1 extension_attributes.xml — Scalar Attribute

```xml
<?xml version="1.0"?>
<!--
/**
 * Copyright © Monsoon Consulting. All rights reserved.
 * See LICENSE_MONSOON.txt for license details.
 */
-->
<config xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
        xsi:noNamespaceSchemaLocation="urn:magento:framework:Api/etc/extension_attributes.xsd">
    <extension_attributes for="{TargetEntityInterface}">
        <attribute code="{attribute_code}" type="{type}"/>
    </extension_attributes>
</config>
```

### 5.2 extension_attributes.xml — Complex or Array Type

Same structure but the type is a fully qualified interface name or an array type:

```xml
<extension_attributes for="{TargetEntityInterface}">
    <attribute code="{attribute_code}" type="{Vendor}\{ModuleName}\Api\Data\{CustomType}Interface"/>
</extension_attributes>
```

For arrays, use the `[]` suffix: `type="{Vendor}\{ModuleName}\Api\Data\{CustomType}Interface[]"` or `type="string[]"`.

### 5.3 extension_attributes.xml — With Join Directive

Auto-populates the attribute from a database join when using repository `getList()` with SearchCriteria:

```xml
<?xml version="1.0"?>
<!-- Standard XML header — see _shared/conventions.md -->
<config xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
        xsi:noNamespaceSchemaLocation="urn:magento:framework:Api/etc/extension_attributes.xsd">
    <extension_attributes for="{TargetEntityInterface}">
        <attribute code="{attribute_code}" type="string">
            <join reference_table="{table_name}"
                  reference_field="{fk_column}"
                  join_on_field="entity_id">
                <field>{column_to_select}</field>
            </join>
        </attribute>
    </extension_attributes>
</config>
```

**Important:** Join directives ONLY work when the entity is loaded via repository `getList()` with SearchCriteria. They do NOT work with `getById()`. For `getById()`, you must also add a plugin.

### 5.4 extension_attributes.xml — With ACL Restriction

Restrict attribute visibility based on admin ACL:

```xml
<extension_attributes for="{TargetEntityInterface}">
    <attribute code="{attribute_code}" type="{type}">
        <resources>
            <resource ref="{Vendor}_{ModuleName}::{acl_resource}"/>
        </resources>
    </attribute>
</extension_attributes>
```

### 5.5 Plugin for Hydration — afterGet (Single Entity)

```php
<?php
/**
 * Copyright © Monsoon Consulting. All rights reserved.
 * See LICENSE_MONSOON.txt for license details.
 */

declare(strict_types=1);

namespace {Vendor}\{ModuleName}\Plugin;

use {TargetEntityInterface};
use {TargetRepositoryInterface};

final class Add{AttributePascal}To{EntityShort}
{
    public function __construct(
        private readonly \{Vendor}\{ModuleName}\Model\{DataSource} $dataSource
    ) {
    }

    public function afterGet(
        {TargetRepositoryInterface} $subject,
        {TargetEntityInterface} $entity
    ): {TargetEntityInterface} {
        $this->addExtensionAttribute($entity);

        return $entity;
    }

    public function afterGetList(
        {TargetRepositoryInterface} $subject,
        \{SearchResultsInterface} $searchResults
    ): \{SearchResultsInterface} {
        foreach ($searchResults->getItems() as $entity) {
            $this->addExtensionAttribute($entity);
        }

        return $searchResults;
    }

    private function addExtensionAttribute({TargetEntityInterface} $entity): void
    {
        $extensionAttributes = $entity->getExtensionAttributes();
        $value = $this->dataSource->get{AttributePascal}((int) $entity->getEntityId());
        $extensionAttributes->set{AttributePascal}($value);
        $entity->setExtensionAttributes($extensionAttributes);
    }
}
```

**Key points:**
- Always implement BOTH `afterGet` and `afterGetList` in the same plugin class
- Extract the shared logic into a private `addExtensionAttribute()` method
- Always call `$entity->getExtensionAttributes()` — Magento auto-generates the class and this method initializes it. Never create the extension attributes object manually.

**Method name variations:** Some repositories use `getById()` instead of `get()`. Check the actual repository interface method names. For example, `OrderRepositoryInterface` has `get()`, while `ProductRepositoryInterface` has `getById()`. Name your plugin method accordingly: `afterGet` or `afterGetById`.

### 5.6 Plugin for Persistence — afterSave

Add this method to the same plugin class when the attribute is writable via API:

```php
    public function afterSave(
        {TargetRepositoryInterface} $subject,
        {TargetEntityInterface} $entity
    ): {TargetEntityInterface} {
        $extensionAttributes = $entity->getExtensionAttributes();
        if ($extensionAttributes !== null && $extensionAttributes->get{AttributePascal}() !== null) {
            $this->dataSource->save{AttributePascal}(
                (int) $entity->getEntityId(),
                $extensionAttributes->get{AttributePascal}()
            );
        }

        return $entity;
    }
```

### 5.7 Complete Plugin — Hydration + Persistence Combined

When the attribute is both readable and writable, the complete plugin class looks like this:

```php
<?php
// Standard file header — see _shared/conventions.md
declare(strict_types=1);

namespace {Vendor}\{ModuleName}\Plugin;

use {TargetEntityInterface};
use {TargetRepositoryInterface};
use {SearchResultsInterface};

final class Add{AttributePascal}To{EntityShort}
{
    public function __construct(
        private readonly \{Vendor}\{ModuleName}\Model\{DataSource} $dataSource
    ) {
    }

    public function afterGet(
        {TargetRepositoryInterface} $subject,
        {TargetEntityInterface} $entity
    ): {TargetEntityInterface} {
        $this->addExtensionAttribute($entity);

        return $entity;
    }

    public function afterGetList(
        {TargetRepositoryInterface} $subject,
        {SearchResultsInterface} $searchResults
    ): {SearchResultsInterface} {
        foreach ($searchResults->getItems() as $entity) {
            $this->addExtensionAttribute($entity);
        }

        return $searchResults;
    }

    public function afterSave(
        {TargetRepositoryInterface} $subject,
        {TargetEntityInterface} $entity
    ): {TargetEntityInterface} {
        $extensionAttributes = $entity->getExtensionAttributes();
        if ($extensionAttributes !== null && $extensionAttributes->get{AttributePascal}() !== null) {
            $this->dataSource->save{AttributePascal}(
                (int) $entity->getEntityId(),
                $extensionAttributes->get{AttributePascal}()
            );
        }

        return $entity;
    }

    private function addExtensionAttribute({TargetEntityInterface} $entity): void
    {
        $extensionAttributes = $entity->getExtensionAttributes();
        $value = $this->dataSource->get{AttributePascal}((int) $entity->getEntityId());
        $extensionAttributes->set{AttributePascal}($value);
        $entity->setExtensionAttributes($extensionAttributes);
    }
}
```

### 5.8 di.xml — Plugin Registration

```xml
<?xml version="1.0"?>
<!-- Standard XML header — see _shared/conventions.md -->
<config xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
        xsi:noNamespaceSchemaLocation="urn:magento:framework:ObjectManager/etc/config.xsd">
    <type name="{TargetRepositoryInterface}">
        <plugin name="{vendor}_{modulename}_add_{attribute_code}"
                type="{Vendor}\{ModuleName}\Plugin\Add{AttributePascal}To{EntityShort}"/>
    </type>
</config>
```

## 6. Generation Rules

Follow this sequence when generating extension attributes:

1. **Verify the target module exists** — check that `app/code/{Vendor}/{ModuleName}/registration.php` exists. If not, instruct the user to scaffold it first with `/m2-module`.

2. **Create or update `etc/extension_attributes.xml`** — if the file exists, append the new `<attribute>` inside the existing `<extension_attributes>` element (or add a new `<extension_attributes for="...">` block). If the file does not exist, create it with the full XML structure.

3. **Determine data source strategy:**
   - **Same-table column:** Add a join directive in extension_attributes.xml for `getList()`, PLUS a plugin with `afterGet` for `getById()`.
   - **Different table or computed:** Create a plugin class with both `afterGet` and `afterGetList` for hydration. No join directive.

4. **If writable via API:** Add `afterSave` to the plugin class for persistence.

5. **Register the plugin in di.xml** — if `etc/di.xml` exists, append the `<type>` block. If not, create the file.

6. **If a join directive references a custom table:** Ensure `db_schema.xml` defines that table (use `/m2-db-schema` if needed).

7. **Remind the user** to run post-generation commands (see section 8).

## 7. Anti-Patterns

**Forgetting `afterGetList`.**
Adding `afterGet` but not `afterGetList` means extension attributes are missing from search/list API calls. Always implement both in the same plugin class.

**Relying solely on join directives.**
Join directives only work with `getList()` + SearchCriteria, not `getById()`. Always add a plugin for `afterGet` as well.

**Not calling `getExtensionAttributes()`.**
Always call `$entity->getExtensionAttributes()` to obtain the extension attributes object. Magento auto-generates the extension attributes class, and this method initializes it. Never instantiate the extension attributes object manually with `new` or the ObjectManager.

**Modifying core `extension_attributes.xml`.**
Always add your own `extension_attributes.xml` in your module's `etc/` directory. Magento merges all `extension_attributes.xml` files automatically.

**Using extension attributes when EAV attributes are more appropriate.**
If you need the attribute to appear in admin forms, product grids, or layered navigation, use EAV attributes via `/m2-eav-attributes`. Extension attributes are for API/programmatic data exposure.

**Missing null checks in `afterSave`.**
Always check that both `getExtensionAttributes()` and the specific getter are not null before persisting. The extension attributes object may not be set if the entity was saved without API input.

**Circular plugin references.**
Do not read extension attributes inside the same plugin that sets them. This can cause infinite loops if the getter triggers the repository load again.

## 7.1 Quote-to-Order Data Transfer

To transfer extension attribute data from quote to order during checkout, use `fieldset.xml`:

```xml
<!-- etc/fieldset.xml -->
<?xml version="1.0"?>
<config xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
        xsi:noNamespaceSchemaLocation="urn:magento:framework:DataObject/etc/fieldset.xsd">
    <scope id="global">
        <fieldset id="sales_convert_quote">
            <field name="{attribute_code}">
                <aspect name="to_order"/>
            </field>
        </fieldset>
    </scope>
</config>
```

This copies the column value from the `quote` table to the `sales_order` table during order placement. The column must exist on both tables (add via `db_schema.xml`).

**GraphQL note:** Extension attributes are REST-only. For GraphQL, you need a custom resolver to expose the same data. See `/m2-graphql-builder`.

## 8. Post-Generation

After generating the extension attribute files, remind the user to run:

```bash
bin/magento setup:di:compile    # Required — generates extension attributes interfaces
bin/magento cache:flush         # Clear cached configuration
```

Generated interfaces appear in `generated/code/` — Magento auto-generates getter/setter methods on the `ExtensionInterface` based on your `extension_attributes.xml` declarations.

To verify the attribute appears in API responses:

```bash
# REST API test (adjust endpoint for target entity)
curl -s -H "Authorization: Bearer <token>" \
  https://your-store.test/rest/V1/orders/1 | python3 -m json.tool | grep extension_attributes
```
