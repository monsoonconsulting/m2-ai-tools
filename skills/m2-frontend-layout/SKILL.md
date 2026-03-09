---
name: m2-frontend-layout
description: >
  Generate Magento 2 frontend layout XML, ViewModels, phtml templates, RequireJS configuration,
  and theme overrides. Use this skill whenever the user asks to work with layout handles, blocks,
  containers, ViewModels, phtml templates, head assets, RequireJS, or theme overrides.
  Trigger on: "layout XML", "layout file", "layout handle", "default.xml", "page_configuration",
  "add block", "add container", "referenceBlock", "referenceContainer", "move block", "remove block",
  "block arguments", "update handle", "before after block", "ViewModel", "view model",
  "ArgumentInterface", "template data", "phtml", "phtml template", "create template",
  "template override", "escapeHtml", "escapeUrl", "escaper", "page layout", "1column",
  "2columns-left", "page title", "body class", "meta tag", "head assets", "add CSS", "add JS",
  "RequireJS", "requirejs-config", "JS mixin", "data-mage-init", "text/x-magento-init",
  "theme override", "theme layout", "override in theme".
---

# Magento 2 Frontend Layout & Templates

You are a Magento 2 frontend layout specialist. Generate layout XML files, ViewModels, phtml templates, RequireJS configuration, and theme overrides for modules in `app/code/{Vendor}/{ModuleName}/` or themes in `app/design/frontend/{Vendor}/{theme}/`.

Follow the coding conventions and file headers defined in `.claude/skills/_shared/conventions.md` and `.claude/skills/m2-module/SKILL.md`. Do not duplicate those conventions here.

**Prerequisites:** Module must exist (see `_shared/conventions.md`). If not, use `/m2-module` first.

## 1. Decision Tree

**Use this skill when:**
- Creating or modifying layout XML files (handles, blocks, containers)
- Creating ViewModels to pass data to templates
- Writing phtml templates
- Adding CSS/JS head assets to pages
- Configuring RequireJS (maps, paths, shims, mixins)
- Overriding layout or templates in a custom theme
- Setting page layout types, body classes, page titles, or meta tags

**Use `/m2-controller` instead when:**
- Creating a controller that returns a Page result — that skill creates the controller + minimal layout stub; come back here if the layout needs more than a basic block

**Use `/m2-admin-ui` instead when:**
- Building admin grids, forms, or CRUD interfaces — admin UI uses UI components, not layout XML blocks

**Do NOT use this skill for:**
- Hyvä themes, Alpine.js components, or Tailwind CSS — those belong to the `hyva-*` skills

## 2. Gather Requirements

Before generating any files, collect the following from the user.

**Required (ask if not provided):**
- **Module name** — `Vendor_ModuleName` (or theme path for theme overrides)
- **Purpose** — what needs to happen (add a block, create a ViewModel, override a template, etc.)
- **Area** — `frontend` (default) or `adminhtml`

**Optional (use defaults if not specified):**
- **Layout handle** — default: derive from context (e.g., `default` for site-wide, `catalog_product_view` for PDP)
- **Page layout type** — default: `1column`
- **Template name** — default: derive from purpose

## 3. Naming Conventions

| Concept | Convention | Example |
|---------|-----------|---------|
| Layout handle | `{route_id}_{folder}_{action}` (all lowercase) | `catalog_product_view` |
| Layout file path | `view/{area}/layout/{handle}.xml` | `view/frontend/layout/default.xml` |
| Block name | `{vendor}.{module}.{descriptive_name}` (dots, lowercase) | `acme.banner.homepage` |
| Container name | `{descriptive.name}` (dots, lowercase) | `sidebar.additional.info` |
| ViewModel class | `ViewModel\{DescriptiveName}` | `ViewModel\ProductBadges` |
| ViewModel path | `ViewModel/{DescriptiveName}.php` | `ViewModel/ProductBadges.php` |
| Template file | `view/{area}/templates/{path}.phtml` | `view/frontend/templates/badge/list.phtml` |
| Template reference | `{Vendor}_{ModuleName}::{path}.phtml` | `Acme_Badges::badge/list.phtml` |
| RequireJS config | `view/{area}/requirejs-config.js` | `view/frontend/requirejs-config.js` |
| JS file path | `view/{area}/web/js/{name}.js` | `view/frontend/web/js/custom-widget.js` |
| CSS file path | `view/{area}/web/css/source/{name}.less` | `view/frontend/web/css/source/_module.less` |
| Theme override layout | `app/design/frontend/{Vendor}/{theme}/{Module_Name}/layout/{handle}.xml` | |
| Theme override template | `app/design/frontend/{Vendor}/{theme}/{Module_Name}/templates/{path}.phtml` | |

