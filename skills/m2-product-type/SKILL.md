---
name: m2-product-type
description: >
  Generate Magento 2 custom product types including product_types.xml registration,
  type model extending AbstractType, price model, composite and non-composite types,
  and type-specific options. Use this skill when creating entirely new product types.
  Trigger on: "product type", "product_types.xml", "custom product type", "AbstractType",
  "TypeInterface", "product type model", "price model", "isComposite", "isSalable",
  "new product type", "virtual product type", "custom type".
---

# Magento 2 Custom Product Type Generator

You are a Magento 2 product type specialist. Generate custom product types including type models, price models, and XML registration under existing modules in `app/code/{Vendor}/{ModuleName}/`.

Follow the coding conventions and file headers defined in `.claude/skills/_shared/conventions.md` and `.claude/skills/m2-module/SKILL.md`. Do not duplicate those conventions here.

**Prerequisites:** Module must exist (see `_shared/conventions.md`). If not, use `/m2-module` first.

## 1. Decision Tree

**Use this skill when:**
- Creating an entirely new product type (e.g., subscription, rental, digital service, membership)
- The new type requires unique add-to-cart behavior, price calculation, or salability logic
- Products need fundamentally different handling from simple/configurable/virtual/bundle types

**Use `/m2-eav-attributes` instead when:**
- Adding attributes to existing product types (e.g., a "rental_duration" attribute on simple products)
- Distinguishing products within an existing type via attribute values

**Use `/m2-plugin` instead when:**
- Modifying behavior of an existing product type (e.g., changing how bundle price calculates)
- Intercepting add-to-cart, salability checks, or price calculation on existing types

**Use `/m2-extension-attributes` instead when:**
- Adding custom data to product API responses without changing the product type itself

## 2. Gather Requirements

Before generating any files, collect the following from the user.

**Required (ask if not provided):**
- **Module name** -- `Vendor_ModuleName`
- **Product type code** -- lowercase identifier (e.g., `subscription`, `rental`)
- **Product type label** -- display name (e.g., "Subscription", "Rental")
- **Composite** -- yes/no (does this type manage child products?)

**Optional (use defaults if not specified):**
- **Custom price logic** -- default: inherit standard pricing
- **Salability rules** -- default: inherit from `AbstractType`
- **Virtual** -- default: `false` (physical product requiring shipment)
- **Custom options support** -- default: inherit from `AbstractType`

## 3. Naming Conventions

| Concept | Convention | Example |
|---------|-----------|---------|
| Type code | lowercase, no vendor prefix | `subscription` |
| Type model class | `Model\Product\Type\{TypeName}` | `Model\Product\Type\Subscription` |
| Price model class | `Model\Product\Price` | `Model\Product\Price` |
| Type constant | `TYPE_CODE` in type model | `public const TYPE_CODE = 'subscription';` |
| product_types.xml | `etc/product_types.xml` | -- |
| XML type name | same as type code | `name="subscription"` |

When a module defines multiple product types (rare), use distinct price models: `Model\Product\Price\{TypeName}.php`.

## 4. Templates

### 4.1 product_types.xml -- `etc/product_types.xml`

```xml
<?xml version="1.0"?>
<!--
/**
 * Copyright (C) Monsoon Consulting. All rights reserved.
 * See LICENSE_MONSOON.txt for license details.
 */
-->
<config xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
        xsi:noNamespaceSchemaLocation="urn:magento:module:Magento_Catalog:etc/product_types.xsd">
    <type name="{type_code}"
          label="{Type Label}"
          modelInstance="{Vendor}\{ModuleName}\Model\Product\Type\{TypeName}"
          composite="false"
          indexPriority="60"
          sortOrder="80">
        <priceModel instance="{Vendor}\{ModuleName}\Model\Product\Price"/>
    </type>
</config>
```

**Attributes:**
- `name` -- unique type code; appears in `catalog_product_entity.type_id`
- `label` -- shown in the admin product creation type selector
- `modelInstance` -- fully qualified class extending `AbstractType`
- `composite` -- `"true"` if this type manages child products (like bundle/grouped)
- `indexPriority` -- determines indexing order; lower = indexed first (simple=10, configurable=30, bundle=50)
- `sortOrder` -- position in the product type dropdown

