# Source & Backend Models Reference

## Source Models

Source models provide the list of options for `select`, `multiselect`, and `boolean` attributes.

### Built-in Source Models

| Class | Short Reference | Use Case |
|-------|----------------|----------|
| `Magento\Eav\Model\Entity\Attribute\Source\Table` | `Source\Table` | Admin-managed options stored in `eav_attribute_option` / `eav_attribute_option_value`. Default choice for `select` and `multiselect`. |
| `Magento\Eav\Model\Entity\Attribute\Source\Boolean` | `Source\Boolean` | Yes/No dropdown. Always use for `boolean` input type. Provides labels "Yes" and "No". |
| `Magento\Catalog\Model\Product\Attribute\Source\Status` | `Source\Status` | Product status (Enabled/Disabled). Product entity only. |
| `Magento\Catalog\Model\Product\Attribute\Source\Countryofmanufacture` | `Source\Countryofmanufacture` | Country list. Useful for country-of-origin attributes. |
| `Magento\Customer\Model\Customer\Attribute\Source\Group` | `Source\Group` | Customer group list. Useful for customer-group-based attributes. |
| `Magento\Customer\Model\Customer\Attribute\Source\Store` | `Source\Store` | Store view list. |
| `Magento\Customer\Model\Customer\Attribute\Source\Website` | `Source\Website` | Website list. |
| `Magento\Catalog\Model\Category\Attribute\Source\Layout` | `Source\Layout` | Page layout options (1column, 2columns-left, etc.). Category entity only. |
| `Magento\Catalog\Model\Category\Attribute\Source\Mode` | `Source\Mode` | Category display mode (Products only, Static block only, Both). Category entity only. |

### When to Use `Source\Table` vs Custom Source

**Use `Source\Table` when:**
- Options are simple labels (e.g., "Small", "Medium", "Large")
- Options should be editable in admin (Stores > Attributes > Product)
- Options are passed via the `option` key in `addAttribute()`
- You need store-view-specific option translations

**Use a custom source model when:**
- Options are derived from another entity or database table
- Options need programmatic logic (e.g., filtered by config, computed)
- Option values are non-integer strings (e.g., `'type_a'`, `'type_b'`)
- Options are constant and should not be admin-editable

### Custom Source Model Pattern

Extend `AbstractSource` and implement `getAllOptions()`:

```php
use Magento\Eav\Model\Entity\Attribute\Source\AbstractSource;

final class CustomSource extends AbstractSource
{
    public function getAllOptions(): array
    {
        if ($this->_options === null) {
            $this->_options = [
                ['value' => '', 'label' => __('-- Please Select --')],
                ['value' => 'value_1', 'label' => __('Label One')],
                ['value' => 'value_2', 'label' => __('Label Two')],
            ];
        }
        return $this->_options;
    }
}
```

If you need DI dependencies (e.g., to fetch options from a repository), add them to the constructor:

```php
final class CustomSource extends AbstractSource
{
    public function __construct(
        private readonly SomeRepositoryInterface $repository
    ) {
    }

    public function getAllOptions(): array
    {
        if ($this->_options === null) {
            $this->_options = [['value' => '', 'label' => __('-- Please Select --')]];
            foreach ($this->repository->getList() as $item) {
                $this->_options[] = [
                    'value' => $item->getId(),
                    'label' => $item->getName(),
                ];
            }
        }
        return $this->_options;
    }
}
```

## Backend Models

Backend models handle value serialization, validation, and processing before save/after load.

### Built-in Backend Models

| Class | Short Reference | Required For | Purpose |
|-------|----------------|-------------|---------|
| `Magento\Eav\Model\Entity\Attribute\Backend\ArrayBackend` | `Backend\ArrayBackend` | `multiselect` | Converts array ↔ comma-separated string. **Required** for multiselect to work. |
| `Magento\Eav\Model\Entity\Attribute\Backend\Datetime` | `Backend\Datetime` | `date` input | Normalizes date format to MySQL datetime. Prevents locale-dependent date storage issues. |
| `Magento\Catalog\Model\Product\Attribute\Backend\Price` | `Backend\Price` | `price` input (product) | Handles price scope (global/website), validation, and tier price interactions. |
| `Magento\Catalog\Model\Category\Attribute\Backend\Image` | `Backend\Image` (category) | `image` input (category) | Handles image file upload, storage in `pub/media/catalog/category/`, and path management. |
| `Magento\Catalog\Model\Product\Attribute\Backend\Boolean` | `Backend\Boolean` (product) | Optional for `boolean` | Normalizes boolean values. Usually not required — `int` type with `Source\Boolean` is sufficient. |

### When Backend Models Are Required

| Input Type | Backend Model Required? | Why |
|-----------|------------------------|-----|
| `text` | No | Simple varchar storage, no transformation needed |
| `textarea` | No | Simple text storage |
| `select` | No | Stores a single integer (option_id) |
| `multiselect` | **Yes** — `ArrayBackend` | Must convert between PHP array and comma-separated string |
| `boolean` | No | Stores 0 or 1 as integer |
| `date` | **Yes** — `Datetime` | Must normalize date format |
| `price` | **Yes** — `Price` | Must handle price scope and validation |
| `image` (category) | **Yes** — `Image` | Must handle file upload |
| `media_image` (product) | No | Product media gallery handles storage separately |

### Custom Backend Model Pattern

Extend `AbstractBackend` for custom validation or processing:

```php
use Magento\Eav\Model\Entity\Attribute\Backend\AbstractBackend;
use Magento\Framework\Exception\LocalizedException;

final class CustomValidation extends AbstractBackend
{
    public function beforeSave($object): self
    {
        $value = $object->getData($this->getAttribute()->getAttributeCode());

        if ($value && !$this->isValid($value)) {
            throw new LocalizedException(__('Invalid value for %1.', $this->getAttribute()->getLabel()));
        }

        return parent::beforeSave($object);
    }

    private function isValid(mixed $value): bool
    {
        // Custom validation logic
        return true;
    }
}
```