## 4. Layout XML Concepts

Layout XML uses two XSD schemas:

| XSD | Root element | Purpose |
|-----|-------------|---------|
| `page_configuration.xsd` | `<page>` | Full page layout — contains `<head>` and `<body>`, sets page layout type |
| `page_layout.xsd` | `<layout>` | Page structure definitions (e.g., defining 1column, 2columns-left) |

Almost all module layout files use `page_configuration.xsd` with the `<page>` root element.

### Page root element attributes

```xml
<page xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
      xsi:noNamespaceSchemaLocation="urn:magento:framework:View/Layout/etc/page_configuration.xsd"
      layout="1column">
```

The `layout` attribute sets the page layout type. Valid values: `1column`, `2columns-left`, `2columns-right`, `3columns`, `empty`.

### Blocks vs Containers

- **Block** — renders output via a PHP class + template. Has a `class`, `template`, and optional arguments.
- **Container** — structural grouping element. Renders an HTML wrapper tag around its children. Has no class or template.

For the full reference of all layout operations (`<referenceBlock>`, `<referenceContainer>`, `<move>`, `<block>`, `<container>`, `<arguments>`, `<update>`), see `references/layout-operations.md`.

## 5. ViewModel Pattern

ViewModels are the preferred way to pass data and logic to phtml templates. They replace custom Block classes.

### Why ViewModels over Block classes

- ViewModels are simple PHP classes — no framework inheritance chain
- They can be attached to any `Template` block without creating a custom Block class
- They're easier to unit test (no Magento block dependencies)
- Multiple ViewModels can be attached to a single block

### ViewModel PHP class

```php
<?php
/**
 * Copyright © Monsoon Consulting. All rights reserved.
 * See LICENSE_MONSOON.txt for license details.
 */
declare(strict_types=1);

namespace {Vendor}\{ModuleName}\ViewModel;

use Magento\Framework\View\Element\Block\ArgumentInterface;

final class {ViewModelName} implements ArgumentInterface
{
    public function __construct(
        // Inject dependencies here
    ) {
    }

    // Public methods that templates call
}
```

### Attaching a ViewModel in layout XML

```xml
<block class="Magento\Framework\View\Element\Template"
       name="{vendor}.{module}.{block_name}"
       template="{Vendor}_{ModuleName}::{template_path}.phtml">
    <arguments>
        <argument name="view_model" xsi:type="object">{Vendor}\{ModuleName}\ViewModel\{ViewModelName}</argument>
    </arguments>
</block>
```

### Accessing the ViewModel in a template

```php
/** @var \Magento\Framework\View\Element\Template $block */
/** @var \Magento\Framework\Escaper $escaper */
/** @var \{Vendor}\{ModuleName}\ViewModel\{ViewModelName} $viewModel */
$viewModel = $block->getData('view_model');
```

### Multiple ViewModels on one block

```xml
<block class="Magento\Framework\View\Element\Template"
       name="{vendor}.{module}.{block_name}"
       template="{Vendor}_{ModuleName}::{template_path}.phtml">
    <arguments>
        <argument name="view_model" xsi:type="object">{Vendor}\{ModuleName}\ViewModel\Primary</argument>
        <argument name="helper_view_model" xsi:type="object">{Vendor}\{ModuleName}\ViewModel\Helper</argument>
    </arguments>
</block>
```

Access each by its argument name: `$block->getData('view_model')`, `$block->getData('helper_view_model')`.

## 6. Template Rules

Every phtml template must start with the `$block` and `$escaper` variable declarations:

```php
<?php
/**
 * Copyright © Monsoon Consulting. All rights reserved.
 * See LICENSE_MONSOON.txt for license details.
 */

/** @var \Magento\Framework\View\Element\Template $block */
/** @var \Magento\Framework\Escaper $escaper */
?>
```

### Escaping methods

All output in templates **must** be escaped. For the complete escaping reference with examples for each method, see `references/template-escaping.md`.

