---
name: m2-widget
description: >
  Generate Magento 2 CMS widgets including widget.xml configuration,
  BlockInterface implementation, widget parameters, and phtml templates.
  Use this skill whenever the user asks to create a CMS widget, page builder widget,
  widget block, or configurable content block for WYSIWYG editors.
  Trigger on: "widget", "widget.xml", "BlockInterface", "CMS widget",
  "page builder widget", "widget parameter", "WYSIWYG widget",
  "create widget", "add widget", "widget block", "widget instance",
  "content widget", "configurable block", "widget directive",
  "reusable content block", "editor widget",
  "content block", "inline block", "WYSIWYG block".
---

# Magento 2 CMS Widget Generator

You are a Magento 2 widget specialist. Generate widget.xml configuration, BlockInterface block classes, and phtml templates under existing modules in `app/code/{Vendor}/{ModuleName}/`.

Follow the coding conventions and file headers defined in `.claude/skills/_shared/conventions.md` and `.claude/skills/m2-module/SKILL.md`. Do not duplicate those conventions here.

**Prerequisites:** Module must exist (see `_shared/conventions.md`). If not, use `/m2-module` first.

## 1. Decision Tree

**Use a widget when:**
- CMS editors need to insert reusable, configurable content blocks via WYSIWYG or layout XML
- The content block requires admin-configurable parameters (title, limit, category, etc.)
- The same block appears on multiple CMS pages or static blocks with different settings
- You need a Page Builder-compatible content type with a simple parameter form

**Use a regular block instead when:**
- The block renders fixed template output with no CMS editor configurability
- Configuration comes from system config (`system.xml`) rather than per-instance parameters
- The block is only placed via layout XML, never inserted into CMS content

**Use a UI component instead when:**
- You are building admin grids, forms, or data management interfaces — not CMS content

## 2. Gather Requirements

Before generating any files, collect the following from the user.

**Required (ask if not provided):**
- **Module name** — `Vendor_ModuleName`
- **Widget label** — human-readable name shown in the widget chooser (e.g., "Featured Products Slider")
- **Widget description** — short explanation of the widget's purpose

**Optional (use defaults if not specified):**
- **Widget parameters** — default: `title` (text, required) and `content` (textarea, optional)
- **Widget class name** — default: derived from widget label (e.g., `FeaturedProductsSlider`)
- **Template name** — default: derived from class name in snake_case (e.g., `featured_products_slider.phtml`)

## 3. Naming Conventions

| Concept | Convention | Example |
|---------|-----------|---------|
| Widget ID | `{vendor}_{modulename}_{widget_snake}` | `acme_content_featured_slider` |
| Block class | `Block\Widget\{WidgetName}` | `Block\Widget\FeaturedProductsSlider` |
| Template path | `view/frontend/templates/widget/{name}.phtml` | `view/frontend/templates/widget/featured_products_slider.phtml` |
| widget.xml | `etc/widget.xml` | `etc/widget.xml` |

## 4. Templates

### 4.1 widget.xml — `etc/widget.xml`

```xml
<?xml version="1.0"?>
<!--
/**
 * Copyright © Monsoon Consulting. All rights reserved.
 * See LICENSE_MONSOON.txt for license details.
 */
-->
<widgets xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:noNamespaceSchemaLocation="urn:magento:module:Magento_Widget:etc/widget.xsd">
    <widget id="{vendor}_{modulename}_{widget_id}"
            class="{Vendor}\{ModuleName}\Block\Widget\{WidgetName}"
            placeholder_image="Magento_Widget::placeholder.gif">
        <label>{Widget Label}</label>
        <description>{Widget Description}</description>
        <parameters>
            <parameter name="title" xsi:type="text" required="true" visible="true" sort_order="10">
                <label>Title</label>
            </parameter>
            <parameter name="content" xsi:type="textarea" required="false" visible="true" sort_order="20">
                <label>Content</label>
            </parameter>
        </parameters>
    </widget>
</widgets>
```

If `etc/widget.xml` already exists, append the new `<widget>` element inside the existing `<widgets>` root — do not create a second file.

### 4.2 Widget Block Class — `Block/Widget/{WidgetName}.php`

```php
<?php
/**
 * Copyright © Monsoon Consulting. All rights reserved.
 * See LICENSE_MONSOON.txt for license details.
 */

declare(strict_types=1);

namespace {Vendor}\{ModuleName}\Block\Widget;

use Magento\Framework\View\Element\Template;
use Magento\Widget\Block\BlockInterface;

class {WidgetName} extends Template implements BlockInterface
{
    protected $_template = '{Vendor}_{ModuleName}::widget/{widget_template}.phtml';

    public function getTitle(): string
    {
        return (string) $this->getData('title');
    }

    public function getContent(): string
    {
        return (string) $this->getData('content');
    }
}
```

Add a typed getter method for each widget parameter. All getters cast to the appropriate PHP type and read from `$this->getData('{parameter_name}')`.

### 4.3 phtml Template — `view/frontend/templates/widget/{name}.phtml`

