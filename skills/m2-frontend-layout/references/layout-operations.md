# Layout Operations Reference

Complete reference for all Magento 2 layout XML operations.

## `<block>`

Defines a UI output element backed by a PHP class and (usually) a template.

```xml
<block class="Magento\Framework\View\Element\Template"
       name="vendor.module.block_name"
       template="Vendor_Module::path/to/template.phtml"
       as="alias"
       before="-"
       after="other.block.name"
       ifconfig="section/group/field"
       cacheable="true"
       ttl="3600"
       group="detailed_info">
    <arguments>
        <argument name="view_model" xsi:type="object">Vendor\Module\ViewModel\MyViewModel</argument>
    </arguments>
</block>
```

### Block attributes

| Attribute | Required | Description |
|-----------|----------|-------------|
| `class` | Yes | PHP class (usually `Magento\Framework\View\Element\Template` with a ViewModel) |
| `name` | Yes | Unique identifier — used for referencing, moving, removing |
| `template` | No | phtml template in `Module::path.phtml` format |
| `as` | No | Alias for `getChildHtml('alias')` calls from parent block |
| `before` | No | Position before another block. Use `-` for first position |
| `after` | No | Position after another block. Use `-` for last position |
| `ifconfig` | No | Config path — block renders only if this config value is truthy |
| `cacheable` | No | Set `false` to mark the block as uncacheable (disables FPC for the page) |
| `ttl` | No | ESI block TTL in seconds (Varnish only) |
| `group` | No | Groups block into a named set (e.g., `detailed_info` on product page) |

## `<container>`

Structural wrapper element. Renders an HTML tag around its children. Has no PHP class or template.

```xml
<container name="some.container"
           htmlTag="div"
           htmlClass="my-container-class"
           htmlId="my-container-id"
           label="My Container"
           before="-"
           after="other.element">
    <!-- child blocks and containers go here -->
</container>
```

### Container attributes

| Attribute | Required | Description |
|-----------|----------|-------------|
| `name` | Yes | Unique identifier |
| `htmlTag` | No | HTML wrapper tag (`div`, `section`, `aside`, `header`, `footer`, `main`, `nav`, `ul`, `ol`) |
| `htmlClass` | No | CSS class on the wrapper tag |
| `htmlId` | No | HTML id on the wrapper tag |
| `label` | No | Descriptive label (visible in layout debug mode) |
| `before` / `after` | No | Positioning (same as block) |

**Note:** If `htmlTag` is omitted, the container renders no wrapper — children are rendered directly.

## `<referenceBlock>`

Modify an existing block by name.

### Change template

```xml
<referenceBlock name="existing.block.name"
                template="Vendor_Module::custom/template.phtml"/>
```

### Remove a block

```xml
<referenceBlock name="existing.block.name" remove="true"/>
```

### Add arguments to an existing block

```xml
<referenceBlock name="existing.block.name">
    <arguments>
        <argument name="view_model" xsi:type="object">Vendor\Module\ViewModel\Custom</argument>
    </arguments>
</referenceBlock>
```

### Add child blocks

```xml
<referenceBlock name="existing.block.name">
    <block class="Magento\Framework\View\Element\Template"
           name="vendor.module.child"
           template="Vendor_Module::child.phtml"/>
</referenceBlock>
```

### Change CSS class on block's wrapper

```xml
<referenceBlock name="existing.block.name">
    <arguments>
        <argument name="css_class" xsi:type="string">custom-class</argument>
    </arguments>
</referenceBlock>
```

## `<referenceContainer>`

Modify an existing container by name.

### Add blocks into a container

```xml
<referenceContainer name="content">
    <block class="Magento\Framework\View\Element\Template"
           name="vendor.module.my_block"
           template="Vendor_Module::my_template.phtml"/>
</referenceContainer>
```

### Remove a container

```xml
<referenceContainer name="some.container" remove="true"/>
```

### Change container HTML attributes

```xml
<referenceContainer name="some.container"
                    htmlTag="section"
                    htmlClass="new-class"
                    htmlId="new-id"/>
```

## `<move>`

Move an element (block or container) to a different parent and/or position.

```xml
<move element="block.to.move"
      destination="target.container"
      before="-"
      after="other.block"/>
```

### Move attributes

