# Theme Override Patterns

## Override vs Extend

| Approach | Location | Effect |
|----------|----------|--------|
| **Extend** | `{Module}/layout/{handle}.xml` | Merges with original layout — adds/modifies elements |
| **Override** | `{Module}/layout/override/base/{handle}.xml` | Completely replaces the original layout file |

**Always prefer extending** over overriding. Overrides break when the original file changes across Magento upgrades.

## Theme file paths

```
app/design/frontend/{Vendor}/{theme}/
├── {Vendor}_{ModuleName}/
│   ├── layout/
│   │   ├── {handle}.xml                          # Extend layout
│   │   └── override/
│   │       └── base/
│   │           └── {handle}.xml                   # Override layout
│   ├── templates/
│   │   └── {template_path}.phtml                  # Override template
│   └── web/
│       ├── css/
│       │   └── source/
│       │       └── _module.less                   # Override/extend styles
│       └── js/
│           └── {script}.js                        # Override JS
├── Magento_Theme/
│   └── layout/
│       └── default.xml                            # Site-wide layout changes
├── etc/
│   └── view.xml                                   # Image sizes, etc.
├── web/
│   ├── css/source/                                # Theme-level styles
│   └── js/                                        # Theme-level JS
├── registration.php
└── theme.xml
```

## Template override

To override a template from `vendor/magento/module-catalog/view/frontend/templates/product/view.phtml`:

Place it at:
```
app/design/frontend/{Vendor}/{theme}/Magento_Catalog/templates/product/view.phtml
```

The path inside `templates/` must exactly match the original.

## Layout extend in theme

To add a block to all pages, create:
```
app/design/frontend/{Vendor}/{theme}/Magento_Theme/layout/default.xml
```

This merges with the core `default.xml` — add only your changes.
