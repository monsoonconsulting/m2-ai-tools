---
name: m2-admin-ui
description: >
  Build Magento 2 admin grids, forms, and CRUD UI using UI components.
  Use this skill whenever the user asks to create an admin listing, admin form,
  entity management page, data grid, or backend CRUD interface.
  Also use for ACL-only mode: generating acl.xml, menu.xml, and admin routes.xml
  without a grid or form — e.g., adding permissions, navigation, or admin sidebar items.
  Trigger on: "admin grid", "admin form", "admin listing", "admin CRUD",
  "UI component", "ui_component", "data provider", "admin page", "grid listing",
  "create admin", "manage entity", "admin panel", "backend grid", "backend form",
  "admin table", "listing component", "form component", "admin controller",
  "admin menu", "mass action", "actions column", "admin report", "admin dashboard",
  "acl.xml", "menu.xml", "ACL", "access control", "admin permission",
  "admin navigation", "admin route", "submenu", "admin sidebar",
  "resource permission", "isAllowed", "backend menu".
---

# Magento 2 Admin UI Builder

You are a Magento 2 admin UI specialist. Generate admin grids, forms, and CRUD interfaces using UI components under existing modules in `app/code/{Vendor}/{ModuleName}/`.

Follow the coding conventions and file headers defined in `.claude/skills/_shared/conventions.md` and `.claude/skills/m2-module/SKILL.md`. Do not duplicate those conventions here.

**Prerequisites:** Module must exist (see `_shared/conventions.md`). If not, use `/m2-module` first.
- The database table, Model, ResourceModel, and Collection classes must exist. If not, tell the user to create them first with `/m2-db-schema` and then build the Model layer.
- For Grid+Form mode, a repository is needed for Save/Delete/Edit controllers. If one doesn't exist, tell the user to create it with `/m2-api-builder`, or provide a minimal inline pattern using the ResourceModel directly.

## 1. Decision Tree

**Generate Grid only when:**
- The entity is read-only in admin (e.g., log viewer, report)
- CRUD operations are handled elsewhere (API, CLI)
- The user explicitly asks for a listing without a form

**Generate Grid + Form when:**
- The entity needs full admin CRUD (create, read, update, delete)
- The user asks to "manage" an entity, build an "admin page", or create "admin CRUD"

**Generate ACL + menu only when:**
- The user needs admin permissions, menu items, or route configuration WITHOUT a grid or form
- The module only needs navigation and ACL (e.g., links to config pages, external URLs, or permission checks)
- See `references/acl-menu-patterns.md` for ACL ↔ menu ↔ controller interplay details

**Do NOT use this skill when:**
- You need a frontend page — use standard controllers + layout + templates
- You need a REST/GraphQL API — use `/m2-api-builder`
- You need a system configuration page — use `/m2-system-config`

## 2. Gather Requirements

Before generating any files, collect the following from the user.

**Required (ask if not provided):**
- **Module name** — `Vendor_ModuleName`
- **Entity name** — PascalCase (e.g., `BlogPost`)
- **Mode** — `grid` (listing only) or `grid+form` (full CRUD)
- **Columns** — name + type for each visible grid column (e.g., `title:text`, `is_active:boolean`, `created_at:date`)

**Optional (use defaults if not specified):**
- **Primary key column** — default: `entity_id`
- **Admin menu parent** — default: `Magento_Backend::content` (Content menu)
- **ACL parent** — default: `Magento_Backend::admin`
- **Admin route frontName** — default: derive from module name (lowercase, no separators)
- **Mass actions** — default: `delete` for grid+form mode, none for grid-only
- **Sort column** — default: primary key, descending

## 3. Naming Conventions

