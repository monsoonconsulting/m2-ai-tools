# System Configuration Field Types Reference

## Field Types

| Type | Description | Requires |
|------|------------|----------|
| `text` | Single-line text input | — |
| `textarea` | Multi-line text input | — |
| `select` | Dropdown | `<source_model>` |
| `multiselect` | Multi-select list | `<source_model>` |
| `obscure` | Masked input (passwords/secrets) | `<backend_model>Magento\Config\Model\Config\Backend\Encrypted</backend_model>` |
| `label` | Read-only display text | — |
| `image` | Image file upload | `<backend_model>Magento\Config\Model\Config\Backend\Image</backend_model>`, optional `<upload_dir>` |
| `file` | Generic file upload | `<backend_model>Magento\Config\Model\Config\Backend\File</backend_model>`, `<upload_dir>` |
| `time` | Time picker (HH:MM:SS) | — |
| `note` | Display-only note/HTML | Use `<comment>` for content |
| `editor` | WYSIWYG HTML editor | Optional `<frontend_model>` |

## Built-In Source Models

| Source Model | Options |
|---|---|
| `Magento\Config\Model\Config\Source\Yesno` | Yes (1) / No (0) |
| `Magento\Config\Model\Config\Source\Enabledisable` | Enable (1) / Disable (0) |
| `Magento\Config\Model\Config\Source\Locale` | All available locales |
| `Magento\Config\Model\Config\Source\Store` | All store views |
| `Magento\Config\Model\Config\Source\Website` | All websites |
| `Magento\Directory\Model\Config\Source\Country` | All countries |
| `Magento\Directory\Model\Config\Source\Allregion` | All regions |
| `Magento\Shipping\Model\Config\Source\Allmethods` | All shipping methods |
| `Magento\Payment\Model\Config\Source\Allmethods` | All payment methods |
| `Magento\Customer\Model\Config\Source\Group` | Customer groups |
| `Magento\Catalog\Model\Config\Source\Category` | Category tree |
| `Magento\Cms\Model\Config\Source\Page` | CMS pages |
| `Magento\Cms\Model\Config\Source\Block` | CMS blocks |
| `Magento\Email\Model\Config\Source\Template` | Email templates |
| `Magento\Config\Model\Config\Source\Email\Identity` | Email sender identities |
| `Magento\Cron\Model\Config\Source\Frequency` | Cron frequencies (daily/weekly/monthly) |

## Built-In Backend Models

| Backend Model | Purpose |
|---|---|
| `Magento\Config\Model\Config\Backend\Encrypted` | Encrypts value before saving to DB |
| `Magento\Config\Model\Config\Backend\Serialized\ArraySerialized` | Serializes array data (dynamic rows) |
| `Magento\Config\Model\Config\Backend\Image` | Handles image upload + storage |
| `Magento\Config\Model\Config\Backend\File` | Handles file upload + storage |
| `Magento\Config\Model\Config\Backend\Currency\Allow` | Validates allowed currencies |
| `Magento\Cron\Model\Config\Backend\Cron` | Validates cron expression format |

## Scope Constants

| Scope | `showIn*` Attribute | `ScopeInterface` Constant | Meaning |
|-------|---------------------|---------------------------|---------|
| Default | `showInDefault="1"` | `ScopeConfigInterface::SCOPE_TYPE_DEFAULT` | Global value |
| Website | `showInWebsite="1"` | `ScopeInterface::SCOPE_WEBSITE` | Per-website |
| Store View | `showInStore="1"` | `ScopeInterface::SCOPE_STORE` | Per-store-view (most granular) |

Use the most restrictive scope needed. API keys/secrets: default or website only. Display settings: store view.
