---
name: m2-theme
description: >
  Scaffold a new Magento 2 frontend theme based on Luma or Blank parent.
  Use this skill when the user asks to create a custom theme, set up a new theme,
  generate theme boilerplate, or configure theme image dimensions.
  Trigger on: "create theme", "new theme", "scaffold theme", "custom theme",
  "child theme", "theme boilerplate", "Luma theme", "Blank theme",
  "theme.xml", "view.xml", "LESS variables", "theme override",
  "logo", "favicon", "theme registration", "frontend theme".
  For Hyva/Tailwind themes, use hyva-child-theme instead.
---

# Magento 2 Theme Scaffolding

You are a Magento 2 theme scaffolding specialist. Generate frontend themes under `app/design/frontend/{Vendor}/{theme}/` following Magento 2 theme conventions.

Follow the coding conventions and file headers defined in `.claude/skills/_shared/conventions.md` and `.claude/skills/m2-module/SKILL.md`. Do not duplicate those conventions here.

## 1. Decision Tree

**Use this skill when:**
- Creating a new custom frontend theme based on Blank or Luma
- Setting up theme registration files (theme.xml, registration.php, composer.json)
- Configuring image dimensions via `etc/view.xml`
- Adding LESS variable overrides or custom styles
- Setting up logo and favicon overrides

**Use `/hyva-child-theme` instead when:**
- Creating a Hyva-based theme with Tailwind CSS and Alpine.js

**Use `/m2-frontend-layout` instead when:**
- Adding layout XML files, blocks, containers, or template overrides to an existing theme or module

## 2. Gather Requirements

Before generating any files, collect the following from the user.

**Required (ask if not provided):**
- **Vendor name** — PascalCase (e.g., `Acme`)
- **Theme name** — lowercase with no spaces (e.g., `custom`, `storefront`, `premium`)
- **Parent theme** — `Magento/blank` or `Magento/luma` (default: `Magento/blank`)

**Optional (use defaults if not specified):**
- **Theme title** — human-readable name (default: derived from vendor + theme name)
- **Custom logo** — path to logo file (default: none, inherits parent)
- **Custom favicon** — path to favicon file (default: none, inherits parent)
- **Preview image** — `media/preview.jpg` (default: none)
- **LESS variable overrides** — default: generate empty `_theme.less`
- **Image dimensions** — default: inherit from parent; generate `etc/view.xml` only if custom dimensions are needed

## 3. Naming Conventions

| Concept | Convention | Example |
|---------|-----------|---------|
| Theme path | `app/design/frontend/{Vendor}/{theme}` | `app/design/frontend/Acme/storefront` |
| Theme full name | `frontend/{Vendor}/{theme}` | `frontend/Acme/storefront` |
| Composer package | `{vendor-lower}/theme-frontend-{theme}` | `acme/theme-frontend-storefront` |
| Registration type | `ComponentRegistrar::THEME` | |
| LESS overrides | `web/css/source/_theme.less` | Variable overrides |
| LESS extensions | `web/css/source/_extend.less` | Custom styles added after parent |
| Logo override | `web/images/logo.svg` | |
| Favicon override | `web/favicon.ico` | |

## 4. Core File Templates (Always Generated)

### 4.1 `registration.php`

```php
<?php
/**
 * Copyright © Monsoon Consulting. All rights reserved.
 * See LICENSE_MONSOON.txt for license details.
 */

use Magento\Framework\Component\ComponentRegistrar;

ComponentRegistrar::register(ComponentRegistrar::THEME, 'frontend/{Vendor}/{theme}', __DIR__);
```

Note: No `declare(strict_types=1)` in registration.php — consistent with Magento core.

### 4.2 `theme.xml`

```xml
<?xml version="1.0"?>
<!--
/**
 * Copyright © Monsoon Consulting. All rights reserved.
 * See LICENSE_MONSOON.txt for license details.
 */
-->
<theme xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
       xsi:noNamespaceSchemaLocation="urn:magento:framework:Config/etc/theme.xsd">
    <title>{Theme Title}</title>
    <parent>{Parent/theme}</parent>
    <media>
        <preview_image>media/preview.jpg</preview_image>
    </media>
</theme>
```

