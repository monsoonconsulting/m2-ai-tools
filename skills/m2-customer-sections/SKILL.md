---
name: m2-customer-sections
description: >
  Generate Magento 2 customer data sections (private content) including sections.xml
  action-to-section mapping, SectionSourceInterface implementations, section pool
  registration via di.xml, and frontend customerData JS consumers. Use this skill
  for FPC-compatible personalization — displaying customer-specific data on cached pages.
  Trigger on: "sections.xml", "private content", "customer data", "section source",
  "SectionSourceInterface", "customer-data", "customerData", "section pool",
  "invalidate section", "cached page", "personalized content", "FPC compatible",
  "customer section", "section invalidation".
---

# Magento 2 Customer Data Sections (Private Content)

You are a Magento 2 private content specialist. Generate customer data section sources, sections.xml configuration, di.xml pool registration, and frontend JS consumers under existing modules in `app/code/{Vendor}/{ModuleName}/`.

Follow the coding conventions and file headers defined in `.claude/skills/_shared/conventions.md` and `.claude/skills/m2-module/SKILL.md`. Do not duplicate those conventions here.

**Prerequisites:** Module must exist (see `_shared/conventions.md`). If not, use `/m2-module` first.

## 1. Decision Tree

**Use customer data sections when:**
- You need to display personalized data on full-page-cached (FPC/Varnish) pages
- Data varies per customer: cart count, wishlist items, reward points, customer name, loyalty tier
- The data should refresh automatically after specific POST actions (add to cart, place order, etc.)

**Use a ViewModel instead when:**
- The data does not vary per customer (e.g., store config values, static catalog data)
- The page is not cached by FPC (e.g., customer account pages behind authentication) — for server-side My Account pages, see `/m2-customer-account`

**Use a direct AJAX call instead when:**
- You need a one-off data load not tied to POST action invalidation
- The data load is expensive and should only happen on specific pages, not globally
- You need custom request parameters or non-GET HTTP methods

**Key rule:** Customer data sections are the standard Magento mechanism for personalized content on cached pages. They are loaded via a single batched AJAX GET request (`/customer/section/load/`) after page load, so FPC can serve the same HTML to all visitors while sections inject per-customer data client-side.

## 2. Gather Requirements

Before generating any files, collect the following from the user.

**Required (ask if not provided):**
- **Module name** — `Vendor_ModuleName`
- **Section name** — lowercase-hyphenated identifier (e.g., `custom-rewards`)
- **Data to expose** — what fields the section returns (e.g., count, items, label)

**Optional (use defaults if not specified):**
- **Invalidation actions** — which POST URLs invalidate this section (e.g., `checkout/cart/add`, `rest/*/V1/carts/*/items`)
- **Dependencies** — services the section source needs (repositories, helpers, session)

## 3. Naming Conventions

| Concept | Convention | Example |
|---------|-----------|---------|
| Section name | lowercase-hyphenated | `custom-rewards` |
| Section source class | `CustomerData\{PascalCaseName}` | `CustomerData\CustomRewards` |
| File path | `CustomerData/{PascalCaseName}.php` | `CustomerData/CustomRewards.php` |
| sections.xml location | `etc/frontend/sections.xml` | Always frontend area |
| di.xml pool key | matches section name | `custom-rewards` |

## 4. Templates

### 4.1 sections.xml — `etc/frontend/sections.xml`

```xml
<?xml version="1.0"?>
<!--
/**
 * Copyright © Monsoon Consulting. All rights reserved.
 * See LICENSE_MONSOON.txt for license details.
 */
-->
<config xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
        xsi:noNamespaceSchemaLocation="urn:magento:module:Magento_Customer:etc/sections.xsd">
    <action name="checkout/cart/add">
        <section name="{section-name}"/>
    </action>
    <action name="rest/*/V1/carts/*/items">
        <section name="{section-name}"/>
    </action>
    <action name="{custom/action/post}">
        <section name="{section-name}"/>
    </action>
</config>
```

**How it works:** Each `<action>` maps a POST URL pattern to sections that should be invalidated when that URL is hit. After a matching POST request completes, the browser automatically re-fetches the listed sections via AJAX.

