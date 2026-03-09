# RequireJS Patterns Reference

Complete reference for RequireJS configuration and JavaScript initialization in Magento 2.

## `requirejs-config.js` Template

Place at `view/{area}/requirejs-config.js` within your module.

```javascript
/**
 * Copyright © Monsoon Consulting. All rights reserved.
 * See LICENSE_MONSOON.txt for license details.
 */
var config = {
    // Alias mapping — make modules available under short names
    map: {
        '*': {
            'customWidget': 'Vendor_Module/js/custom-widget'
        }
    },

    // Path aliases for third-party libraries
    paths: {
        'vendorLib': 'Vendor_Module/js/lib/vendor-library'
    },

    // Shim for non-AMD scripts (legacy JS that doesn't call define())
    shim: {
        'Vendor_Module/js/legacy-lib': {
            deps: ['jquery'],
            exports: 'LegacyLib'
        }
    },

    // Mixins — extend existing JS modules without overriding them
    config: {
        mixins: {
            'Magento_Checkout/js/model/step-navigator': {
                'Vendor_Module/js/model/step-navigator-mixin': true
            },
            'jquery/ui-modules/widgets/menu': {
                'Vendor_Module/js/menu-mixin': true
            }
        }
    }
};
```

## Config Keys

### `map`

Creates module ID aliases. Maps short names to full module paths.

```javascript
map: {
    '*': {
        // Available everywhere as 'shortName'
        'shortName': 'Vendor_Module/js/full-path'
    },
    'Vendor_Module/js/specific-consumer': {
        // Only available in this specific module
        'dependency': 'Vendor_Module/js/custom-dependency'
    }
}
```

### `paths`

Defines path aliases for modules. Useful for third-party libraries.

```javascript
paths: {
    'libraryName': 'Vendor_Module/js/lib/library.min'
    // Note: .js extension is omitted
}
```

### `shim`

Configures non-AMD scripts so RequireJS can load them properly.

```javascript
shim: {
    'Vendor_Module/js/legacy-script': {
        deps: ['jquery'],           // Dependencies to load first
        exports: 'GlobalVarName'    // Global variable the script creates
    }
}
```

### `config/mixins`

Extend existing JS modules by wrapping them. The mixin module receives the original and returns a modified version.

```javascript
config: {
    mixins: {
        'target/module/path': {
            'Vendor_Module/js/mixin-file': true
        }
    }
}
```

## JS Mixin Pattern

A mixin wraps an existing RequireJS module to extend its behavior.

### Mixin for a jQuery widget

File: `view/frontend/web/js/widget-mixin.js`

```javascript
/**
 * Copyright © Monsoon Consulting. All rights reserved.
 * See LICENSE_MONSOON.txt for license details.
 */
define([
    'jquery'
], function ($) {
    'use strict';

    return function (originalWidget) {
        $.widget('mage.originalWidget', originalWidget, {
            // Override or extend methods
            methodToExtend: function () {
                // Custom logic before
                this._super();  // Call original method
                // Custom logic after
            }
        });

        return $.mage.originalWidget;
    };
});
```

### Mixin for a JS object/function

File: `view/frontend/web/js/module-mixin.js`

```javascript
/**
 * Copyright © Monsoon Consulting. All rights reserved.
 * See LICENSE_MONSOON.txt for license details.
 */
define([], function () {
    'use strict';

    return function (originalModule) {
        // Extend or modify the original module
        originalModule.newMethod = function () {
            // Custom logic
        };

        return originalModule;
    };
});
```

## JS Initialization Patterns

### `data-mage-init` attribute

Binds a JS component to a specific DOM element. The component receives the element and config options.

```html
<div data-mage-init='{"Vendor_Module/js/component": {"option1": "value1", "option2": true}}'>
    Content
</div>
```

For components registered via `map`:

```html
<div data-mage-init='{"customWidget": {"option": "value"}}'>
    Content
</div>
```

### `<script type="text/x-magento-init">`

More flexible initialization. Can target any CSS selector or use `*` for non-DOM components.

**Target a specific element:**

```html
<script type="text/x-magento-init">
{
    "#my-element": {
        "Vendor_Module/js/component": {
            "option1": "value1"
        }
    }
}
</script>
```

**Multiple components on different elements:**

```html
<script type="text/x-magento-init">
{
    "#element-one": {
        "Vendor_Module/js/component-a": {"key": "val"}
    },
    ".element-class": {
        "Vendor_Module/js/component-b": {}
    }
}
</script>
```

**Wildcard `*` — no DOM element (runs immediately):**

```html
<script type="text/x-magento-init">
{
    "*": {
        "Vendor_Module/js/init-script": {
            "apiUrl": "<?= $escaper->escapeJs($block->getUrl('route/action')) ?>"
        }
    }
}
</script>
```

## Custom jQuery Widget

File: `view/frontend/web/js/custom-widget.js`

```javascript
/**
 * Copyright © Monsoon Consulting. All rights reserved.
 * See LICENSE_MONSOON.txt for license details.
 */
define([
    'jquery',
    'jquery-ui-modules/widget'
], function ($) {
    'use strict';

    $.widget('vendor.customWidget', {
        options: {
            selector: '.item',
            activeClass: 'active'
        },

        /**
         * Widget constructor
         * @private
         */
        _create: function () {
            this._bind();
        },

        /**
         * Bind event handlers
         * @private
         */
        _bind: function () {
            this._on({
                'click [data-action="toggle"]': '_onToggle'
            });
        },

        /**
         * Toggle handler
         * @param {jQuery.Event} event
         * @private
         */
        _onToggle: function (event) {
            event.preventDefault();
            $(event.currentTarget)
                .closest(this.options.selector)
                .toggleClass(this.options.activeClass);
        }
    });

    return $.vendor.customWidget;
});
```

Register in `requirejs-config.js`:

```javascript
var config = {
    map: {
        '*': {
            'customWidget': 'Vendor_Module/js/custom-widget'
        }
    }
};
```

Use in template:

```html
<div data-mage-init='{"customWidget": {"selector": ".my-item", "activeClass": "is-active"}}'>
    <div class="my-item">
        <button data-action="toggle">Toggle</button>
    </div>
</div>
```

## File Locations

| File Type | Module Path | Theme Override Path |
|-----------|------------|-------------------|
| `requirejs-config.js` | `view/{area}/requirejs-config.js` | `{Module_Name}/requirejs-config.js` |
| JS files | `view/{area}/web/js/{name}.js` | `{Module_Name}/web/js/{name}.js` |
| CSS files | `view/{area}/web/css/source/{name}.less` | `{Module_Name}/web/css/source/{name}.less` |
| Templates | `view/{area}/templates/{path}.phtml` | `{Module_Name}/templates/{path}.phtml` |