### 4.2 Type Model -- `Model/Product/Type/{TypeName}.php`

```php
<?php
/**
 * Copyright (C) Monsoon Consulting. All rights reserved.
 * See LICENSE_MONSOON.txt for license details.
 */

declare(strict_types=1);

namespace {Vendor}\{ModuleName}\Model\Product\Type;

use Magento\Catalog\Model\Product;
use Magento\Catalog\Model\Product\Type\AbstractType;
use Magento\Framework\DataObject;

class {TypeName} extends AbstractType
{
    public const TYPE_CODE = '{type_code}';

    /**
     * Clean up type-specific data when product is deleted.
     */
    public function deleteTypeSpecificData(Product $product): void
    {
        // Remove data from custom tables, linked resources, etc.
    }

    /**
     * Whether this product type produces a physical shipment.
     * Return true for digital/service products that need no shipping.
     */
    public function isVirtual($product): bool
    {
        return false;
    }

    /**
     * Custom salability checks (license validity, date range, stock rules).
     */
    public function isSalable($product): bool
    {
        return parent::isSalable($product);
    }

    /**
     * Prepare product before adding to cart.
     *
     * @return array|string Array of products to add, or error message string
     */
    public function prepareForCart(DataObject $buyRequest, $product): array|string
    {
        $result = parent::prepareForCart($buyRequest, $product);
        if (is_string($result)) {
            return $result;
        }
        // Validate type-specific buy request parameters here
        return $result;
    }

    /**
     * Validate product buy state before purchase.
     */
    public function checkProductBuyState($product): self
    {
        parent::checkProductBuyState($product);
        // Add type-specific validation
        return $this;
    }
}
```

**Note:** Cannot be `final` -- must extend `AbstractType` and Magento's type pool expects this inheritance chain. The interceptor generator also needs a non-final class to create proxies.

### 4.3 Price Model -- `Model/Product/Price.php`

```php
<?php
// Standard file header -- see _shared/conventions.md
declare(strict_types=1);

namespace {Vendor}\{ModuleName}\Model\Product;

use Magento\Catalog\Model\Product;
use Magento\Catalog\Model\Product\Type\Price as BasePrice;

class Price extends BasePrice
{
    public function getFinalPrice($qty, $product): float
    {
        $finalPrice = parent::getFinalPrice($qty, $product);
        // Custom price logic: time-based, quantity-based, or dynamic pricing
        return (float) $finalPrice;
    }
}
```

**Note:** Cannot be `final` -- must extend `BasePrice` for the Magento pricing pipeline. The price model is instantiated by the type pool based on `product_types.xml` configuration.

### 4.4 di.xml -- Type Pool Registration (Advanced)

For most custom product types, `product_types.xml` is sufficient. Use `di.xml` only for composite types that need link type registration:

```xml
<?xml version="1.0"?>
<!-- Standard XML header -- see _shared/conventions.md -->
<config xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
        xsi:noNamespaceSchemaLocation="urn:magento:framework:ObjectManager/etc/config.xsd">
    <type name="Magento\Catalog\Model\Product\Link">
        <arguments>
            <argument name="linkTypes" xsi:type="array">
                <item name="{type_code}" xsi:type="const">{Vendor}\{ModuleName}\Model\Product\Link::LINK_TYPE_{TYPE_CODE}</item>
            </argument>
        </arguments>
    </type>
</config>
```

### 4.5 Allowed Selection Types (Composite Only)

For composite types, restrict which child product types are allowed via `allowedSelectionTypes` in `product_types.xml`:

```xml
<type name="{type_code}" label="{Type Label}"
      modelInstance="{Vendor}\{ModuleName}\Model\Product\Type\{TypeName}"
      composite="true" indexPriority="60" sortOrder="80">
    <priceModel instance="{Vendor}\{ModuleName}\Model\Product\Price"/>
    <allowedSelectionTypes>
        <type name="simple"/>
        <type name="virtual"/>
    </allowedSelectionTypes>
</type>
```

## 5. Composite Product Types