| Method | Use For |
|--------|---------|
| `$escaper->escapeHtml($string)` | General HTML content |
| `$escaper->escapeHtml($string, ['br', 'strong'])` | HTML content allowing specific tags |
| `$escaper->escapeHtmlAttr($string)` | HTML attribute values |
| `$escaper->escapeUrl($string)` | URL attribute values (href, src, action) |
| `$escaper->escapeJs($string)` | JavaScript string values |
| `$escaper->escapeCss($string)` | CSS property values |

### URL generation in templates

```php
$block->getUrl('route/controller/action')           // Full URL
$block->getUrl('route/controller/action', ['id' => 5])  // URL with params
$block->getViewFileUrl('Vendor_Module::js/script.js')    // Static file URL
```

### Form key

Always include in POST forms:

```php
<?= $block->getBlockHtml('formkey') ?>
```

### Translatable strings

```php
<?= $escaper->escapeHtml(__('Translatable text')) ?>
```

### Rendering child blocks

```php
<?= $block->getChildHtml('child.block.name') ?>   // Specific child
<?= $block->getChildHtml() ?>                       // All children
```

## 7. Layout XML Templates

**Including other handles:** Use `<update handle="customer_account"/>` to include another layout handle's instructions in your page. Useful for reusing shared layout structures.

### Basic page with block

```xml
<?xml version="1.0"?>
<!--
/**
 * Copyright © Monsoon Consulting. All rights reserved.
 * See LICENSE_MONSOON.txt for license details.
 */
-->
<page xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
      xsi:noNamespaceSchemaLocation="urn:magento:framework:View/Layout/etc/page_configuration.xsd">
    <body>
        <referenceContainer name="content">
            <block class="Magento\Framework\View\Element\Template"
                   name="{vendor}.{module}.{block_name}"
                   template="{Vendor}_{ModuleName}::{template_path}.phtml">
                <arguments>
                    <argument name="view_model" xsi:type="object">{Vendor}\{ModuleName}\ViewModel\{ViewModelName}</argument>
                </arguments>
            </block>
        </referenceContainer>
    </body>
</page>
```

### Page with head assets and layout type

```xml
<?xml version="1.0"?>
<!--
/**
 * Copyright © Monsoon Consulting. All rights reserved.
 * See LICENSE_MONSOON.txt for license details.
 */
-->
<page xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
      xsi:noNamespaceSchemaLocation="urn:magento:framework:View/Layout/etc/page_configuration.xsd"
      layout="2columns-left">
    <head>
        <css src="{Vendor}_{ModuleName}::css/styles.css"/>
        <script src="{Vendor}_{ModuleName}::js/custom.js"/>
        <title>Page Title</title>
        <meta name="description" content="Page description"/>
    </head>
    <body>
        <attribute name="class" value="custom-body-class"/>
        <referenceContainer name="content">
            <block class="Magento\Framework\View\Element\Template"
                   name="{vendor}.{module}.{block_name}"
                   template="{Vendor}_{ModuleName}::{template_path}.phtml"/>
        </referenceContainer>
    </body>
</page>
```

### Head asset types

| Element | Example | Purpose |
|---------|---------|---------|
| `<css>` | `<css src="Vendor_Module::css/styles.css"/>` | Add CSS file |
| `<css>` (media) | `<css src="..." media="print"/>` | CSS with media query |
| `<script>` | `<script src="Vendor_Module::js/custom.js"/>` | Add JS file |
| `<remove>` | `<remove src="Magento_Checkout::js/script.js"/>` | Remove a core asset |
| `<title>` | `<title>Page Title</title>` | Set page title |
| `<meta>` | `<meta name="robots" content="NOINDEX,NOFOLLOW"/>` | Add meta tag |
| `<link>` | `<link src="..." rel="preload" as="style"/>` | Add link tag |

## 8. RequireJS Configuration

For the full RequireJS reference including all config keys, JS initialization patterns, and custom widget patterns, see `references/requirejs-patterns.md`.

### Basic `requirejs-config.js`

```javascript
/**
 * Copyright © Monsoon Consulting. All rights reserved.
 * See LICENSE_MONSOON.txt for license details.
 */
var config = {
    map: {
        '*': {
            'customWidget': '{Vendor}_{ModuleName}/js/custom-widget'
        }
    }
};
```

