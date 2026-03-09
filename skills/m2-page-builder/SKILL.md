---
name: m2-page-builder
description: >
  Generate custom Magento 2 Page Builder content types including content type XML,
  UI component forms, preview components, master templates, and appearance configurations.
  Use this skill when the user asks to create a custom Page Builder content type,
  extend Page Builder, add a Page Builder component, or create custom appearances.
  Trigger on: "page builder", "content type", "Page Builder component",
  "pagebuilder", "custom content type", "page builder form",
  "preview component", "master template", "appearance",
  "content_type.xml", "Page Builder widget", "drag and drop content",
  "CMS editor component", "visual editor block", "page builder extension".
---

# Magento 2 Page Builder Content Type Generator

You are a Magento 2 Page Builder specialist. Generate custom content types with XML configuration, UI component forms, KnockoutJS preview components, and master (storefront) templates under existing modules in `app/code/{Vendor}/{ModuleName}/`.

Follow the coding conventions and file headers defined in `.claude/skills/_shared/conventions.md` and `.claude/skills/m2-module/SKILL.md`. Do not duplicate those conventions here.

**Prerequisites:** Module must exist (see `_shared/conventions.md`). If not, use `/m2-module` first. The module must require `magento/module-page-builder`.

## 1. Decision Tree

**Use a Page Builder content type when:**
- Content editors need a drag-and-drop visual component with a live preview in the admin
- The component has multiple configurable fields (text, images, alignment, etc.)
- The content type may have multiple appearances (layout variants)
- You need a reusable visual building block for CMS pages, blocks, or dynamic blocks

**Use a CMS widget (`/m2-widget`) instead when:**
- The component is inserted via WYSIWYG directive syntax (`{{widget ...}}`)
- No visual drag-and-drop preview is needed
- The component has simple parameters (text, select)

**Use a static block instead when:**
- The content is one-off HTML managed by CMS editors, not a reusable typed component

## 2. Gather Requirements

Before generating any files, collect the following from the user.

**Required (ask if not provided):**
- **Module name** — `Vendor_ModuleName`
- **Content type name** — machine name in snake_case (e.g., `custom_banner`, `testimonial`)
- **Content type label** — human-readable name (e.g., "Custom Banner", "Testimonial")
- **Fields** — list of editable fields (e.g., heading, description, image, link)

**Optional (use defaults if not specified):**
- **Group** — Page Builder panel group: `layout`, `elements`, `media`, `add_content` (default: `add_content`)
- **Appearances** — layout variants (default: single `default` appearance)
- **Icon** — custom icon class (default: `icon-pagebuilder-{name}`)
- **Sort order** — position within the group (default: `100`)
- **Is system** — whether this is a system content type (default: `false`)

## 3. Naming Conventions

| Concept | Convention | Example |
|---------|-----------|---------|
| Content type name | `{snake_case}` | `custom_banner` |
| Content type XML | `view/adminhtml/pagebuilder/content_type/{name}.xml` | `content_type/custom_banner.xml` |
| UI form component | `view/adminhtml/ui_component/pagebuilder_{name}_form.xml` | `pagebuilder_custom_banner_form.xml` |
| Preview component | `view/adminhtml/web/js/content-type/{name}/preview.js` | `js/content-type/custom_banner/preview.js` |
| Preview template | `view/adminhtml/web/template/content-type/{name}/default/preview.html` | `template/content-type/custom_banner/default/preview.html` |
| Master template | `view/adminhtml/web/template/content-type/{name}/default/master.html` | `template/content-type/custom_banner/default/master.html` |
| Appearance name | lowercase, no spaces | `default`, `collage-left` |

## 4. File Structure Overview

```
app/code/{Vendor}/{ModuleName}/
├── view/adminhtml/
│   ├── pagebuilder/
│   │   └── content_type/
│   │       └── {name}.xml                           # Content type definition
│   ├── ui_component/
│   │   └── pagebuilder_{name}_form.xml              # Admin edit form
│   └── web/
│       ├── css/source/
│       │   └── content-type/{name}/_default.less     # Admin preview styles
│       ├── js/content-type/{name}/
│       │   └── preview.js                            # Preview KnockoutJS component
│       └── template/content-type/{name}/default/
│           ├── preview.html                          # Admin preview template
│           └── master.html                           # Storefront output template
├── view/frontend/
│   ├── layout/
│   │   └── default.xml                              # (optional) Frontend-specific layout
│   └── web/css/source/
│       └── content-type/{name}/_default.less         # Frontend styles
└── etc/
    └── module.xml                                   # Must depend on Magento_PageBuilder
```

## 5. Content Type XML — `view/adminhtml/pagebuilder/content_type/{name}.xml`

