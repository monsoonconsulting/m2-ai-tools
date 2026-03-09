# API XML Configuration Templates

## webapi.xml — `etc/webapi.xml`

```xml
<?xml version="1.0"?>
<!--
/**
 * Copyright © Monsoon Consulting. All rights reserved.
 * See LICENSE_MONSOON.txt for license details.
 */
-->
<routes xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
        xsi:noNamespaceSchemaLocation="urn:magento:module:Magento_Webapi:etc/webapi.xsd">

    <!-- GET single entity by ID -->
    <route url="/V1/{vendor}-{module}/{entity-kebab}/:entityId" method="GET">
        <service class="{Vendor}\{ModuleName}\Api\{Entity}RepositoryInterface" method="getById"/>
        <resources>
            <resource ref="{Vendor}_{ModuleName}::{entity_snake}"/>
        </resources>
    </route>

    <!-- GET list with search criteria -->
    <route url="/V1/{vendor}-{module}/{entity-kebab-plural}" method="GET">
        <service class="{Vendor}\{ModuleName}\Api\{Entity}RepositoryInterface" method="getList"/>
        <resources>
            <resource ref="{Vendor}_{ModuleName}::{entity_snake}"/>
        </resources>
    </route>

    <!-- POST create new entity -->
    <route url="/V1/{vendor}-{module}/{entity-kebab}" method="POST">
        <service class="{Vendor}\{ModuleName}\Api\{Entity}RepositoryInterface" method="save"/>
        <resources>
            <resource ref="{Vendor}_{ModuleName}::{entity_snake}"/>
        </resources>
    </route>

    <!-- PUT update existing entity -->
    <route url="/V1/{vendor}-{module}/{entity-kebab}/:entityId" method="PUT">
        <service class="{Vendor}\{ModuleName}\Api\{Entity}RepositoryInterface" method="save"/>
        <resources>
            <resource ref="{Vendor}_{ModuleName}::{entity_snake}"/>
        </resources>
    </route>

    <!-- DELETE entity by ID -->
    <route url="/V1/{vendor}-{module}/{entity-kebab}/:entityId" method="DELETE">
        <service class="{Vendor}\{ModuleName}\Api\{Entity}RepositoryInterface" method="deleteById"/>
        <resources>
            <resource ref="{Vendor}_{ModuleName}::{entity_snake}"/>
        </resources>
    </route>
</routes>
```

**ACL resource options:**
- `{Vendor}_{ModuleName}::{entity_snake}` — admin-only (requires integration or admin token)
- `self` — authenticated customer accessing own data
- `anonymous` — public access, no authentication required

## di.xml Preferences

Add these preferences to `etc/di.xml` (create or append):

```xml
<config xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
        xsi:noNamespaceSchemaLocation="urn:magento:framework:ObjectManager/etc/config.xsd">
    <preference for="{Vendor}\{ModuleName}\Api\Data\{Entity}Interface"
                type="{Vendor}\{ModuleName}\Model\{Entity}"/>
    <preference for="{Vendor}\{ModuleName}\Api\{Entity}RepositoryInterface"
                type="{Vendor}\{ModuleName}\Model\{Entity}Repository"/>
    <preference for="{Vendor}\{ModuleName}\Api\Data\{Entity}SearchResultsInterface"
                type="{Vendor}\{ModuleName}\Model\{Entity}SearchResults"/>
</config>
```

## acl.xml — `etc/acl.xml`

```xml
<?xml version="1.0"?>
<!--
/**
 * Copyright © Monsoon Consulting. All rights reserved.
 * See LICENSE_MONSOON.txt for license details.
 */
-->
<config xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
        xsi:noNamespaceSchemaLocation="urn:magento:framework:Acl/etc/acl.xsd">
    <acl>
        <resources>
            <resource id="Magento_Backend::admin">
                <resource id="{Vendor}_{ModuleName}::config" title="{ModuleName}" sortOrder="100">
                    <resource id="{Vendor}_{ModuleName}::{entity_snake}"
                              title="Manage {Entity}" sortOrder="10"/>
                </resource>
            </resource>
        </resources>
    </acl>
</config>
```

If `etc/acl.xml` already exists, merge the new `<resource>` node into the existing tree.