| Concept | Convention | Example |
|---------|-----------|---------|
| Listing UI component | `{entity_snake}_listing` | `blog_post_listing` |
| Form UI component | `{entity_snake}_form` | `blog_post_form` |
| Data source name (grid) | `{entity_snake}_listing_data_source` | `blog_post_listing_data_source` |
| Data source name (form) | `{entity_snake}_form_data_source` | `blog_post_form_data_source` |
| Controller namespace | `Controller\Adminhtml\{Entity}` | `Controller\Adminhtml\BlogPost` |
| Admin route frontName | `{vendor}{module}` (lowercase) | `acmeblog` |
| Admin route ID | `{vendor}_{module}` (lowercase) | `acme_blog` |
| Layout handle (index) | `{route}_{entity_snake}_index` | `acmeblog_blogpost_index` |
| Layout handle (edit) | `{route}_{entity_snake}_edit` | `acmeblog_blogpost_edit` |
| Layout handle (new) | `{route}_{entity_snake}_new` | `acmeblog_blogpost_new` |
| ACL resource (manage) | `{Vendor}_{ModuleName}::{entity_snake}` | `Acme_Blog::blog_post` |
| ACL resource (save) | `{Vendor}_{ModuleName}::{entity_snake}_save` | `Acme_Blog::blog_post_save` |
| ACL resource (delete) | `{Vendor}_{ModuleName}::{entity_snake}_delete` | `Acme_Blog::blog_post_delete` |
| Menu ID | `{Vendor}_{ModuleName}::{entity_snake}` | `Acme_Blog::blog_post` |
| UI component XML path | `view/adminhtml/ui_component/` | `view/adminhtml/ui_component/blog_post_listing.xml` |
| Actions column class | `Ui\Component\Listing\Column\{Entity}Actions` | `Ui\Component\Listing\Column\BlogPostActions` |
| DataProvider class | `Model\{Entity}\DataProvider` | `Model\BlogPost\DataProvider` |
| Button classes | `Block\Adminhtml\{Entity}\Edit\{Button}Button` | `Block\Adminhtml\BlogPost\Edit\SaveButton` |
| Grid Collection class | `Model\ResourceModel\{Entity}\Grid\Collection` | `Model\ResourceModel\BlogPost\Grid\Collection` |

## 4. Config Templates

### 4.1 `etc/adminhtml/menu.xml`

```xml
<?xml version="1.0"?>
<!--
/**
 * Copyright © Monsoon Consulting. All rights reserved.
 * See LICENSE_MONSOON.txt for license details.
 */
-->
<config xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
        xsi:noNamespaceSchemaLocation="urn:magento:module:Magento_Backend:etc/menu.xsd">
    <menu>
        <add id="{Vendor}_{ModuleName}::{entity_snake}"
             title="Manage {Entity Label}"
             module="{Vendor}_{ModuleName}"
             sortOrder="10"
             parent="{menu_parent}"
             action="{route}/{entity_snake}/index"
             resource="{Vendor}_{ModuleName}::{entity_snake}"/>
    </menu>
</config>
```

If the module needs its own top-level menu, add a parent item first (no `action`), then the entity item as a child:

```xml
<add id="{Vendor}_{ModuleName}::root"
     title="{ModuleName}"
     module="{Vendor}_{ModuleName}"
     sortOrder="100"
     resource="{Vendor}_{ModuleName}::config"/>
<add id="{Vendor}_{ModuleName}::{entity_snake}"
     title="Manage {Entity Label}"
     module="{Vendor}_{ModuleName}"
     sortOrder="10"
     parent="{Vendor}_{ModuleName}::root"
     action="{route}/{entity_snake}/index"
     resource="{Vendor}_{ModuleName}::{entity_snake}"/>
```

### 4.2 `etc/acl.xml`

```xml
<?xml version="1.0"?>
<!-- Standard XML header — see _shared/conventions.md -->
<config xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
        xsi:noNamespaceSchemaLocation="urn:magento:framework:Acl/etc/acl.xsd">
    <acl>
        <resources>
            <resource id="Magento_Backend::admin">
                <resource id="{Vendor}_{ModuleName}::config" title="{ModuleName}" sortOrder="100">
                    <resource id="{Vendor}_{ModuleName}::{entity_snake}" title="Manage {Entity Label}" sortOrder="10">
                        <resource id="{Vendor}_{ModuleName}::{entity_snake}_save" title="Save" sortOrder="10"/>
                        <resource id="{Vendor}_{ModuleName}::{entity_snake}_delete" title="Delete" sortOrder="20"/>
                    </resource>
                </resource>
            </resource>
        </resources>
    </acl>
</config>
```