| Attribute | Required | Description |
|-----------|----------|-------------|
| `element` | Yes | Name of the block or container to move |
| `destination` | Yes | Name of the target container or block |
| `before` | No | Place before this element. Use `-` for first position |
| `after` | No | Place after this element. Use `-` for last position |
| `as` | No | New alias in the destination parent |

**Examples:**

```xml
<!-- Move sidebar block to main content area -->
<move element="catalog.leftnav" destination="content" before="-"/>

<!-- Move block to end of footer -->
<move element="my.block" destination="footer" after="-"/>
```

## `<update>`

Include another layout handle's instructions.

```xml
<update handle="customer_account"/>
```

This pulls in all layout instructions from the `customer_account` handle. Useful for:
- Sharing common layout structure across multiple handles
- Including standard page sections (e.g., account navigation)

## `<arguments>` and `<argument>`

Pass data to blocks via arguments. Arguments are accessible in templates via `$block->getData('arg_name')` or `$block->getArgName()` (magic getter).

### Argument types (`xsi:type`)

```xml
<arguments>
    <!-- String -->
    <argument name="label" xsi:type="string">My Label</argument>

    <!-- Translatable string -->
    <argument name="label" xsi:type="string" translate="true">Translatable Label</argument>

    <!-- Boolean -->
    <argument name="is_enabled" xsi:type="boolean">true</argument>

    <!-- Number -->
    <argument name="count" xsi:type="number">10</argument>

    <!-- Object (DI-resolved class instance — used for ViewModels) -->
    <argument name="view_model" xsi:type="object">Vendor\Module\ViewModel\MyClass</argument>

    <!-- URL -->
    <argument name="save_url" xsi:type="url" path="module/controller/action">
        <param name="id">123</param>
    </argument>

    <!-- Helper method call -->
    <argument name="value" xsi:type="helper"
              helper="Vendor\Module\Helper\Data::getConfigValue">
        <param name="param1">value1</param>
    </argument>

    <!-- Array -->
    <argument name="options" xsi:type="array">
        <item name="key1" xsi:type="string">value1</item>
        <item name="key2" xsi:type="number">42</item>
        <item name="nested" xsi:type="array">
            <item name="inner" xsi:type="string">value</item>
        </item>
    </argument>
</arguments>
```

## `<action>` (DEPRECATED)

**Do not use.** `<action>` calls PHP methods on block instances and is deprecated since Magento 2.0. Documented here only for awareness when reading legacy code.

```xml
<!-- DEPRECATED — do not use in new code -->
<action method="setData">
    <argument name="name" xsi:type="string">key</argument>
    <argument name="value" xsi:type="string">value</argument>
</action>
```

**Replace with:** `<arguments>` for setting data, or a ViewModel for logic.

## Key Luma/Blank Containers

Containers commonly targeted in Luma/Blank-based themes:

| Container Name | Location | Use For |
|---------------|----------|---------|
| `header.container` | Page header outer wrapper | Header-level additions |
| `header-wrapper` | Inside header | Logo area, header links |
| `header.panel` | Top bar above header | Store switcher, welcome message |
| `top.container` | Below header, above content | Breadcrumbs area |
| `columns.top` | Above main content columns | Full-width content above sidebar |
| `content` | Main content area | Primary page content |
| `content.aside` | Beside main content | Supplementary content |
| `content.bottom` | Below main content | Below-content widgets |
| `sidebar.main` | Primary sidebar | Navigation, filters |
| `sidebar.additional` | Secondary sidebar | Additional sidebar blocks |
| `footer-container` | Footer outer wrapper | Footer-level additions |
| `footer` | Inside footer | Footer links, copyright |
| `before.body.end` | Before closing `</body>` | Scripts, modals, overlays |
| `after.body.start` | After opening `<body>` | Early-load content |
| `head.additional` | Inside `<head>` | Additional head markup |

### Page sections (for `<move>` destinations)

- **Header area:** `header.container` > `header-wrapper`, `header.panel`
- **Content area:** `columns.top`, `content`, `content.aside`, `content.bottom`
- **Sidebar:** `sidebar.main`, `sidebar.additional`
- **Footer area:** `footer-container` > `footer`
- **Script area:** `before.body.end`, `after.body.start`