- Wildcards `*` match any single URL segment
- Only POST requests trigger invalidation — GET requests are ignored
- Multiple `<section>` elements can be listed under one `<action>`
- Multiple `<action>` elements can invalidate the same section

### 4.2 Section Source Class — `CustomerData/{SectionName}.php`

```php
<?php
/**
 * Copyright © Monsoon Consulting. All rights reserved.
 * See LICENSE_MONSOON.txt for license details.
 */

declare(strict_types=1);

namespace {Vendor}\{ModuleName}\CustomerData;

use Magento\Customer\CustomerData\SectionSourceInterface;
use Magento\Customer\Model\Session as CustomerSession;

final class {SectionName} implements SectionSourceInterface
{
    public function __construct(
        private readonly CustomerSession $customerSession
    ) {
    }

    /**
     * @return array<string, mixed>
     */
    public function getSectionData(): array
    {
        if (!$this->customerSession->isLoggedIn()) {
            return $this->getDefaultData();
        }

        return [
            'count' => 0,
            'items' => [],
            'label' => '',
            // Return data as a flat associative array — serialized to JSON for the frontend
        ];
    }

    /**
     * @return array<string, mixed>
     */
    private function getDefaultData(): array
    {
        return [
            'count' => 0,
            'items' => [],
            'label' => '',
        ];
    }
}
```

**Important:** `getSectionData()` must return a flat associative array. The array is JSON-encoded and exposed as a Knockout.js observable on the frontend.

### 4.3 di.xml — Register Section in the Pool

File: `etc/frontend/di.xml`

```xml
<?xml version="1.0"?>
<!-- Standard XML header — see _shared/conventions.md -->
<config xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
        xsi:noNamespaceSchemaLocation="urn:magento:framework:ObjectManager/etc/config.xsd">
    <type name="Magento\Customer\CustomerData\SectionPoolInterface">
        <arguments>
            <argument name="sectionSourceMap" xsi:type="array">
                <item name="{section-name}" xsi:type="string">{Vendor}\{ModuleName}\CustomerData\{SectionName}</item>
            </argument>
        </arguments>
    </type>
</config>
```

The `sectionSourceMap` key must match the section name used in `sections.xml` and in frontend JS `customerData.get()` calls.

### 4.4 Frontend JS Consumer — RequireJS Component

File: `view/frontend/web/js/{section-name}.js`

```javascript
/**
 * Copyright © Monsoon Consulting. All rights reserved.
 * See LICENSE_MONSOON.txt for license details.
 */

define([
    'uiComponent',
    'Magento_Customer/js/customer-data'
], function (Component, customerData) {
    'use strict';

    return Component.extend({
        initialize: function () {
            this._super();
            this.sectionData = customerData.get('{section-name}');
        }
    });
});
```

### 4.5 phtml Template with Knockout.js Binding

File: `view/frontend/templates/{section-name}.phtml`

```php
<?php
// Standard file header — see _shared/conventions.md
declare(strict_types=1);

/**
 * @var \Magento\Framework\View\Element\Template $block
 * @var \Magento\Framework\Escaper $escaper
 */
?>
<div id="{vendor}-{section-name}" data-bind="scope: '{section-name}'">
    <!-- ko if: sectionData().count > 0 -->
    <span data-bind="text: sectionData().count"></span>
    <!-- /ko -->
</div>

<script type="text/x-magento-init">
{
    "#{vendor}-{section-name}": {
        "Magento_Ui/js/core/app": {
            "components": {
                "{section-name}": {
                    "component": "{Vendor}_{ModuleName}/js/{section-name}"
                }
            }
        }
    }
}
</script>
```

### 4.6 Layout XML — Add the Block to a Page

File: `view/frontend/layout/{layout_handle}.xml`

```xml
<?xml version="1.0"?>
<!-- Standard XML header — see _shared/conventions.md -->
<page xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
      xsi:noNamespaceSchemaLocation="urn:magento:framework:View/Layout/etc/page_configuration.xsd">
    <body>
        <referenceContainer name="content">
            <block class="Magento\Framework\View\Element\Template"
                   name="{vendor}_{module}_{section_name}"
                   template="{Vendor}_{ModuleName}::{section-name}.phtml"/>
        </referenceContainer>
    </body>
</page>
```

