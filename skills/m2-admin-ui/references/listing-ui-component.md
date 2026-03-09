# Listing UI Component Template

## `view/adminhtml/ui_component/{entity_snake}_listing.xml`

```xml
<?xml version="1.0"?>
<!--
/**
 * Copyright © Monsoon Consulting. All rights reserved.
 * See LICENSE_MONSOON.txt for license details.
 */
-->
<listing xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:noNamespaceSchemaLocation="urn:magento:module:Magento_Ui:etc/ui_configuration.xsd">

    <argument name="data" xsi:type="array">
        <item name="js_config" xsi:type="array">
            <item name="provider" xsi:type="string">{entity_snake}_listing.{entity_snake}_listing_data_source</item>
        </item>
    </argument>

    <settings>
        <spinner>{entity_snake}_listing_columns</spinner>
        <deps>
            <dep>{entity_snake}_listing.{entity_snake}_listing_data_source</dep>
        </deps>
        <!-- Add New button (grid+form only) -->
        <buttons>
            <button name="add" class="Magento\Backend\Block\Widget\Button\SplitButton">
                <url path="*/*/*new"/>
                <class>primary</class>
                <label translate="true">Add New</label>
            </button>
        </buttons>
    </settings>

    <dataSource name="{entity_snake}_listing_data_source" component="Magento_Ui/js/grid/provider">
        <settings>
            <storageConfig>
                <param name="indexField" xsi:type="string">{primary_key}</param>
            </storageConfig>
            <updateUrl path="mui/index/render"/>
        </settings>
        <aclResource>{Vendor}_{ModuleName}::{entity_snake}</aclResource>
        <dataProvider class="Magento\Framework\View\Element\UiComponent\DataProvider\DataProvider"
                      name="{entity_snake}_listing_data_source">
            <settings>
                <requestFieldName>id</requestFieldName>
                <primaryFieldName>{primary_key}</primaryFieldName>
            </settings>
        </dataProvider>
    </dataSource>

    <listingToolbar name="listing_top">
        <settings>
            <sticky>true</sticky>
        </settings>
        <bookmark name="bookmarks"/>
        <columnsControls name="columns_controls"/>
        <filterSearch name="fulltext"/>
        <filters name="listing_filters"/>
        <!-- Mass actions (grid+form only) -->
        <massaction name="listing_massaction" component="Magento_Ui/js/grid/tree-massactions">
            <action name="delete">
                <settings>
                    <confirm>
                        <message translate="true">Are you sure you want to delete the selected items?</message>
                        <title translate="true">Delete items</title>
                    </confirm>
                    <url path="*/*/*massDelete"/>
                    <type>delete</type>
                    <label translate="true">Delete</label>
                </settings>
            </action>
        </massaction>
        <paging name="listing_paging"/>
    </listingToolbar>

    <columns name="{entity_snake}_listing_columns">
        <selectionsColumn name="ids" sortOrder="0">
            <settings>
                <indexField>{primary_key}</indexField>
            </settings>
        </selectionsColumn>

        <!-- ID column -->
        <column name="{primary_key}" sortOrder="10">
            <settings>
                <filter>textRange</filter>
                <label translate="true">ID</label>
                <sorting>desc</sorting>
            </settings>
        </column>

        <!-- Text column example -->
        <column name="title" sortOrder="20">
            <settings>
                <filter>text</filter>
                <label translate="true">Title</label>
            </settings>
        </column>

        <!-- Select/boolean column example -->
        <column name="is_active" component="Magento_Ui/js/grid/columns/select" sortOrder="30">
            <settings>
                <filter>select</filter>
                <options class="Magento\Config\Model\Config\Source\Yesno"/>
                <dataType>select</dataType>
                <label translate="true">Active</label>
            </settings>
        </column>

        <!-- Date column example -->
        <column name="created_at" class="Magento\Ui\Component\Listing\Columns\Date"
                component="Magento_Ui/js/grid/columns/date" sortOrder="40">
            <settings>
                <filter>dateRange</filter>
                <dataType>date</dataType>
                <label translate="true">Created</label>
            </settings>
        </column>

        <!-- Actions column (grid+form only) -->
        <actionsColumn name="actions"
                       class="{Vendor}\{ModuleName}\Ui\Component\Listing\Column\{Entity}Actions"
                       sortOrder="200">
            <settings>
                <indexField>{primary_key}</indexField>
            </settings>
        </actionsColumn>
    </columns>
</listing>
```

## Column Type Reference

| DB Type | UI Component Config |
|---------|-------------------|
| `varchar` / `text` | `<column name="..."><settings><filter>text</filter><label>...</label></settings></column>` |
| `int` (boolean 0/1) | `<column name="..." component="Magento_Ui/js/grid/columns/select"><settings><filter>select</filter><options class="Magento\Config\Model\Config\Source\Yesno"/><dataType>select</dataType><label>...</label></settings></column>` |
| `int` (FK / select) | `<column name="..." component="Magento_Ui/js/grid/columns/select"><settings><filter>select</filter><options class="{Vendor}\{ModuleName}\Model\Source\{OptionSource}"/><dataType>select</dataType><label>...</label></settings></column>` |
| `datetime` / `timestamp` | `<column name="..." class="Magento\Ui\Component\Listing\Columns\Date" component="Magento_Ui/js/grid/columns/date"><settings><filter>dateRange</filter><dataType>date</dataType><label>...</label></settings></column>` |
| `decimal` / `int` (numeric) | `<column name="..."><settings><filter>textRange</filter><label>...</label></settings></column>` |

## Notes

- For grid-only mode: remove the `<buttons>` block, `<massaction>`, `<selectionsColumn>`, and the `<actionsColumn>`.
- The `<filterSearch name="fulltext"/>` enables the search bar. It requires a fulltext index on the table for the columns you want searchable. Add it in `db_schema.xml` with `xsi:type="fulltext"`.
- Custom mass actions can be added alongside delete (e.g., enable/disable status toggle).
- The `<spinner>` setting must match the `<columns name="...">` value.
