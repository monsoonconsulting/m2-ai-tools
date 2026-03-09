# Content Type XML Schema Reference

The content type XML file (`view/adminhtml/pagebuilder/content_type/{name}.xml`) defines the structure, data bindings, and appearances for a Page Builder content type.

## Top-Level `<type>` Attributes

| Attribute | Required | Description |
|-----------|----------|-------------|
| `name` | Yes | Unique machine name (snake_case) |
| `label` | Yes | Human-readable label shown in panel |
| `menu_section` | No | Panel group: `layout`, `elements`, `media`, `add_content` |
| `component` | Yes | JS component path (usually `Magento_PageBuilder/js/content-type`) |
| `preview_component` | Yes | JS preview class path |
| `master_component` | No | JS master class (default: `Magento_PageBuilder/js/content-type/master`) |
| `form` | Yes | UI component form name |
| `icon` | No | CSS icon class for the panel |
| `sortOrder` | No | Position within panel group |
| `is_system` | No | System types cannot be removed (`true`/`false`) |
| `translate` | No | Attributes to translate (e.g., `label`) |

## `<children>` Element

Controls whether this content type accepts child content types.

```xml
<children default_policy="deny"/>          <!-- No children allowed -->
<children default_policy="allow"/>         <!-- All children allowed -->
<children default_policy="deny">           <!-- Only specific children -->
    <child name="text" policy="allow"/>
    <child name="heading" policy="allow"/>
</children>
```

## `<appearances>` and `<appearance>`

Each content type has one or more appearances (layout variants).

| Attribute | Required | Description |
|-----------|----------|-------------|
| `name` | Yes | Appearance identifier |
| `default` | No | Set `true` for the default appearance |
| `preview_template` | Yes | KnockoutJS template path for admin preview |
| `master_template` | Yes | KnockoutJS template path for storefront output |
| `reader` | Yes | JS reader class (usually `configurable`) |

## `<elements>` and `<element>`

Elements define the data-to-DOM mapping for an appearance.

### Child Nodes of `<element>`

| Node | Description |
|------|-------------|
| `<style>` | Maps a data field to a CSS style property |
| `<static_style>` | Sets a fixed CSS style value |
| `<attribute>` | Maps a data field to an HTML attribute |
| `<static_attribute>` | Sets a fixed HTML attribute value |
| `<html>` | Maps a data field to inner HTML content |
| `<css>` | Maps a data field to CSS class names |
| `<tag>` | Maps a data field to the HTML tag name |

### `<style>` Attributes

```xml
<style name="{css-property}" source="{data_field}" converter="{js/converter/path}"
       persistence_mode="read|write|readwrite" storage_key="{key}" reader="{js/reader/path}"/>
```

### Common Converters

| Converter | Purpose |
|-----------|---------|
| `Magento_PageBuilder/js/converter/style/border-style` | Border style values |
| `Magento_PageBuilder/js/converter/style/border-width` | Appends `px` to border width |
| `Magento_PageBuilder/js/converter/style/remove-px` | Removes `px` suffix |
| `Magento_PageBuilder/js/converter/style/margins` | Margin shorthand |
| `Magento_PageBuilder/js/converter/style/paddings` | Padding shorthand |
| `Magento_PageBuilder/js/converter/style/color` | Color value handling |
| `Magento_PageBuilder/js/converter/style/background-image` | URL wrapping for backgrounds |
| `Magento_PageBuilder/js/converter/html/tag-escaper` | HTML entity escaping |
