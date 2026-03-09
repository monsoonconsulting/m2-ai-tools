# Custom Form Fields Reference

> Companion file for m2-admin-ui. Covers custom UI component field types for admin forms.

## File Uploader (`imageUploader`)

```xml
<field name="image" formElement="imageUploader" sortOrder="50">
    <settings>
        <label translate="true">Image</label>
        <componentType>imageUploader</componentType>
    </settings>
    <formElements>
        <imageUploader>
            <settings>
                <allowedExtensions>jpg jpeg gif png svg</allowedExtensions>
                <maxFileSize>2097152</maxFileSize>
                <uploaderConfig>
                    <param xsi:type="string" name="url">vendor_module/image/upload</param>
                </uploaderConfig>
            </settings>
        </imageUploader>
    </formElements>
</field>
```

The `uploaderConfig` URL points to a controller that uses `Magento\Framework\File\Uploader` and returns JSON with `name`, `url`, `tmp_name`, `size`. The Save controller moves the file from `tmp` to its final location.

## Color Picker

```xml
<field name="color" formElement="colorPicker" sortOrder="60">
    <settings>
        <dataType>text</dataType>
        <label translate="true">Color</label>
    </settings>
    <formElements>
        <colorPicker>
            <settings>
                <colorFormat>hex</colorFormat>
                <colorPickerMode>full</colorPickerMode>
            </settings>
        </colorPicker>
    </formElements>
</field>
```

Modes: `full` (spectrum), `simple` (swatches), `nocolor` (text only). Formats: `hex`, `rgb`, `hsl`, `hsv`.

## WYSIWYG with Custom Config

```xml
<field name="content" formElement="wysiwyg" sortOrder="70">
    <settings>
        <dataType>text</dataType>
        <label translate="true">Content</label>
    </settings>
    <formElements>
        <wysiwyg>
            <settings>
                <rows>25</rows>
                <wysiwyg>true</wysiwyg>
            </settings>
        </wysiwyg>
    </formElements>
</field>
```

For custom TinyMCE config, extend `Magento\Cms\Model\Wysiwyg\Config` and override `getConfig()` to set `tinymce.toolbar`, `tinymce.plugins`, and `tinymce.content_css`.

## Dynamic Rows (`dynamicRows`)

```xml
<container name="custom_options" sortOrder="80">
    <argument name="data" xsi:type="array">
        <item name="config" xsi:type="array">
            <item name="componentType" xsi:type="string">dynamicRows</item>
            <item name="label" xsi:type="string" translate="true">Options</item>
            <item name="addButtonLabel" xsi:type="string" translate="true">Add Option</item>
            <item name="deleteProperty" xsi:type="boolean">true</item>
        </item>
    </argument>
    <container name="record" component="Magento_Ui/js/dynamic-rows/record">
        <argument name="data" xsi:type="array">
            <item name="config" xsi:type="array">
                <item name="isTemplate" xsi:type="boolean">true</item>
                <item name="is_collection" xsi:type="boolean">true</item>
                <item name="componentType" xsi:type="string">container</item>
            </item>
        </argument>
        <field name="label" formElement="input" sortOrder="10">
            <settings><dataType>text</dataType><label translate="true">Label</label></settings>
        </field>
        <field name="value" formElement="input" sortOrder="20">
            <settings><dataType>text</dataType><label translate="true">Value</label></settings>
        </field>
        <actionDelete sortOrder="30">
            <settings><dataType>text</dataType><componentType>actionDelete</componentType></settings>
        </actionDelete>
    </container>
</container>
```

The data provider must return dynamic rows as a nested array under the field name. The Save controller receives them as an indexed array.

## Modal Selector

```xml
<field name="product_id" formElement="input" sortOrder="90">
    <settings><dataType>text</dataType><label translate="true">Product</label></settings>
</field>
<button name="select_product" displayArea="content">
    <argument name="data" xsi:type="array">
        <item name="config" xsi:type="array">
            <item name="title" xsi:type="string" translate="true">Select Product</item>
            <item name="actions" xsi:type="array">
                <item name="0" xsi:type="array">
                    <item name="targetName" xsi:type="string">${ $.parentName}.product_modal</item>
                    <item name="actionName" xsi:type="string">openModal</item>
                </item>
            </item>
        </item>
    </argument>
</button>
<modal name="product_modal">
    <settings><options><option name="title" xsi:type="string" translate="true">Select Product</option></options></settings>
    <insertListing name="product_listing">
        <settings>
            <externalProvider>product_listing.product_listing_data_source</externalProvider>
            <selectionsProvider>product_listing.product_listing.product_columns.ids</selectionsProvider>
            <autoRender>false</autoRender>
            <dataLinks><imports>false</imports><exports>true</exports></dataLinks>
        </settings>
    </insertListing>
</modal>
```

The `insertListing` references an existing listing component. Wire the selected value back to the form field via JS `exports`/`imports` links.

## Custom Validation Rules

Built-in rules via `<validation>`:

```xml
<validation>
    <rule name="required-entry" xsi:type="boolean">true</rule>
    <rule name="validate-email" xsi:type="boolean">true</rule>
    <rule name="max_text_length" xsi:type="number">255</rule>
</validation>
```

Custom validator -- create a RequireJS mixin for `Magento_Ui/js/lib/validation/rules`:

```js
// view/adminhtml/web/js/validation/custom-rules.js
define(['jquery'], function ($) {
    'use strict';
    return function (validator) {
        validator.addRule('validate-slug', function (value) {
            return /^[a-z0-9]+(?:-[a-z0-9]+)*$/.test(value);
        }, $.mage.__('Only lowercase letters, numbers, and hyphens allowed.'));
        return validator;
    };
});
```

Register in `view/adminhtml/requirejs-config.js`:

```js
var config = {
    config: {
        mixins: {
            'Magento_Ui/js/lib/validation/rules': {
                'Vendor_ModuleName/js/validation/custom-rules': true
            }
        }
    }
};
```

Then use in XML: `<rule name="validate-slug" xsi:type="boolean">true</rule>`.

## di.xml Registration

Custom field types rarely need `di.xml`. For dynamic form modifications, register a data modifier:

```xml
<virtualType name="Vendor\ModuleName\Model\Entity\DataProvider\Modifier\Pool"
             type="Magento\Ui\DataProvider\Modifier\Pool">
    <arguments>
        <argument name="modifiers" xsi:type="array">
            <item name="custom_fields" xsi:type="array">
                <item name="class" xsi:type="string">Vendor\ModuleName\Ui\DataProvider\Modifier\CustomFields</item>
                <item name="sortOrder" xsi:type="number">10</item>
            </item>
        </argument>
    </arguments>
</virtualType>
```

The modifier implements `Magento\Ui\DataProvider\Modifier\ModifierInterface` -- `modifyData()` transforms loaded data, `modifyMeta()` dynamically alters form structure (add fields, change validation, inject custom JS components).