```xml
<?xml version="1.0"?>
<!--
/**
 * Copyright © Monsoon Consulting. All rights reserved.
 * See LICENSE_MONSOON.txt for license details.
 */
-->
<config xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
        xsi:noNamespaceSchemaLocation="urn:magento:module:Magento_PageBuilder:etc/content_type.xsd">
    <type name="{name}"
          label="{Label}"
          menu_section="{group}"
          component="Magento_PageBuilder/js/content-type"
          preview_component="{Vendor}_{ModuleName}/js/content-type/{name}/preview"
          master_component="Magento_PageBuilder/js/content-type/master"
          form="pagebuilder_{name}_form"
          icon="icon-pagebuilder-{name}"
          sortOrder="{sort_order}"
          translate="label">
        <children default_policy="deny"/>
        <appearances>
            <appearance name="default"
                        default="true"
                        preview_template="{Vendor}_{ModuleName}/content-type/{name}/default/preview"
                        master_template="{Vendor}_{ModuleName}/content-type/{name}/default/master"
                        reader="Magento_PageBuilder/js/master-format/read/configurable">
                <elements>
                    <element name="main">
                        <style name="text_align" source="text_align"/>
                        <style name="border" source="border_style" converter="Magento_PageBuilder/js/converter/style/border-style"/>
                        <style name="border-color" source="border_color"/>
                        <style name="border-width" source="border_width" converter="Magento_PageBuilder/js/converter/style/border-width"/>
                        <style name="border-radius" source="border_radius" converter="Magento_PageBuilder/js/converter/style/remove-px"/>
                        <style name="margin" storage_key="margins" reader="Magento_PageBuilder/js/property/margins" converter="Magento_PageBuilder/js/converter/style/margins"/>
                        <style name="padding" storage_key="paddings" reader="Magento_PageBuilder/js/property/paddings" converter="Magento_PageBuilder/js/converter/style/paddings"/>
                        <static_style name="display" value="inline-block"/>
                        <static_style name="width" value="100%"/>
                        <attribute name="name" source="data-content-type"/>
                        <attribute name="appearance" source="data-appearance"/>
                        <css name="css_classes"/>
                    </element>
                    <element name="heading">
                        <html name="heading_text" converter="Magento_PageBuilder/js/converter/html/tag-escaper"/>
                        <style name="heading_type" virtual="true"/>
                    </element>
                    <element name="description">
                        <html name="description_text" converter="Magento_PageBuilder/js/converter/html/tag-escaper"/>
                    </element>
                </elements>
            </appearance>
        </appearances>
    </type>
</config>
```

For the full content type XML schema reference (elements, style properties, converters, attribute types), see `references/content-type-schema.md`.

## 6. UI Component Form — `view/adminhtml/ui_component/pagebuilder_{name}_form.xml`

```xml
<?xml version="1.0"?>
// Standard file header — see _shared/conventions.md
<form xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
      xsi:noNamespaceSchemaLocation="urn:magento:module:Magento_Ui:etc/ui_configuration.xsd">
    <argument name="data" xsi:type="array">
        <item name="js_config" xsi:type="array">
            <item name="provider" xsi:type="string">pagebuilder_{name}_form.pagebuilder_{name}_form_data_source</item>
        </item>
        <item name="label" xsi:type="string" translate="true">{Label}</item>
    </argument>
    <settings>
        <namespace>pagebuilder_{name}_form</namespace>
        <deps>
            <dep>pagebuilder_{name}_form.pagebuilder_{name}_form_data_source</dep>
        </deps>
    </settings>
    <dataSource name="pagebuilder_{name}_form_data_source">
        <argument name="data" xsi:type="array">
            <item name="js_config" xsi:type="array">
                <item name="component" xsi:type="string">Magento_PageBuilder/js/form/provider</item>
            </item>
        </argument>
    </dataSource>
    <fieldset name="appearance_fieldset" sortOrder="10"
              component="Magento_PageBuilder/js/form/element/dependent-fieldset">
        <settings>
            <label translate="true">Appearance</label>
            <additionalClasses>
                <class name="admin__fieldset-visual-select-large">true</class>
            </additionalClasses>
            <collapsible>false</collapsible>
            <opened>true</opened>
        </settings>
        <field name="appearance" formElement="select" sortOrder="10"
               component="Magento_PageBuilder/js/form/element/visual-select">
            <settings>
                <dataType>text</dataType>
                <validation>
                    <rule name="required-entry" xsi:type="boolean">true</rule>
                </validation>
            </settings>
            <formElements>
                <select>
                    <settings>
                        <options class="Magento\PageBuilder\Model\Config\ContentType\AdditionalData\Provider\Appearance">
                            <argument name="contentType" xsi:type="string">{name}</argument>
                        </options>
                    </settings>
                </select>
            </formElements>
        </field>
    </fieldset>
    <fieldset name="general" sortOrder="20">
        <settings>
            <label translate="true">Content</label>
        </settings>
        <field name="heading_text" formElement="input" sortOrder="10">
            <settings>
                <label translate="true">Heading</label>
                <dataType>text</dataType>
            </settings>
        </field>
        <field name="heading_type" formElement="select" sortOrder="20">
            <settings>
                <label translate="true">Heading Type</label>
                <dataType>text</dataType>
            </settings>
            <formElements>
                <select>
                    <settings>
                        <options>
                            <option name="h1" value="h1"><label translate="true">H1</label></option>
                            <option name="h2" value="h2"><label translate="true">H2</label></option>
                            <option name="h3" value="h3"><label translate="true">H3</label></option>
                            <option name="h4" value="h4"><label translate="true">H4</label></option>
                        </options>
                    </settings>
                </select>
            </formElements>
        </field>
        <field name="description_text" formElement="wysiwyg" sortOrder="30">
            <settings>
                <label translate="true">Description</label>
                <dataType>text</dataType>
                <wysiwygConfigData>
                    <item name="is_pagebuilder_enabled" xsi:type="boolean">false</item>
                </wysiwygConfigData>
            </settings>
        </field>
    </fieldset>
    <fieldset name="advanced" sortOrder="90">
        <settings>
            <label translate="true">Advanced</label>
        </settings>
        <field name="css_classes" formElement="input" sortOrder="10">
            <settings>
                <dataType>text</dataType>
                <label translate="true">CSS Classes</label>
            </settings>
        </field>
        <container name="borders_and_margins" sortOrder="20"
                   component="Magento_PageBuilder/js/form/element/borders-and-margins"/>
    </fieldset>
</form>
```

