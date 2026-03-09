# ACL & Admin Menu Patterns

Reference for ACL, menu, and route configuration patterns used by `/m2-admin-ui`.

## ACL ↔ Menu ↔ Controller Interplay

The three files work together:
1. **acl.xml** defines the permission tree (what roles can access)
2. **menu.xml** links menu items to ACL resources (menu hidden if no permission)
3. **Controller `ADMIN_RESOURCE`** enforces the permission on the actual page

**All three must reference the same ACL resource ID.** If they don't match:
- Menu shows but page returns 403 → controller ACL doesn't match menu ACL
- Menu is hidden but URL works → menu resource doesn't match controller resource
- Neither works → ACL resource ID has a typo or isn't registered

## Config Section ACL Pattern

When your module has system configuration (`system.xml`), the config ACL resource must nest under `Magento_Config::config`, not directly under `Magento_Backend::admin`:

```xml
<resource id="Magento_Backend::admin">
    <resource id="Magento_Backend::stores">
        <resource id="Magento_Config::config">
            <resource id="{Vendor}_{ModuleName}::config" title="{Module} Configuration"/>
        </resource>
    </resource>
</resource>
```

This resource ID is referenced in `system.xml` via the `<resource>` tag on the section.

## Common Parent Menu IDs

Use these as the `parent` attribute in `menu.xml` to nest items under existing Magento sections:

| Parent ID | Menu Section |
|-----------|-------------|
| `Magento_Backend::content` | Content |
| `Magento_Backend::marketing` | Marketing |
| `Magento_Backend::stores` | Stores |
| `Magento_Backend::system` | System |
| `Magento_Catalog::catalog` | Catalog |
| `Magento_Sales::sales` | Sales |
| `Magento_Customer::customer` | Customers |
| `Magento_Reports::report` | Reports |

## Common Parent ACL IDs

| Parent Resource | Use For |
|----------------|---------|
| `Magento_Backend::admin` | Root — all custom resources nest under this |
| `Magento_Backend::content` | Content menu section |
| `Magento_Backend::stores` | Stores > Configuration section |
| `Magento_Backend::system` | System section |
| `Magento_Backend::marketing` | Marketing section |

## ACL Nesting Pattern

A typical module ACL tree:
```
Magento_Backend::admin
└── {Vendor}_{ModuleName}::top_level        (module root permission)
    ├── {Vendor}_{ModuleName}::manage        (manage entities)
    │   ├── {Vendor}_{ModuleName}::save      (create/edit)
    │   └── {Vendor}_{ModuleName}::delete    (delete)
    └── {Vendor}_{ModuleName}::config        (module configuration)
```

## ACL-Only Use Case (Permissions Without Grid/Form)

When you only need ACL resources and menu items — no admin grid or form:

1. Generate `etc/acl.xml` with the permission hierarchy
2. Generate `etc/adminhtml/menu.xml` with menu items pointing to existing actions or external URLs
3. Generate `etc/adminhtml/routes.xml` if the menu links to controllers in this module
4. Set `ADMIN_RESOURCE` on any admin controllers

This is common for:
- Modules that add configuration pages only (use `/m2-system-config` for the config UI)
- Modules that need permission checks on existing admin pages
- Modules that add menu shortcuts to external services