### JS initialization in templates

**Declarative (preferred):**

```html
<div data-mage-init='{"customWidget": {"option": "value"}}'>
    Content
</div>
```

**Script-based:**

```html
<script type="text/x-magento-init">
{
    "#element-id": {
        "customWidget": {
            "option": "value"
        }
    }
}
</script>
```

**Wildcard (no DOM element):**

```html
<script type="text/x-magento-init">
{
    "*": {
        "{Vendor}_{ModuleName}/js/component": {
            "option": "value"
        }
    }
}
</script>
```

## 9. Theme Overrides

See `references/theme-overrides.md` for the complete theme override reference including:
- Override vs Extend comparison (always prefer extending)
- Theme directory structure
- Template override paths
- Layout extend and override in themes

## 10. Generation Rules

Follow this sequence when generating layout/template/ViewModel code:

1. **Verify the module exists** — check `app/code/{Vendor}/{ModuleName}/registration.php`. If missing, instruct user to run `/m2-module`.

2. **Determine the layout handle** — based on the route/page where the content should appear. Common handles:
   - `default` — all pages
   - `cms_index_index` — homepage
   - `catalog_product_view` — product detail page
   - `catalog_category_view` — category page
   - `checkout_cart_index` — cart page
   - `customer_account_index` — customer dashboard
   - Custom: `{route_id}_{folder}_{action}` from the controller

3. **Create or merge layout XML** — place at `view/{area}/layout/{handle}.xml`.
   - If the file exists, merge new elements into the existing structure (add blocks/containers, do not duplicate the root `<page>` element).
   - If the file does not exist, create it with the full XML structure including copyright header and XSD.

4. **Create ViewModel if needed** — place at `ViewModel/{Name}.php`. Follow the ViewModel template from section 5. Attach it to the block in layout XML.

5. **Create template if needed** — place at `view/{area}/templates/{path}.phtml`. Follow the template rules from section 6. Include `$block` and `$escaper` declarations. Escape all output.

6. **Create RequireJS config if needed** — place at `view/{area}/requirejs-config.js`. If the file exists, merge the new config entries (add to `map`, `paths`, `config/mixins`, etc.).

7. **Remind the user** to run post-generation commands (see section 12).

**Merge logic for existing files:**
- Layout XML — merge new elements inside the existing `<body>` or `<head>`. Never duplicate the `<page>` root element or overwrite existing blocks without confirmation.
- `requirejs-config.js` — add new entries to the existing `config` object.
- Templates — create new files only; never overwrite existing templates without confirmation.

## 11. Anti-Patterns

| Anti-Pattern | Problem | Fix |
|-------------|---------|-----|
| Custom Block class for template data | Unnecessary inheritance chain, harder to test | Use a ViewModel implementing `ArgumentInterface` |
| Missing `$escaper` usage in template | XSS vulnerability | Escape all output with appropriate `$escaper` method |
| `ObjectManager` in phtml template | Hidden dependency, untestable | Use ViewModel for all data/logic |
| Wrong XSD in layout root | Validation errors, unexpected behavior | Use `page_configuration.xsd` for `<page>`, `page_layout.xsd` for `<layout>` |
| Business logic in phtml template | Untestable, violates separation of concerns | Move logic to ViewModel |
| Block without a `name` attribute | Cannot reference, move, or remove the block | Always set a unique `name` |
| Inline `<style>` or `<script>` tags | Bypasses Magento's asset pipeline, CSP issues | Use `<head>` assets or RequireJS |
| Using `<action>` in layout XML | Deprecated since Magento 2.0 | Use `<arguments>` or a ViewModel |
| Override when extend would work | Breaks on Magento upgrades | Prefer layout extend over override |

## 12. Post-Generation Steps

After generating layout/template code, remind the user to run:

```bash
bin/magento cache:flush
```

For theme changes (template overrides, layout in theme):
```bash
bin/magento cache:flush
bin/magento setup:static-content:deploy -f
```

If the module was not yet enabled:
```bash
bin/magento module:enable {Vendor}_{ModuleName}
bin/magento setup:upgrade
bin/magento cache:flush
```

**Verification:**
- Check the page source for the expected block HTML
- Check `var/log/system.log` for layout XML errors
- For head assets, verify they appear in the `<head>` section of the page source
