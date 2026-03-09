# Catalog Attribute Properties Reference

Complete reference of properties specific to `catalog_product` and `catalog_category` attributes, beyond the basic EAV properties.

These properties are passed in the attribute definition array to `EavSetup::addAttribute()`.

## Search & Filter Properties (Product Only)

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `searchable` | `bool` | `false` | Include in catalog search results |
| `filterable` | `int` | `0` | Show in layered navigation: `0` = no, `1` = filterable with results, `2` = filterable without results |
| `filterable_in_search` | `bool` | `false` | Show in layered navigation on search results page |
| `comparable` | `bool` | `false` | Allow in product comparison |
| `visible_in_advanced_search` | `bool` | `false` | Show in advanced search form |
| `is_used_for_promo_rules` | `bool` | `false` | Available as condition in cart/catalog price rules |

**Note:** `filterable` only works on `select`, `multiselect`, `price`, and `boolean` input types. Setting it on `text` or `textarea` has no effect.

## Display Properties

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `visible_on_front` | `bool` | `false` | Show on product detail page ("More Information" tab) |
| `used_in_product_listing` | `bool` | `false` | Load attribute value in product listings (category pages). Required if value is used in templates on listing pages. |
| `used_for_sort_by` | `bool` | `false` | Available as "Sort By" option on category pages |
| `visible` | `bool` | `true` | Show on product edit form in admin. Set `false` for programmatic-only attributes. |

**Performance note:** `used_in_product_listing => true` adds the attribute to the flat catalog (if enabled) and to collection queries on category pages. Only enable when the value is actually needed in listings.

## Admin Grid Properties

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `is_used_in_grid` | `bool` | `false` | Available in the admin product/category grid |
| `is_visible_in_grid` | `bool` | `false` | Shown by default in the grid (vs. available via column chooser) |
| `is_filterable_in_grid` | `bool` | `false` | Can be used as a filter in the admin grid |

These three are independent: you can make an attribute filterable in the grid without showing it as a column.

## WYSIWYG Properties

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `wysiwyg_enabled` | `bool` | `false` | Enable WYSIWYG editor for this attribute. Only works with `input => 'texteditor'` or `input => 'textarea'`. |
| `is_html_allowed_on_front` | `bool` | `false` | Allow HTML rendering on frontend. Set `true` when `wysiwyg_enabled` is `true`, otherwise HTML is escaped. |

**Always set both together:** If you enable `wysiwyg_enabled` without `is_html_allowed_on_front`, the admin will show a WYSIWYG editor but the frontend will escape all HTML tags.

## Product-Specific Properties

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `apply_to` | `string` | `''` (all) | Comma-separated product types: `simple`, `configurable`, `grouped`, `bundle`, `virtual`, `downloadable`. Empty = all types. |
| `is_configurable` | `bool` | `false` | Can be used to create configurable product variations. Only works with `select` input. |

**`apply_to` examples:**
```php
'apply_to' => 'simple,configurable'  // Only simple and configurable products
'apply_to' => ''                      // All product types (default)
```

## Common Property Combinations

### Simple text attribute (product)
```php
[
    'type' => 'varchar',
    'input' => 'text',
    'visible_on_front' => false,
    'used_in_product_listing' => false,
    'searchable' => false,
    'filterable' => 0,
]
```

### Filterable dropdown (product, for layered navigation)
```php
[
    'type' => 'int',
    'input' => 'select',
    'source' => \Magento\Eav\Model\Entity\Attribute\Source\Table::class,
    'filterable' => 1,
    'is_used_for_promo_rules' => true,
    'visible_on_front' => true,
    'is_used_in_grid' => true,
    'is_filterable_in_grid' => true,
]
```

### WYSIWYG rich text (product or category)
```php
[
    'type' => 'text',
    'input' => 'texteditor',
    'wysiwyg_enabled' => true,
    'is_html_allowed_on_front' => true,
    'visible_on_front' => true,
]
```

### Attribute for product listing pages
```php
[
    'type' => 'varchar',
    'input' => 'text',
    'used_in_product_listing' => true,
    'used_for_sort_by' => true,
    'is_used_in_grid' => true,
    'is_visible_in_grid' => true,
]
```