```php
<?php
// Standard file header — see _shared/conventions.md
declare(strict_types=1);

/** @var {Vendor}\{ModuleName}\Block\Widget\{WidgetName} $block */
?>
<?php if ($block->getTitle()): ?>
    <div class="widget {widget-css-class}">
        <h2><?= $block->escapeHtml($block->getTitle()) ?></h2>
        <?php if ($block->getContent()): ?>
            <div class="widget-content">
                <?= $block->escapeHtml($block->getContent()) ?>
            </div>
        <?php endif; ?>
    </div>
<?php endif; ?>
```

Always escape output with `$block->escapeHtml()` for text or `$block->escapeUrl()` for URLs. If the parameter contains HTML that should render, use `$block->getContent()` without escaping but document the security implications.

### 4.4 Parameter Types Reference

| Type | XML `xsi:type` | Description |
|------|----------------|-------------|
| `text` | `text` | Simple single-line text input |
| `textarea` | `textarea` | Multiline text input |
| `select` | `select` | Dropdown with predefined options |
| `multiselect` | `multiselect` | Multiple selection list |
| `block` | `block` | Block chooser (references another CMS block) |
| `conditions` | `conditions` | Condition combiner for catalog/sales rules |
| `label` | `label` | Read-only display text (no user input) |

**Select parameter with source_model:**

```xml
<parameter name="display_mode" xsi:type="select" required="true" visible="true" sort_order="30">
    <label>Display Mode</label>
    <options>
        <option name="grid" value="grid">
            <label>Grid</label>
        </option>
        <option name="list" value="list">
            <label>List</label>
        </option>
    </options>
</parameter>
```

**Select parameter with a source model class:**

```xml
<parameter name="category_id" xsi:type="select" required="true" visible="true"
           source_model="{Vendor}\{ModuleName}\Model\Config\Source\{SourceModel}" sort_order="40">
    <label>Category</label>
</parameter>
```

The source model must implement `Magento\Framework\Data\OptionSourceInterface` with a `toOptionArray()` method.

**Block chooser parameter:**

```xml
<parameter name="block_id" xsi:type="block" required="true" visible="true" sort_order="50">
    <label>CMS Block</label>
    <block class="Magento\Cms\Block\Adminhtml\Block\Widget\Chooser">
        <data>
            <item name="button" xsi:type="array">
                <item name="open" xsi:type="string">Select Block...</item>
            </item>
        </data>
    </block>
</parameter>
```

### 4.5 Widget Directive Syntax (CMS Content)

Widgets inserted via the WYSIWYG editor use directive syntax in CMS page/block content:

```
{{widget type="{Vendor}\{ModuleName}\Block\Widget\{WidgetName}" title="Hello" content="World"}}
```

Widgets can also be placed via layout XML:

```xml
<block class="{Vendor}\{ModuleName}\Block\Widget\{WidgetName}" name="{widget_name}">
    <arguments>
        <argument name="title" xsi:type="string">Hello</argument>
    </arguments>
</block>
```

## 5. Generation Rules

Follow this sequence when generating a widget:

1. **Verify the module exists** — check that `app/code/{Vendor}/{ModuleName}/registration.php` exists. If not, instruct the user to scaffold it first with `/m2-module`.

2. **Check module dependency** — ensure `Magento_Widget` is listed as a dependency in `etc/module.xml`. If not, add it to the `<sequence>` element.

3. **Create or update `etc/widget.xml`** — if the file exists, append the new `<widget>` element inside `<widgets>`. If it does not exist, create it with the full XML structure including copyright header.

4. **Create the Block class** — `Block/Widget/{WidgetName}.php` implementing `BlockInterface`. Add a typed getter for each parameter.

5. **Create the phtml template** — `view/frontend/templates/widget/{name}.phtml` with proper escaping and block type hint.

6. **Remind the user** to run post-generation commands.

## 6. Anti-Patterns

**Business logic in the widget block class.**
Widget blocks should only provide data access via getters. Delegate complex logic (database queries, API calls, calculations) to a ViewModel or service class injected via constructor.

**Missing BlockInterface implementation.**
The widget block class must implement `Magento\Widget\Block\BlockInterface`. Without it, the widget will not appear in the CMS widget chooser and cannot be inserted via WYSIWYG.

**Hardcoded data instead of parameters.**
If a value should be configurable per widget instance, expose it as a `<parameter>` in widget.xml. Hardcoded values defeat the purpose of widgets as reusable, editor-configurable components.

**Not escaping output in templates.**
Always use `$block->escapeHtml()`, `$block->escapeUrl()`, or `$block->escapeHtmlAttr()` in phtml templates. Unescaped widget parameter values are an XSS vector since CMS editors control the input.

**Using ObjectManager in the block class.**
Inject all dependencies via constructor. Never call `ObjectManager::getInstance()` inside a widget block.

**Overloading a single widget with too many parameters.**
If a widget has more than 8-10 parameters, consider splitting it into multiple focused widgets. Complex parameter forms are hard for CMS editors to use correctly.

## 7. Post-Generation Steps

Follow `.claude/skills/_shared/post-generation.md` for: layout XML / templates / config changes.

Widgets do **not** require `setup:di:compile` unless the block class introduces dependencies that need compilation (proxies, factories). In most cases, a cache flush is sufficient.

To verify the widget is registered, go to **Content > Pages > Edit Page > Insert Widget** in the admin panel. The new widget should appear in the widget type dropdown.
