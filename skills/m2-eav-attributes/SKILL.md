---
name: m2-eav-attributes
description: >
  Generate Magento 2 EAV attribute data patches for product, category, customer, and customer
  address entities. Use this skill whenever the user asks to create, update, or remove an EAV
  attribute, add product attributes, add customer attributes, define attribute options, assign
  attributes to attribute sets/groups, assign customer attributes to forms, or generate custom
  source models. Trigger on: "create attribute", "add attribute", "product attribute",
  "category attribute", "customer attribute", "customer address attribute", "EAV attribute",
  "attribute set", "attribute group", "attribute options", "source model", "backend model",
  "select attribute", "multiselect attribute", "boolean attribute", "dropdown attribute",
  "used_in_forms", "update attribute", "remove attribute", "delete attribute".
---

# Magento 2 EAV Attribute Generator

You are a Magento 2 EAV attribute specialist. Generate data patch files that create, update, or remove EAV attributes under existing modules in `app/code/{Vendor}/{ModuleName}/`.

Follow the coding conventions and file headers defined in `.claude/skills/_shared/conventions.md` and `.claude/skills/m2-module/SKILL.md`. Do not duplicate those conventions here.

**Prerequisites:** Module must exist (see `_shared/conventions.md`). If not, use `/m2-module` first.

## 1. Decision Tree

**Use this skill (`/m2-eav-attributes`) when you need to:**
- Create, update, or remove product, category, customer, or customer address attributes
- Define attribute options (dropdown, multiselect)
- Assign customer/customer address attributes to forms
- Generate custom source models for attribute options

**Use `/m2-db-schema` instead when you need to:**
- Create flat database tables (non-EAV)
- Write generic data patches (CMS blocks, config values, seed data)
- Define indexes, foreign keys, or table schema

**Use `/m2-admin-ui` instead when you need to:**
- Build admin grids or forms for custom entities
- Create UI components for entity management

## 2. Gather Requirements

Before generating any files, collect the following from the user.

**Required for all attribute types:**
- **Module name** — `Vendor_ModuleName` where the patch belongs
- **Entity type** — product, category, customer, or customer_address
- **Attribute code** — lowercase, underscored (e.g., `custom_warranty_period`)
- **Label** — human-readable name (e.g., "Custom Warranty Period")
- **Input type** — text, textarea, select, multiselect, boolean, date, price, etc.

**Ask if not provided (use sensible defaults):**
- **Required** — is the attribute required? (default: `false`)
- **Scope** — store, website, or global (default: global for product; N/A for customer)
- **Attribute group** — which group/tab in the admin (default: "General")
- **Sort order** — position within the group (default: `100`)
- **Default value** — if any
- **Options** — for select/multiselect inputs
- **Visible on frontend** — show on product detail/compare pages? (default: `false`)
- **Searchable/filterable** — for product attributes (default: `false`)
- **Customer forms** — for customer/customer_address: which forms to show in

## 3. Entity Types

| Entity Code | Setup Factory | Entity Type Constant | Notes |
|-------------|---------------|---------------------|-------|
| `catalog_product` | `Magento\Eav\Setup\EavSetupFactory` | `\Magento\Catalog\Model\Product::ENTITY` | Most common. Uses `EavSetup::addAttribute()` |
| `catalog_category` | `Magento\Eav\Setup\EavSetupFactory` | `\Magento\Catalog\Model\Category::ENTITY` | Same factory as product |
| `customer` | `Magento\Customer\Setup\CustomerSetupFactory` | `\Magento\Customer\Model\Customer::ENTITY` | **Different factory**. Requires form assignment |
| `customer_address` | `Magento\Customer\Setup\CustomerSetupFactory` | `'customer_address'` (string literal) | Requires form assignment |

> **CRITICAL: Customer and customer address attributes use `CustomerSetupFactory`, NOT `EavSetupFactory`.** Using the wrong factory will silently create broken attributes that don't associate with the customer entity type. This is the most common EAV mistake for customer attributes.

## 4. Type/Input Quick Rules

These are the most critical mappings — wrong combinations cause silent failures.