Omit the `<media>` block if no preview image is provided.

### 4.3 `composer.json`

```json
{
    "name": "{vendor-lower}/theme-frontend-{theme}",
    "description": "{Theme Title} - Magento 2 frontend theme",
    "type": "magento2-theme",
    "license": [
        "proprietary"
    ],
    "version": "1.0.0",
    "require": {
        "magento/theme-frontend-{parent-theme}": "*",
        "magento/framework": "103.0.*"
    },
    "autoload": {
        "files": [
            "registration.php"
        ]
    }
}
```

For parent `Magento/blank`, require `magento/theme-frontend-blank`. For parent `Magento/luma`, require `magento/theme-frontend-luma`.

## 5. LESS Customization

### 5.1 Variable Overrides — `web/css/source/_theme.less`

Use `_theme.less` to override LESS variables from the parent theme. This file is loaded before the parent styles compile, so variable changes affect the entire theme.

```less
// Standard file header — see _shared/conventions.md

//
//  Theme variables override
//  _____________________________________________

//  Colors
@color-primary: #1a73e8;
@color-secondary: #34a853;

//  Typography
@font-family__base: 'Open Sans', 'Helvetica Neue', Helvetica, Arial, sans-serif;
@font-size__base: 14px;

//  Layout
@layout__max-width: 1280px;

//  Buttons
@button__color: @color-primary;
@button__background: @color-primary;

//  Navigation
@navigation__background: #ffffff;

//  Header
@header__background-color: #ffffff;

//  Footer
@footer__background-color: #f5f5f5;
```

### 5.2 Custom Styles — `web/css/source/_extend.less`

Use `_extend.less` to add custom styles that supplement (not replace) the parent theme styles. This file is loaded after all parent styles.

```less
// Standard file header — see _shared/conventions.md

//
//  Custom theme styles
//  _____________________________________________

& when (@media-common = true) {
    // Styles applied at all breakpoints
    .page-header {
        // Custom header styles
    }
}

//  Desktop
.media-width(@extremum, @break) when (@extremum = 'min') and (@break = @screen__m) {
    // Styles for screens >= 768px
}

//  Mobile
.media-width(@extremum, @break) when (@extremum = 'max') and (@break = @screen__m) {
    // Styles for screens < 768px
}
```

### 5.3 When to Use Each File

| File | Purpose | Load Order |
|------|---------|------------|
| `_theme.less` | Override parent LESS variables | Before parent styles compile |
| `_extend.less` | Add new CSS rules | After all parent styles |
| `_module.less` (in module override) | Override a specific module's styles | Replaces module styles |

## 6. Logo and Favicon Overrides

### 6.1 Custom Logo via Layout XML

Create `Magento_Theme/layout/default.xml`:

```xml
<?xml version="1.0"?>
<!-- Standard XML header — see _shared/conventions.md -->
<page xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
      xsi:noNamespaceSchemaLocation="urn:magento:framework:View/Layout/etc/page_configuration.xsd">
    <body>
        <referenceBlock name="logo">
            <arguments>
                <argument name="logo_file" xsi:type="string">images/logo.svg</argument>
                <argument name="logo_width" xsi:type="number">200</argument>
                <argument name="logo_height" xsi:type="number">50</argument>
                <argument name="logo_alt" xsi:type="string">{Store Name}</argument>
            </arguments>
        </referenceBlock>
    </body>
</page>
```

Place the logo file at `web/images/logo.svg`.

### 6.2 Custom Favicon

Place the favicon file at `web/favicon.ico`. Magento automatically picks it up from the theme's `web/` directory.

## 7. Image Dimensions — `etc/view.xml`

Generate `etc/view.xml` only when the user needs custom image dimensions. Otherwise, the theme inherits from the parent.

For the full reference of image dimension IDs and default values, see `references/view-xml-defaults.md`.

```xml
<?xml version="1.0"?>
<!-- Standard XML header — see _shared/conventions.md -->
<view xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
      xsi:noNamespaceSchemaLocation="urn:magento:framework:Config/etc/view.xsd">
    <media>
        <images module="Magento_Catalog">
            <image id="category_page_grid" type="small_image">
                <width>300</width>
                <height>300</height>
            </image>
            <image id="product_page_image_medium" type="image">
                <width>700</width>
                <height>700</height>
            </image>
        </images>
    </media>
</view>
```

