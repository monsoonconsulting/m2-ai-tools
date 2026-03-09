# Form UI Component Template

## `view/adminhtml/ui_component/{entity_snake}_form.xml`

```xml
<?xml version="1.0"?>
<!--
/**
 * Copyright © Monsoon Consulting. All rights reserved.
 * See LICENSE_MONSOON.txt for license details.
 */
-->
<form xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
      xsi:noNamespaceSchemaLocation="urn:magento:module:Magento_Ui:etc/ui_configuration.xsd">

    <argument name="data" xsi:type="array">
        <item name="js_config" xsi:type="array">
            <item name="provider" xsi:type="string">{entity_snake}_form.{entity_snake}_form_data_source</item>
        </item>
        <item name="label" xsi:type="string" translate="true">{Entity Label}</item>
        <item name="template" xsi:type="string">templates/form/collapsible</item>
    </argument>

    <settings>
        <namespace>{entity_snake}_form</namespace>
        <dataScope>data</dataScope>
        <deps>
            <dep>{entity_snake}_form.{entity_snake}_form_data_source</dep>
        </deps>
        <buttons>
            <button name="back" class="{Vendor}\{ModuleName}\Block\Adminhtml\{Entity}\Edit\BackButton"/>
            <button name="delete" class="{Vendor}\{ModuleName}\Block\Adminhtml\{Entity}\Edit\DeleteButton"/>
            <button name="save" class="{Vendor}\{ModuleName}\Block\Adminhtml\{Entity}\Edit\SaveButton"/>
        </buttons>
    </settings>

    <dataSource name="{entity_snake}_form_data_source">
        <argument name="data" xsi:type="array">
            <item name="js_config" xsi:type="array">
                <item name="component" xsi:type="string">Magento_Ui/js/form/provider</item>
            </item>
        </argument>
        <settings>
            <submitUrl path="*/*/*save"/>
        </settings>
        <dataProvider class="{Vendor}\{ModuleName}\Model\{Entity}\DataProvider"
                      name="{entity_snake}_form_data_source">
            <settings>
                <requestFieldName>{primary_key}</requestFieldName>
                <primaryFieldName>{primary_key}</primaryFieldName>
            </settings>
        </dataProvider>
    </dataSource>

    <fieldset name="general" sortOrder="10">
        <settings>
            <collapsible>false</collapsible>
            <label translate="true">General</label>
        </settings>

        <!-- Hidden primary key field -->
        <field name="{primary_key}" formElement="input" sortOrder="0">
            <settings>
                <dataType>text</dataType>
                <visible>false</visible>
            </settings>
        </field>

        <!-- Text input example -->
        <field name="title" formElement="input" sortOrder="10">
            <settings>
                <dataType>text</dataType>
                <label translate="true">Title</label>
                <validation>
                    <rule name="required-entry" xsi:type="boolean">true</rule>
                </validation>
            </settings>
        </field>

        <!-- Textarea example -->
        <field name="description" formElement="textarea" sortOrder="20">
            <settings>
                <dataType>text</dataType>
                <label translate="true">Description</label>
                <validation>
                    <rule name="required-entry" xsi:type="boolean">false</rule>
                </validation>
            </settings>
        </field>

        <!-- Boolean toggle example -->
        <field name="is_active" formElement="checkbox" sortOrder="30">
            <argument name="data" xsi:type="array">
                <item name="config" xsi:type="array">
                    <item name="default" xsi:type="number">1</item>
                </item>
            </argument>
            <settings>
                <dataType>boolean</dataType>
                <label translate="true">Active</label>
            </settings>
            <formElements>
                <checkbox>
                    <settings>
                        <prefer>toggle</prefer>
                        <valueMap>
                            <map name="false" xsi:type="number">0</map>
                            <map name="true" xsi:type="number">1</map>
                        </valueMap>
                    </settings>
                </checkbox>
            </formElements>
        </field>

        <!-- Select dropdown example -->
        <field name="status" formElement="select" sortOrder="40">
            <settings>
                <dataType>text</dataType>
                <label translate="true">Status</label>
                <validation>
                    <rule name="required-entry" xsi:type="boolean">true</rule>
                </validation>
            </settings>
            <formElements>
                <select>
                    <settings>
                        <options class="{Vendor}\{ModuleName}\Model\Source\{OptionSource}"/>
                    </settings>
                </select>
            </formElements>
        </field>

        <!-- WYSIWYG editor example -->
        <field name="content" formElement="wysiwyg" sortOrder="50">
            <settings>
                <dataType>text</dataType>
                <label translate="true">Content</label>
            </settings>
            <formElements>
                <wysiwyg>
                    <settings>
                        <rows>20</rows>
                        <wysiwyg>true</wysiwyg>
                    </settings>
                </wysiwyg>
            </formElements>
        </field>

        <!-- Date field example -->
        <field name="publish_date" formElement="date" sortOrder="60">
            <settings>
                <dataType>text</dataType>
                <label translate="true">Publish Date</label>
            </settings>
        </field>
    </fieldset>
</form>
```

## Field Type Reference

| Data Type | `formElement` | Notes |
|-----------|-------------|-------|
| `varchar` (short text) | `input` | Standard text input |
| `text` (long text) | `textarea` | Multi-line plain text |
| `text` (rich content) | `wysiwyg` | TinyMCE WYSIWYG editor |
| `int` (boolean 0/1) | `checkbox` | Use toggle with `valueMap` |
| `int`/`varchar` (selection) | `select` | Requires `<options class="..."/>` |
| `int`/`varchar` (multi) | `multiselect` | Requires `<options class="..."/>` |
| `datetime` | `date` | Date picker |
| `decimal` / `int` (number) | `input` | Add `<validation><rule name="validate-number" ...>true</rule></validation>` |
| Hidden ID | `input` | Set `<visible>false</visible>` |

## Notes

- The `<submitUrl path="*/*/*save"/>` uses wildcard syntax — Magento resolves `*` to the current route/controller prefix. This makes the form portable.
- Add multiple fieldsets (`<fieldset name="seo" sortOrder="20">`) to organize fields into collapsible sections.
- For image upload fields, use `formElement="imageUploader"` with a controller for upload handling.
- The `requestFieldName` in `<dataProvider>` must match the URL parameter name used to pass the entity ID (typically the primary key name).