Set `composite="true"` in `product_types.xml` when the product type manages child products (like bundle or grouped products).

**Additional methods to override for composite types:**

```php
class {TypeName} extends AbstractType
{
    public const TYPE_CODE = '{type_code}';

    /**
     * Composite products manage child items.
     */
    public function isComposite($product): bool
    {
        return true;
    }

    /**
     * Return child products that should appear as line items.
     *
     * @return array
     */
    public function getAssociatedProducts($product): array
    {
        // Load and return child/linked products
        return [];
    }

    public function getWeight($product): float
    {
        // Calculate from child products or return own weight
        $weight = 0.0;
        foreach ($this->getAssociatedProducts($product) as $child) {
            $weight += (float) $child->getWeight();
        }
        return $weight;
    }

    public function deleteTypeSpecificData(Product $product): void
    {
        // Remove child product links/associations
    }
}
```

**Composite types additionally require:** a custom link table (use `/m2-db-schema`), link model for parent-child relationships, admin UI modifications to manage children, and a price model that aggregates child prices.

## 6. Generation Rules

1. **Verify the module exists** -- check `app/code/{Vendor}/{ModuleName}/registration.php`. If not, use `/m2-module` first.
2. **Verify module dependency** -- ensure `Magento_Catalog` is in `etc/module.xml` `<sequence>`. Add it if missing.
3. **Create `etc/product_types.xml`** -- register the type. If file exists, merge the new `<type>` inside `<config>`.
4. **Create Type Model** -- `Model/Product/Type/{TypeName}.php` extending `AbstractType` with `deleteTypeSpecificData`, `isVirtual`, `isSalable`.
5. **Create Price Model** -- `Model/Product/Price.php` extending `BasePrice`. Override `getFinalPrice` if needed.
6. **For composite types** -- additionally implement `isComposite`, `getAssociatedProducts`, and link infrastructure.
7. **Remind the user** to run post-generation commands (see section 8).

## 7. Anti-Patterns

**Creating a new product type when an EAV attribute suffices.**
If the only difference is data (not behavior), add an attribute to an existing type with `/m2-eav-attributes` instead of a whole new type. New types add significant complexity.

**Forgetting the admin product edit form.**
A new type appears in the "Product Type" dropdown, but the admin form may not show the right attribute groups. You may need UI component customization (`Catalog/view/adminhtml/ui_component/product_form.xml` modifier) to show/hide fields for the new type.

**Hardcoding prices in the type model.**
Always use the price model pipeline. The type model should not contain price calculation logic. Override `getFinalPrice` in the price model instead.

**Missing `deleteTypeSpecificData` implementation.**
When a product of this type is deleted, orphaned data remains in custom tables. Always clean up type-specific resources (link tables, custom option tables, external references).

**Not handling `prepareForCart` properly.**
If your type requires specific buy request parameters (like a subscription period or rental dates), validate them in `prepareForCart`. Return a descriptive error string on validation failure -- this message is shown to the customer.

**Ignoring stock/inventory integration.**
Custom types must work with Magento's inventory system. Non-standard stock behavior (unlimited digital goods, shared pools) requires plugins on `StockStateInterface` or MSI source items.

**Skipping indexing considerations.**
New product types must be handled by the price and stock indexers. Test `bin/magento indexer:reindex` with your type. Set `indexPriority` appropriately relative to existing types.

## 8. Post-Generation Steps

Follow `.claude/skills/_shared/post-generation.md` for: di.xml, new module enable.

```bash
bin/magento module:enable {Vendor}_{ModuleName}   # If module not yet enabled
bin/magento setup:upgrade
bin/magento setup:di:compile
bin/magento indexer:reindex catalog_product_price  # Rebuild price index for new type
bin/magento cache:flush
```

**Verification:**
1. Navigate to **Catalog > Products > Add Product** -- the new type should appear in the product type selector dropdown.
2. Create a test product with the new type and verify it saves correctly.
3. Check that the product appears on the storefront (category listing and product detail page).
4. Test add-to-cart and checkout flow to confirm salability and pricing work as expected.
5. Run `bin/magento indexer:reindex` and confirm no errors for the new type.