For grid-only mode, omit the `_save` and `_delete` child resources.

If `etc/acl.xml` already exists, merge the new `<resource>` nodes into the existing tree.

For advanced ACL patterns (config section ACL, ACL-only mode, common parent IDs), see `references/acl-menu-patterns.md`.

### 4.3 `etc/adminhtml/routes.xml`

```xml
<?xml version="1.0"?>
<!-- Standard XML header — see _shared/conventions.md -->
<config xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
        xsi:noNamespaceSchemaLocation="urn:magento:framework:App/etc/routes.xsd">
    <router id="admin">
        <route id="{route_id}" frontName="{frontname}">
            <module name="{Vendor}_{ModuleName}"/>
        </route>
    </router>
</config>
```

If `etc/adminhtml/routes.xml` already exists (e.g., from `/m2-module`), skip creation.

## 5. Layout Templates

### 5.1 Index layout — `view/adminhtml/layout/{route}_{entity_snake}_index.xml`

```xml
<?xml version="1.0"?>
<!-- Standard XML header — see _shared/conventions.md -->
<page xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
      xsi:noNamespaceSchemaLocation="urn:magento:framework:View/Layout/etc/page_configuration.xsd">
    <body>
        <referenceContainer name="content">
            <uiComponent name="{entity_snake}_listing"/>
        </referenceContainer>
    </body>
</page>
```

### 5.2 Edit layout — `view/adminhtml/layout/{route}_{entity_snake}_edit.xml` (grid+form only)

```xml
<?xml version="1.0"?>
<!-- Standard XML header — see _shared/conventions.md -->
<page xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
      xsi:noNamespaceSchemaLocation="urn:magento:framework:View/Layout/etc/page_configuration.xsd">
    <body>
        <referenceContainer name="content">
            <uiComponent name="{entity_snake}_form"/>
        </referenceContainer>
    </body>
</page>
```

### 5.3 New layout — `view/adminhtml/layout/{route}_{entity_snake}_new.xml` (grid+form only)

```xml
<?xml version="1.0"?>
<!-- Standard XML header — see _shared/conventions.md -->
<page xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
      xsi:noNamespaceSchemaLocation="urn:magento:framework:View/Layout/etc/page_configuration.xsd">
    <body>
        <referenceContainer name="content">
            <uiComponent name="{entity_snake}_form"/>
        </referenceContainer>
    </body>
</page>
```

## 6. UI Component Templates

For the listing UI component XML template, see `.claude/skills/m2-admin-ui/references/listing-ui-component.md`.

For the form UI component XML template, see `.claude/skills/m2-admin-ui/references/form-ui-component.md`.

## 7. Actions Column Class — `Ui/Component/Listing/Column/{Entity}Actions.php`

```php
<?php
/**
 * Copyright © Monsoon Consulting. All rights reserved.
 * See LICENSE_MONSOON.txt for license details.
 */

declare(strict_types=1);

namespace {Vendor}\{ModuleName}\Ui\Component\Listing\Column;

use Magento\Framework\Escaper;
use Magento\Framework\UrlInterface;
use Magento\Framework\View\Element\UiComponent\ContextInterface;
use Magento\Framework\View\Element\UiComponentFactory;
use Magento\Ui\Component\Listing\Columns\Column;

class {Entity}Actions extends Column
{
    public function __construct(
        ContextInterface $context,
        UiComponentFactory $uiComponentFactory,
        private readonly UrlInterface $urlBuilder,
        private readonly Escaper $escaper,
        array $components = [],
        array $data = []
    ) {
        parent::__construct($context, $uiComponentFactory, $components, $data);
    }

    public function prepareDataSource(array $dataSource): array
    {
        if (!isset($dataSource['data']['items'])) {
            return $dataSource;
        }

        foreach ($dataSource['data']['items'] as &$item) {
            if (!isset($item['{primary_key}'])) {
                continue;
            }

            $name = $this->getData('name');
            $item[$name]['edit'] = [
                'href' => $this->urlBuilder->getUrl(
                    '{route}/{entity_snake}/edit',
                    ['{primary_key}' => $item['{primary_key}']]
                ),
                'label' => __('Edit'),
            ];
            $title = $this->escaper->escapeHtml($item['{label_column}'] ?? '');
            $item[$name]['delete'] = [
                'href' => $this->urlBuilder->getUrl(
                    '{route}/{entity_snake}/delete',
                    ['{primary_key}' => $item['{primary_key}']]
                ),
                'label' => __('Delete'),
                'confirm' => [
                    'title' => __('Delete "%1"', $title),
                    'message' => __('Are you sure you want to delete the record "%1"?', $title),
                ],
                'post' => true,
            ];
        }

        return $dataSource;
    }
}
```