### Field Types Reference

| Field Type | `formElement` | Use For |
|-----------|--------------|---------|
| Text input | `input` | Headings, short text, CSS classes |
| Textarea | `textarea` | Descriptions, plain text content |
| WYSIWYG | `wysiwyg` | Rich text content |
| Select | `select` | Heading type, alignment, predefined options |
| Image uploader | `imageUploader` | Product images, background images |
| Color picker | `colorPicker` | Background color, text color |
| Checkbox | `checkbox` | Boolean toggle fields |
| URL input | `urlInput` | Link URL with page/category/product picker |

## 7. Preview Component — `view/adminhtml/web/js/content-type/{name}/preview.js`

```javascript
/**
 * Copyright © Monsoon Consulting. All rights reserved.
 * See LICENSE_MONSOON.txt for license details.
 */

define([
    'Magento_PageBuilder/js/content-type/preview'
], function (PreviewBase) {
    'use strict';

    /**
     * @param {Object} contentType
     * @param {Object} config
     * @param {Object} observableUpdater
     */
    function Preview(contentType, config, observableUpdater) {
        PreviewBase.call(this, contentType, config, observableUpdater);
    }

    Preview.prototype = Object.create(PreviewBase.prototype);
    Preview.prototype.constructor = Preview;

    return Preview;
});
```

For content types that need custom preview behavior (dynamic data loading, complex rendering), extend the prototype with custom methods. For simple content types, the base `PreviewBase` is sufficient.

## 8. Preview Template — `view/adminhtml/web/template/content-type/{name}/default/preview.html`

```html
<!--
/**
 * Copyright © Monsoon Consulting. All rights reserved.
 * See LICENSE_MONSOON.txt for license details.
 */
-->
<div class="pagebuilder-content-type" event="{ mouseover: onMouseOver, mouseout: onMouseOut }"
     attr="data.main.attributes" ko-style="data.main.style" css="data.main.css">
    <render args="getOptions().template"/>
    <div class="element-children" if="isContainer()">
        <!-- ko foreach: getChildren() -->
        <div class="pagebuilder-content-type-wrapper" ko-style="$parent.getChildWrapperStyles($data)">
            <render args="$data.getOptions().template"/>
        </div>
        <!-- /ko -->
    </div>
    <div if="data.heading.html()">
        <render args="'Magento_PageBuilder/content-type/heading/default/preview'" with="{ data: { main: { html: data.heading.html, style: ko.observable({}), attributes: ko.observable({}), css: ko.observable({}) } } }"/>
    </div>
    <div if="data.description.html()">
        <div attr="data.description.attributes" ko-style="data.description.style"
             css="data.description.css" html="data.description.html"/>
    </div>
</div>
```

Preview templates use KnockoutJS bindings. The `data` object is populated from the content type XML element definitions.

## 9. Master Template — `view/adminhtml/web/template/content-type/{name}/default/master.html`