| Input | Backend Type | Source Model | Backend Model | Notes |
|-------|-------------|-------------|---------------|-------|
| `text` | `varchar` | — | — | Simple text |
| `textarea` | `text` | — | — | Long text |
| `boolean` | `int` | `Magento\Eav\Model\Entity\Attribute\Source\Boolean` | — | Stores 0/1 |
| `select` | `int` | `Magento\Eav\Model\Entity\Attribute\Source\Table` or custom | — | Stores option_id |
| `multiselect` | `varchar` | `Magento\Eav\Model\Entity\Attribute\Source\Table` or custom | `Magento\Eav\Model\Entity\Attribute\Backend\ArrayBackend` | Stores comma-separated IDs |
| `date` | `datetime` | — | `Magento\Eav\Model\Entity\Attribute\Backend\Datetime` | Date picker |
| `price` | `decimal` | — | `Magento\Catalog\Model\Product\Attribute\Backend\Price` | Product only |
| `media_image` | `varchar` | — | — | Product image |
| `weight` | `decimal` | — | — | Product weight |

See `references/type-input-mapping.md` for the complete mapping table with explanations.

## 5. Naming Conventions

| Concept | Convention | Example |
|---------|-----------|---------|
| Attribute code | `lowercase_underscored`, max 60 chars | `custom_warranty_period` |
| Patch class (create) | `Add{AttributeLabel}Attribute` | `AddCustomWarrantyPeriodAttribute` |
| Patch class (update) | `Update{AttributeLabel}Attribute` | `UpdateCustomWarrantyPeriodAttribute` |
| Patch class (remove) | `Remove{AttributeLabel}Attribute` | `RemoveCustomWarrantyPeriodAttribute` |
| Patch path | `Setup/Patch/Data/{ClassName}.php` | `Setup/Patch/Data/AddCustomWarrantyPeriodAttribute.php` |
| Custom source model | `Model/Attribute/Source/{Name}.php` | `Model/Attribute/Source/WarrantyType.php` |
| Custom backend model | `Model/Attribute/Backend/{Name}.php` | `Model/Attribute/Backend/CustomValidation.php` |

**Attribute code rules:**
- Must start with a letter
- Only lowercase letters, numbers, and underscores
- Maximum 60 characters (Magento DB constraint)
- Do not prefix with entity type (no `product_`, `customer_` prefix — the entity type is implicit)

## 6. Templates

### 6.1 Product or Category Attribute — Data Patch

```php
<?php
/**
 * Copyright © Monsoon Consulting. All rights reserved.
 * See LICENSE_MONSOON.txt for license details.
 */

declare(strict_types=1);

namespace {Vendor}\{ModuleName}\Setup\Patch\Data;

use Magento\Eav\Setup\EavSetup;
use Magento\Eav\Setup\EavSetupFactory;
use Magento\Framework\Setup\ModuleDataSetupInterface;
use Magento\Framework\Setup\Patch\DataPatchInterface;

final class Add{AttributeName}Attribute implements DataPatchInterface
{
    public function __construct(
        private readonly ModuleDataSetupInterface $moduleDataSetup,
        private readonly EavSetupFactory $eavSetupFactory
    ) {
    }

    public function apply(): self
    {
        /** @var EavSetup $eavSetup */
        $eavSetup = $this->eavSetupFactory->create(['setup' => $this->moduleDataSetup]);

        $eavSetup->addAttribute(
            \Magento\Catalog\Model\Product::ENTITY, // or \Magento\Catalog\Model\Category::ENTITY
            '{attribute_code}',
            [
                'type' => '{backend_type}',
                'label' => '{Attribute Label}',
                'input' => '{input_type}',
                'required' => false,
                'sort_order' => 100,
                'global' => \Magento\Eav\Model\Entity\Attribute\ScopedAttributeInterface::SCOPE_GLOBAL,
                'group' => 'General',
                'visible' => true,
                'user_defined' => true,
                'searchable' => false,
                'filterable' => false,
                'comparable' => false,
                'visible_on_front' => false,
                'used_in_product_listing' => false,
                'is_used_in_grid' => false,
                'is_filterable_in_grid' => false,
            ]
        );

        return $this;
    }

    public static function getDependencies(): array
    {
        return [];
    }

    public function getAliases(): array
    {
        return [];
    }
}
```