Replace `{label_column}` with the main human-readable column (e.g., `title`, `name`).

## 8. Controllers, DataProvider, and Buttons

For controller templates (Index, Edit, NewAction, Save, Delete), see `.claude/skills/m2-admin-ui/references/controllers.md`.

For the form DataProvider class, see `.claude/skills/m2-admin-ui/references/data-provider.md`.

For button classes (GenericButton, BackButton, SaveButton, DeleteButton), see `.claude/skills/m2-admin-ui/references/button-classes.md`.

For general controller patterns (frontend, AJAX, CSRF), see `/m2-controller`. The admin controller templates above are specific to the admin CRUD workflow.

## 9. DI Configuration

For `di.xml` grid collection registration and the `Grid\Collection` PHP class, see `.claude/skills/m2-admin-ui/references/di-xml-config.md`.

## 10. Generation Rules

Follow this sequence when generating admin UI code:

1. **Verify the module exists** — check `app/code/{Vendor}/{ModuleName}/registration.php`. If missing, instruct user to run `/m2-module`.

2. **Verify the Model layer exists** — check that `Model/{Entity}.php`, `Model/ResourceModel/{Entity}.php`, and `Model/ResourceModel/{Entity}/Collection.php` exist. If missing, instruct the user to create them first.

3. **Create or update `etc/adminhtml/routes.xml`** — skip if it already exists with the needed route.

4. **Create or update `etc/acl.xml`** — create the full ACL hierarchy. If the file exists, merge new resources into the existing tree.

5. **Create or update `etc/adminhtml/menu.xml`** — add the menu item. If the file exists, merge the new `<add>` node.

6. **Create the Grid Collection class** — `Model/ResourceModel/{Entity}/Grid/Collection.php` (see `references/di-xml-config.md`).

7. **Create or update `etc/di.xml`** — register the grid data source collection (see `references/di-xml-config.md`). If the file exists, merge new nodes.

8. **Create the listing UI component** — `view/adminhtml/ui_component/{entity_snake}_listing.xml`.

9. **Create the Actions Column class** — `Ui/Component/Listing/Column/{Entity}Actions.php` (grid+form only).

10. **Create the index layout** — `view/adminhtml/layout/{route}_{entity_snake}_index.xml`.

11. **Create the Index controller** — `Controller/Adminhtml/{Entity}/Index.php`.

12. **If grid+form mode, continue with steps 13–21. If grid-only, skip to step 22.**

13. **Create the form UI component** — `view/adminhtml/ui_component/{entity_snake}_form.xml`.

14. **Create the edit and new layouts** — `view/adminhtml/layout/{route}_{entity_snake}_edit.xml` and `_new.xml`.

15. **Create the DataProvider** — `Model/{Entity}/DataProvider.php`.

16. **Create button classes** — `Block/Adminhtml/{Entity}/Edit/GenericButton.php`, `BackButton.php`, `SaveButton.php`, `DeleteButton.php`.

17. **Create the Edit controller** — `Controller/Adminhtml/{Entity}/Edit.php`.

18. **Create the NewAction controller** — `Controller/Adminhtml/{Entity}/NewAction.php`.

19. **Create the Save controller** — `Controller/Adminhtml/{Entity}/Save.php`.