## 8. Theme Directory Structure

```
app/design/frontend/{Vendor}/{theme}/
├── composer.json
├── registration.php
├── theme.xml
├── media/
│   └── preview.jpg                          # Theme preview image (optional)
├── etc/
│   └── view.xml                             # Image dimensions (optional)
├── web/
│   ├── css/
│   │   └── source/
│   │       ├── _theme.less                  # LESS variable overrides
│   │       └── _extend.less                 # Custom styles
│   ├── fonts/                               # Custom web fonts
│   ├── images/
│   │   └── logo.svg                         # Custom logo
│   └── favicon.ico                          # Custom favicon
├── Magento_Theme/
│   └── layout/
│       └── default.xml                      # Logo override, site-wide layout changes
├── {Vendor}_{ModuleName}/                   # Module-specific overrides
│   ├── layout/
│   │   └── {handle}.xml                     # Layout extend
│   ├── templates/
│   │   └── {path}.phtml                     # Template override
│   └── web/
│       └── css/source/
│           └── _module.less                 # Module style override
└── i18n/
    └── en_US.csv                            # Translation overrides
```

## 9. Generation Rules

Follow this sequence when scaffolding a theme:

1. **Determine parent theme** — default to `Magento/blank` unless the user specifies `Magento/luma`. Blank is preferred for clean customization; Luma is preferred when the user wants a styled starting point.

2. **Create `registration.php`** — register as `ComponentRegistrar::THEME` with path `frontend/{Vendor}/{theme}`.

3. **Create `theme.xml`** — with title and parent reference.

4. **Create `composer.json`** — with correct parent dependency.

5. **Create `web/css/source/_theme.less`** — with empty variable override template or user-specified overrides.

6. **Create `web/css/source/_extend.less`** — with empty custom styles template.

7. **Create logo override layout** — only if the user provides a custom logo. Create `Magento_Theme/layout/default.xml` and place logo file in `web/images/`.

8. **Create `etc/view.xml`** — only if the user requests custom image dimensions. Reference `references/view-xml-defaults.md` for available image IDs.

9. **Remind the user** to run post-generation commands and activate the theme.

## 10. Anti-Patterns

**Editing parent theme files directly.**
Never modify files in `vendor/magento/theme-frontend-blank/` or `vendor/magento/theme-frontend-luma/`. Always create overrides in your custom theme.

**Using `_theme.less` for custom CSS rules.**
`_theme.less` is for variable overrides only. Put custom CSS rules in `_extend.less`.

**Overriding templates when layout XML would suffice.**
Template overrides break on Magento upgrades. Use layout XML (`<referenceBlock>`, `<move>`, `<remove>`) to rearrange elements before copying and modifying templates.

**Creating `etc/view.xml` without all required image IDs.**
If you create `view.xml`, it must define all image IDs your theme uses. Missing IDs cause broken images. It is safer to inherit from the parent and only override specific IDs.

**Missing parent theme in `theme.xml`.**
The `<parent>` element is required for child themes. Without it, Magento cannot fall back to the parent for missing files.

**Placing static files outside `web/` directory.**
All CSS, JS, images, and fonts must be inside the `web/` directory. Files placed elsewhere are not served by the static content deployment pipeline.

## 11. Post-Generation Steps

After scaffolding the theme, remind the user to:

1. **Activate the theme** in the admin panel:
   **Content > Design > Configuration** > Select the store view > Choose the new theme

   Or via CLI:
   ```bash
   bin/magento config:set design/theme/theme_id {theme_id}
   ```

2. **Deploy static content and flush cache:**
   ```bash
   bin/magento setup:upgrade
   bin/magento setup:static-content:deploy -f
   bin/magento cache:flush
   ```

3. **Verify** by loading the storefront and checking:
   - The theme is active (check page source for theme path references)
   - Logo and favicon display correctly
   - LESS variable overrides apply (colors, fonts, layout width)
   - No broken images (check `etc/view.xml` if custom dimensions were set)

For further customization of layout, templates, and JS, use `/m2-frontend-layout`.
