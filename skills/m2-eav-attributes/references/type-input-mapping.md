# EAV Type/Input Mapping Reference

Complete mapping of every `input` type to its required `type` (backend storage type), `source` model, and `backend` model.

Getting these wrong is the #1 cause of broken EAV attributes. When in doubt, consult this table.

## Complete Mapping Table

| Input | Type (backend) | Source Model | Backend Model | Notes |
|-------|---------------|-------------|---------------|-------|
| `text` | `varchar` | — | — | Simple single-line text input. Stored as VARCHAR(255). |
| `textarea` | `text` | — | — | Multi-line text. Stored as TEXT. No WYSIWYG. |
| `texteditor` | `text` | — | — | WYSIWYG editor. Set `wysiwyg_enabled => true` and `is_html_allowed_on_front => true`. |
| `date` | `datetime` | — | `Magento\Eav\Model\Entity\Attribute\Backend\Datetime` | Date picker in admin. Backend model handles date format conversion. Without it, dates may save in wrong format. |
| `boolean` | `int` | `Magento\Eav\Model\Entity\Attribute\Source\Boolean` | — | Yes/No dropdown. Stores `0` or `1` as integer. Source model provides the Yes/No labels. |
| `select` | `int` | `Magento\Eav\Model\Entity\Attribute\Source\Table` or custom | — | Dropdown. Stores the `option_id` (integer) from `eav_attribute_option`. Type is `int` because it stores a foreign key to the option table. |
| `multiselect` | `varchar` | `Magento\Eav\Model\Entity\Attribute\Source\Table` or custom | `Magento\Eav\Model\Entity\Attribute\Backend\ArrayBackend` | Multi-select. Stores comma-separated option IDs as VARCHAR. Backend model handles array↔string conversion. Without `ArrayBackend`, values won't save/load correctly. |
| `price` | `decimal` | — | `Magento\Catalog\Model\Product\Attribute\Backend\Price` | Product price field. Backend model handles price-specific validation and scope. **Product entity only.** |
| `weight` | `decimal` | — | — | Product weight. No special backend needed. **Product entity only.** |
| `media_image` | `varchar` | — | — | Product image. Stores the image path as VARCHAR. Used with the product media gallery system. **Product entity only.** |
| `image` | `varchar` | — | `Magento\Catalog\Model\Category\Attribute\Backend\Image` | Category image upload. Backend handles file upload and storage. **Category entity only.** |
| `hidden` | `varchar` | — | — | Hidden input. Not shown in forms but stored in DB. Useful for programmatic values. |
| `multiline` | `text` | — | — | Multiple text lines. Stored as TEXT. Used for addresses (street lines). |

## Why These Mappings Matter

### `select` uses `int`, not `varchar`
A dropdown stores the **option_id** (an integer) from the `eav_attribute_option` table, not the option label text. The label is looked up at display time via the source model. If you use `varchar`, option lookups break.

### `multiselect` uses `varchar`, not `text`
Multiple option_ids are stored as a comma-separated string (e.g., `"4,7,12"`). This fits in VARCHAR. The `ArrayBackend` model converts between PHP arrays and this string format.

### `boolean` uses `int`, not `boolean`
Magento EAV does not have a native boolean backend type. It stores `0` or `1` as an integer. The `Source\Boolean` model provides "Yes"/"No" labels for display.

### `date` needs `Datetime` backend
Without the `Datetime` backend model, dates entered in the admin may save in an inconsistent format depending on the user's locale. The backend model normalizes dates to MySQL datetime format.

### `price` needs `Price` backend
The `Price` backend model handles scope-aware price saving and validation. Without it, prices may not respect the catalog price scope setting. Only valid for product attributes.

### `multiselect` without `ArrayBackend` = silent data corruption
The attribute will appear to work in the admin (you can select multiple options), but on save, only the last selected value persists. The `ArrayBackend` is what serializes the array to a comma-separated string.

## Rarely Used Input Types

| Input | Type | Notes |
|-------|------|-------|
| `gallery` | `varchar` | Legacy. Replaced by the media gallery system for products. |
| `swatch_visual` | `int` | Visual swatch (color/image). Same storage as `select`. Requires swatch modules. |
| `swatch_text` | `int` | Text swatch. Same storage as `select`. Requires swatch modules. |
| `weee` | `static` | Fixed product tax (WEEE/FPT). Stored in a separate table, not EAV value tables. |

## Backend Type to EAV Table Mapping

Understanding where values are physically stored helps debug issues:

| Backend Type (`type`) | EAV Value Table (Product) | MySQL Column Type |
|-----------------------|--------------------------|-------------------|
| `varchar` | `catalog_product_entity_varchar` | VARCHAR(255) |
| `int` | `catalog_product_entity_int` | INT |
| `decimal` | `catalog_product_entity_decimal` | DECIMAL(20,6) |
| `text` | `catalog_product_entity_text` | TEXT |
| `datetime` | `catalog_product_entity_datetime` | DATETIME |
| `static` | Column on `catalog_product_entity` itself | Varies |

For customer attributes, replace `catalog_product` with `customer` in the table names.

`static` type means the value is stored as a column directly on the entity table (`catalog_product_entity.{attribute_code}`), not in a separate EAV value table. This requires a `db_schema.xml` change to add the column — use `/m2-db-schema` for that part.