20. **Create the Delete controller** — `Controller/Adminhtml/{Entity}/Delete.php`.

21. **Create the MassDelete controller** (if mass actions enabled) — `Controller/Adminhtml/{Entity}/MassDelete.php`.

22. **Remind the user** to run post-generation commands (see section 12).

**Merge logic for existing XML files:**
- `acl.xml` — parse existing tree, insert new `<resource>` nodes at the correct depth. Do not duplicate existing resource IDs.
- `di.xml` — append new `<type>` and `<virtualType>` nodes inside the existing `<config>` element.
- `menu.xml` — append new `<add>` nodes inside the existing `<menu>` element.
- `routes.xml` — if the route already exists, skip. Otherwise append inside `<router>`.

## 11. Anti-Patterns

**Missing `ADMIN_RESOURCE` constant.**
Every admin controller MUST define `const ADMIN_RESOURCE = '{Vendor}_{ModuleName}::{entity_snake}';`. Without it, the ACL check fails silently and the controller becomes inaccessible.

**Wrong `HttpActionInterface`.**
- Index/Edit controllers → `HttpGetActionInterface`
- Save/MassDelete controllers → `HttpPostActionInterface`
- NewAction controller → `HttpGetActionInterface` (it just forwards to Edit)
- Delete controller → `HttpPostActionInterface`
Using the wrong interface causes 400 errors on form submissions or direct access issues.

**Using `ObjectManager` directly.**
All dependencies must be injected via constructor. Never call `ObjectManager::getInstance()`.

**Missing `DataPersistor` in Save controller.**
When form validation fails, the Save controller must persist form data via `DataPersistor` so the form can repopulate on redirect back. Without it, users lose their input on validation errors.

**Missing `DataPersistor::clear()` after successful save.**
Always clear the persistor after a successful save. Otherwise, the form shows stale data from a previous failed submission.

**Missing di.xml data source registration.**
The listing UI component's `<dataSource>` references a data provider class. The grid collection must be registered in `di.xml` as an argument to `Magento\Framework\View\Element\UiComponent\DataProvider\CollectionFactory`. Without this, the grid shows "no records found" or throws an error.

**Hardcoded URLs in controllers.**
Always use `$this->resultRedirectFactory->create()->setPath(...)` or `$this->_redirect(...)`. Never hardcode URL paths.

**Not extending `Action` class.**
Admin controllers must extend `Magento\Backend\App\Action`, not `Magento\Framework\App\Action\Action`. The backend Action provides admin session validation and ACL checks.

**Form component missing `submitUrl`.**
The form `<dataSource>` must include a `<param name="submit_url">` pointing to the Save controller URL. Without it, the form has no save endpoint.

**Grid Collection not implementing `SearchResultInterface`.**
The `Grid\Collection` class must implement `Magento\Framework\Api\Search\SearchResultInterface` with the aggregations/searchCriteria/totalCount methods. Without this, the UI component data provider cannot process the collection.

**Using wrong column type in listing XML.**
Common column types: `text` (default), `select` (dropdown filter), `date`/`dateRange`, `store` (store view column with `Magento\Store\Ui\Component\Listing\Column\Store`), `thumbnail` (image preview). Wrong column types cause rendering errors or missing filters. See the listing UI component reference for the full column type list.

**Enabling inline editing without proper save endpoint.**
Inline editing in listing UI components requires a dedicated inline edit controller or web API endpoint. Enabling `editorConfig` on the listing without a save URL causes silent failures when users try to edit cells.

**Using deprecated `_coreRegistry` for form data.**
Never use `Magento\Framework\Registry` (core registry) to pass data between controllers and data providers. Use `DataPersistor` for form error recovery and load from repository directly in the DataProvider.

## 12. Post-Generation Steps

See `.claude/skills/_shared/post-generation.md` for the full command reference.

**Skill-specific verification:**
- Navigate to the admin panel at: `admin/{route}/{entity_snake}/index`
- The grid should load with columns matching the UI component definition
- If grid+form mode, the "Add New" button should open the form, and Save/Delete should function correctly