**For select/multiselect attributes, add the `option` and `source` keys:**
```php
                'source' => \Magento\Eav\Model\Entity\Attribute\Source\Table::class,
                // For multiselect, also add:
                // 'backend' => \Magento\Eav\Model\Entity\Attribute\Backend\ArrayBackend::class,
                'option' => [
                    'values' => [
                        'Option One',
                        'Option Two',
                        'Option Three',
                    ],
                ],
```

**For category attributes, also add:**
```php
                'visible' => true,
                'is_used_in_grid' => false,
                'is_visible_in_grid' => false,
                'is_filterable_in_grid' => false,
```
Note: Category attributes do not use `global` scope — they are always global.

### 6.2 Customer or Customer Address Attribute — Data Patch

**Critical differences from product/category:**
- Uses `CustomerSetupFactory` instead of `EavSetupFactory`
- Must assign to forms after creation, or the attribute won't appear anywhere
- No scope concept — customer attributes are always global

```php
<?php
/**
 * Copyright © Monsoon Consulting. All rights reserved.
 * See LICENSE_MONSOON.txt for license details.
 */

declare(strict_types=1);

namespace {Vendor}\{ModuleName}\Setup\Patch\Data;

use Magento\Customer\Model\Customer;
use Magento\Customer\Setup\CustomerSetup;
use Magento\Customer\Setup\CustomerSetupFactory;
use Magento\Framework\Setup\ModuleDataSetupInterface;
use Magento\Framework\Setup\Patch\DataPatchInterface;

final class Add{AttributeName}CustomerAttribute implements DataPatchInterface
{
    public function __construct(
        private readonly ModuleDataSetupInterface $moduleDataSetup,
        private readonly CustomerSetupFactory $customerSetupFactory
    ) {
    }

    public function apply(): self
    {
        /** @var CustomerSetup $customerSetup */
        $customerSetup = $this->customerSetupFactory->create(['setup' => $this->moduleDataSetup]);

        $customerSetup->addAttribute(
            Customer::ENTITY, // or 'customer_address' for address attributes
            '{attribute_code}',
            [
                'type' => '{backend_type}',
                'label' => '{Attribute Label}',
                'input' => '{input_type}',
                'required' => false,
                'sort_order' => 100,
                'position' => 100,
                'visible' => true,
                'user_defined' => true,
                'system' => false,
            ]
        );

        // --- Form assignment (REQUIRED for customer attributes) ---
        $attribute = $customerSetup->getEavConfig()
            ->getAttribute(Customer::ENTITY, '{attribute_code}');

        $attribute->setData('used_in_forms', [
            'adminhtml_customer',           // Admin customer edit form
            'customer_account_create',      // Storefront registration
            'customer_account_edit',        // Storefront account edit
            // See references/customer-attribute-forms.md for all form codes
        ]);

        $attribute->getResource()->save($attribute);

        return $this;
    }

    public static function getDependencies(): array
    {
        return [];
    }

    public function getAliases(): array
    {
        return [];
    }
}
```

### 6.3 Update or Remove Attribute — Data Patches

See `references/attribute-lifecycle.md` for update and remove attribute data patch templates. Key points:
- **Update:** Use `$eavSetup->updateAttribute()` — only include properties you want to change. Add the creation patch as a dependency in `getDependencies()`.
- **Remove:** Use `$eavSetup->removeAttribute()` — removes the attribute and all its data.
- Never modify an already-applied patch — always create a new patch class for changes.

## 7. Custom Source Model

For custom source model templates and when to use them vs `option` arrays, see `references/scope-and-source-models.md`.

## 8. Generation Rules

Follow this sequence when generating EAV attribute files:

1. **Verify the target module exists** — check that `app/code/{Vendor}/{ModuleName}/registration.php` exists. If not, instruct the user to scaffold it first with `/m2-module`.

2. **Determine the entity type** — product, category, customer, or customer_address. This dictates which factory and template to use.

3. **Validate input/type combination** — consult the type/input mapping in section 4 (and `references/type-input-mapping.md`). If the user requests an invalid combination, warn them and suggest the correct mapping.

4. **Determine if a custom source model is needed:**
   - `select` or `multiselect` with static admin-managed options → use `Source\Table` + `option` array
   - `select` or `multiselect` with computed/dynamic options → generate a custom source model
   - `boolean` → always use `Source\Boolean`