Use `default.xml` as the layout handle if the section should appear on all pages (e.g., header cart count).

## 5. Section Invalidation Patterns

Invalidation happens automatically when a browser POST request URL matches an `<action>` in `sections.xml`. The Magento JS framework intercepts the response and re-fetches invalidated sections via `GET /customer/section/load/?sections={name}`. Magento batches all section requests into a single AJAX call.

**Manual invalidation from JS:**
```javascript
customerData.invalidate(['{section-name}']);  // Stale — reloads on next navigation
customerData.reload(['{section-name}'], true); // Force immediate AJAX reload
```

**Wildcard:** `<action name="*">` invalidates on ANY POST — avoid unless truly needed.

### Common Magento POST Actions for sections.xml

| Action URL | When it fires |
|-----------|---------------|
| `checkout/cart/add` | Product added to cart |
| `checkout/cart/delete` | Item removed from cart |
| `checkout/cart/updatePost` | Cart quantities updated |
| `checkout/cart/couponPost` | Coupon applied/removed |
| `rest/*/V1/carts/*/items` | REST API cart item changes |
| `rest/*/V1/guest-carts/*/items` | Guest cart REST changes |
| `customer/account/loginPost` | Customer login |
| `customer/account/createPost` | Customer registration |
| `wishlist/index/add` | Product added to wishlist |
| `wishlist/index/remove` | Product removed from wishlist |
| `checkout/onepage/saveOrder` | Order placed |

## 6. Generation Rules

Follow this sequence when generating customer data sections:

1. **Verify the module exists** — check `registration.php`.

2. **Create `etc/frontend/sections.xml`** — map POST actions to the section name. If the file exists, append the new `<action>` blocks inside the existing `<config>` element.

3. **Create the section source class** — `CustomerData/{SectionName}.php` implementing `SectionSourceInterface`.

4. **Register in `etc/frontend/di.xml`** — add the section to `SectionPoolInterface`'s `sectionSourceMap`. If the file exists, merge into the existing `<type>` block.

5. **Create the frontend JS component** — `view/frontend/web/js/{section-name}.js`.

6. **Create the phtml template** — with Knockout.js data bindings.

7. **Add layout XML** — reference the template block on the appropriate page(s).

8. **Remind the user** to run post-generation commands.

## 7. Anti-Patterns

**Expensive queries in `getSectionData()`.**
This method is called via AJAX on every page load after invalidation. Keep it fast — use cached data, indexed tables, or lightweight queries. Offload heavy computation to cron or message queues.

**Missing sections.xml action mapping.**
If no `<action>` maps to your section, it never refreshes after user actions. The section loads once and shows stale data. Always map relevant POST URLs.

**Using `<action name="*">` to invalidate everything.**
This forces every section to reload on every POST request, degrading frontend performance. Only invalidate sections that are actually affected by the action.

**Deeply nested arrays in `getSectionData()`.**
Knockout.js observables do not automatically unwrap nested objects. Keep the return array flat or use simple one-level nesting. Complex nested structures cause binding issues.

**Accessing section data before it loads.**
Section data loads asynchronously via AJAX. Always use Knockout `subscribe()` or `data-bind` — never assume the data is available synchronously on page load.

**Not returning default data for guest users.**
`getSectionData()` is called for both logged-in and guest users. Always return a valid default structure (empty counts, empty arrays) when the customer is not authenticated. Returning `null` or an incomplete array causes JS errors.

**Registering the section source in global `etc/di.xml`.**
Section sources must be registered in `etc/frontend/di.xml` — they are only relevant in the frontend area. Global registration wastes resources in admin and API contexts.

## 8. Post-Generation Steps

Follow `.claude/skills/_shared/post-generation.md` for: di.xml, static assets (JS), layout XML / templates.

To verify the section works:
1. Open the storefront in a browser with DevTools Network tab open
2. Filter requests by `section/load`
3. Perform a POST action mapped in sections.xml (e.g., add to cart)
4. Verify the section appears in the `/customer/section/load/` response JSON
5. Confirm the Knockout.js template updates with the new data