```html
<!--
/**
 * Copyright © Monsoon Consulting. All rights reserved.
 * See LICENSE_MONSOON.txt for license details.
 */
-->
<div attr="data.main.attributes" ko-style="data.main.style" css="data.main.css">
    <if args="data.heading.html()">
        <render args="'Magento_PageBuilder/content-type/heading/default/master'" with="{ data: { main: { html: data.heading.html, style: ko.observable({}), attributes: ko.observable({}), css: ko.observable({}) } } }"/>
    </if>
    <if args="data.description.html()">
        <div attr="data.description.attributes" ko-style="data.description.style"
             css="data.description.css" html="data.description.html"/>
    </if>
</div>
```

The master template generates the final HTML saved to the database and rendered on the storefront. It uses the same data bindings as the preview but without admin-specific UI elements (toolbars, overlays).

## 10. Extending Existing Content Types

### Adding a New Appearance

To add a new appearance to an existing content type (e.g., adding a `collage` appearance to `banner`):

```xml
<?xml version="1.0"?>
// Standard file header — see _shared/conventions.md
<config xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
        xsi:noNamespaceSchemaLocation="urn:magento:module:Magento_PageBuilder:etc/content_type.xsd">
    <type name="banner">
        <appearances>
            <appearance name="custom-collage"
                        preview_template="{Vendor}_{ModuleName}/content-type/banner/custom-collage/preview"
                        master_template="{Vendor}_{ModuleName}/content-type/banner/custom-collage/master"
                        reader="Magento_PageBuilder/js/master-format/read/configurable">
                <elements>
                    <!-- Same element structure as existing appearances -->
                </elements>
            </appearance>
        </appearances>
    </type>
</config>
```

Create the corresponding preview and master templates in your module under the appearance subdirectory.

## 11. Generation Rules

Follow this sequence when generating a custom content type:

1. **Verify the module exists** — check `registration.php`.

2. **Check module dependency** — ensure `Magento_PageBuilder` is listed in `etc/module.xml` sequence. If not, add it.

3. **Create content type XML** — `view/adminhtml/pagebuilder/content_type/{name}.xml` with elements, appearances, and style/attribute converters.

4. **Create UI component form** — `view/adminhtml/ui_component/pagebuilder_{name}_form.xml` with fields matching the content type elements.

5. **Create preview component JS** — `view/adminhtml/web/js/content-type/{name}/preview.js`. Use base `PreviewBase` for simple types.

6. **Create preview template** — `view/adminhtml/web/template/content-type/{name}/default/preview.html` with KnockoutJS bindings.

7. **Create master template** — `view/adminhtml/web/template/content-type/{name}/default/master.html` for storefront output.

8. **Create admin preview LESS** (optional) — `view/adminhtml/web/css/source/content-type/{name}/_default.less`.

9. **Create frontend LESS** (optional) — `view/frontend/web/css/source/content-type/{name}/_default.less`.

10. **Remind the user** to run post-generation commands.

## 12. Anti-Patterns

**Using PHP rendering instead of master templates.**
Page Builder content types use KnockoutJS master templates to generate storefront HTML. The HTML is saved to the database as static markup. Do not rely on server-side PHP rendering for the content output.

**Nesting Page Builder inside Page Builder fields.**
Do not set `is_pagebuilder_enabled` to `true` on WYSIWYG fields inside a Page Builder content type form. Nested Page Builder causes UI and saving issues.

**Mismatched element names between XML and templates.**
The `name` attribute on `<element>` entries in the content type XML must match the data bindings in preview and master templates (`data.{element_name}`). Mismatches cause blank fields.

**Forgetting the `data-content-type` attribute on the main element.**
The main element must include `<attribute name="name" source="data-content-type"/>`. Without it, Page Builder cannot identify the content type when reading saved content.

**Missing `data-appearance` attribute.**
Each appearance requires `<attribute name="appearance" source="data-appearance"/>` on the main element. This tells Page Builder which appearance template to use when rendering.

**Overriding core content types entirely.**
Use appearance extensions or plugins to modify existing content types. Replacing core XML definitions breaks upgrades.

## 13. Post-Generation Steps

After generating the content type, remind the user to run:

```bash
bin/magento setup:upgrade
bin/magento setup:di:compile
bin/magento setup:static-content:deploy -f
bin/magento cache:flush
```

If the module was not yet enabled:
```bash
bin/magento module:enable {Vendor}_{ModuleName}
bin/magento setup:upgrade
bin/magento setup:di:compile
bin/magento setup:static-content:deploy -f
bin/magento cache:flush
```

**Verification:**
- Open a CMS page or block editor in the admin panel
- The new content type should appear in the Page Builder panel under the configured group
- Drag the content type onto the stage and verify the preview renders
- Save the page and verify the storefront output matches the master template