5. **Generate the data patch file** at `Setup/Patch/Data/{ClassName}.php`:
   - Use the appropriate template (6.1 for product/category, 6.2 for customer/customer_address)
   - Fill in all attribute properties based on user requirements and sensible defaults
   - For customer attributes, always include form assignment

6. **Generate custom source model** (if needed) at `Model/Attribute/Source/{Name}.php`.

7. **If updating an existing attribute**, use the update template (6.3) and add the creation patch as a dependency.

8. **If removing an attribute**, use the remove template (6.4).

9. **Check for module dependency** — if the attribute's source or backend model comes from another module, ensure that module is listed as a dependency in `etc/module.xml` `<sequence>`.

10. **Remind the user** to run post-generation commands (see section 11).

## 9. Anti-Patterns

**1. Wrong backend type for input.**
The most common EAV mistake. `select` must use `int` (it stores the option_id), `multiselect` must use `varchar` (comma-separated IDs). See the mapping table in section 4.

**2. Missing source model on select/boolean.**
Without a source model, the admin dropdown renders empty. `boolean` needs `Source\Boolean`, `select` needs `Source\Table` or a custom source.

**3. Missing backend model on multiselect.**
Without `ArrayBackend`, Magento cannot serialize/deserialize the comma-separated option IDs. The attribute will save but load incorrectly.

**4. Missing form assignment on customer attributes.**
Customer attributes created without `used_in_forms` assignment will not appear in any admin or storefront form. This is the #1 customer attribute bug. Always assign forms as shown in template 6.2.

**5. Wrong scope constants.**
Magento scope constants are counterintuitive:
- `SCOPE_STORE = 0` — most granular (per store view)
- `SCOPE_GLOBAL = 1` — least granular (same value everywhere)
- `SCOPE_WEBSITE = 2` — per website

Do NOT confuse `SCOPE_GLOBAL` with `SCOPE_STORE`. "Global" means the value is the same across all stores, not that it has the widest scope options.

**6. Using `EavSetupFactory` for customer attributes.**
Customer attributes require `CustomerSetupFactory`. Using `EavSetupFactory` creates a broken attribute without proper customer entity type association.

**7. Using `ObjectManager` instead of DI.**
Never use `ObjectManager::getInstance()` in patches. All dependencies must be constructor-injected.

**8. Modifying an already-applied patch.**
Magento tracks applied patches in the `patch_list` table. Once a patch has run, modifying its `apply()` method has no effect. Always create a new patch for changes.

**9. Missing `user_defined => true` on custom attributes.**
System attributes (`user_defined => false`) cannot be deleted from the admin. Custom attributes should always set `user_defined => true`.

**10. Forgetting `position` on customer attributes.**
Customer attributes need both `sort_order` and `position` to render in the correct order in forms. Omitting `position` causes unpredictable ordering.

## 10. Scope Constants Reference

Scope constants are **counterintuitive**: `SCOPE_STORE = 0` (most granular), `SCOPE_GLOBAL = 1` (least granular), `SCOPE_WEBSITE = 2`. See `references/scope-and-source-models.md` for the full table. Scope only applies to product attributes.

## 11. Post-Generation Steps

After generating attribute patch files, remind the user to run:

```bash
bin/magento setup:upgrade       # Runs pending data patches (creates the attribute)
bin/magento cache:flush         # Clear cached EAV configuration
```

If the module was not yet enabled:
```bash
bin/magento module:enable {Vendor}_{ModuleName}
bin/magento setup:upgrade
bin/magento cache:flush
```

**To verify the attribute was created:**
```bash
# Check in database
bin/magento dev:query:log     # Or query eav_attribute table directly

# Check in admin
# Products > Attributes > Manage Attributes — search for the attribute code
# Customers > Attributes — for customer attributes
```

If the attribute does not appear, check:
1. The patch ran: `SELECT * FROM patch_list WHERE patch_name LIKE '%{PatchClassName}%'`
2. The attribute exists: `SELECT * FROM eav_attribute WHERE attribute_code = '{code}'`
3. For customer attributes: `SELECT * FROM customer_form_attribute WHERE attribute_id = {id}`
