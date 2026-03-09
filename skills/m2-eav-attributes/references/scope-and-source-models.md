# Scope Constants & Custom Source Model Reference

> Companion file for m2-eav-attributes. Referenced from SKILL.md.

## Scope Constants

These values are **counterintuitive** — memorize them or reference this table:

| Constant | Value | Meaning | Use When |
|----------|-------|---------|----------|
| `ScopedAttributeInterface::SCOPE_STORE` | `0` | Per store view | Translatable labels, store-specific values |
| `ScopedAttributeInterface::SCOPE_GLOBAL` | `1` | Same everywhere | SKU-like identifiers, non-translatable data |
| `ScopedAttributeInterface::SCOPE_WEBSITE` | `2` | Per website | Prices (when not using catalog price scope), website-specific settings |

**Full class**: `Magento\Eav\Model\Entity\Attribute\ScopedAttributeInterface`

Note: Scope only applies to `catalog_product` attributes. Category, customer, and customer address attributes do not support scoping — they are always effectively global.

## Custom Source Model Template

Generate when the user needs a dropdown/multiselect with options that are not simple static values managed via `option` array, or when options need programmatic logic.

```php
<?php
/**
 * Copyright © Monsoon Consulting. All rights reserved.
 * See LICENSE_MONSOON.txt for license details.
 */

declare(strict_types=1);

namespace {Vendor}\{ModuleName}\Model\Attribute\Source;

use Magento\Eav\Model\Entity\Attribute\Source\AbstractSource;

final class {SourceName} extends AbstractSource
{
    /**
     * @return array<int, array{value: string, label: string}>
     */
    public function getAllOptions(): array
    {
        if ($this->_options === null) {
            $this->_options = [
                ['value' => '', 'label' => __('-- Please Select --')],
                ['value' => 'option_1', 'label' => __('Option One')],
                ['value' => 'option_2', 'label' => __('Option Two')],
                ['value' => 'option_3', 'label' => __('Option Three')],
            ];
        }

        return $this->_options;
    }
}
```

**When to use a custom source model vs `option` array:**
- Use `option` array (with `Source\Table`) when options are simple, admin-managed labels stored in `eav_attribute_option` / `eav_attribute_option_value` tables
- Use a custom source model when options are computed, come from another entity, or use non-integer values

**In the attribute definition, reference the custom source:**
```php
'source' => \{Vendor}\{ModuleName}\Model\Attribute\Source\{SourceName}::class,
```
