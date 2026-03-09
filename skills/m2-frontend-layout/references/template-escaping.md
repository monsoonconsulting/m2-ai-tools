# Template Escaping Reference

Complete reference for `$escaper` methods in Magento 2 phtml templates.

## Escaper Methods

### `escapeHtml()`

Escapes HTML entities. Use for all general text output.

```php
<!-- Plain text -->
<p><?= $escaper->escapeHtml($viewModel->getTitle()) ?></p>

<!-- Translatable text -->
<span><?= $escaper->escapeHtml(__('Add to Cart')) ?></span>

<!-- With allowed tags (second argument = array of allowed tag names) -->
<div><?= $escaper->escapeHtml($viewModel->getDescription(), ['br', 'strong', 'em', 'a', 'p']) ?></div>
```

### `escapeHtmlAttr()`

Escapes values for use inside HTML attributes.

```php
<div class="<?= $escaper->escapeHtmlAttr($viewModel->getCssClass()) ?>">
<input type="text" value="<?= $escaper->escapeHtmlAttr($viewModel->getValue()) ?>"
       placeholder="<?= $escaper->escapeHtmlAttr(__('Search...')) ?>">
<div data-config="<?= $escaper->escapeHtmlAttr($viewModel->getJsonConfig()) ?>">
```

### `escapeUrl()`

Escapes URLs. Use for `href`, `src`, `action`, and any URL attribute.

```php
<a href="<?= $escaper->escapeUrl($block->getUrl('route/action')) ?>">Link</a>
<img src="<?= $escaper->escapeUrl($viewModel->getImageUrl()) ?>" alt=""/>
<form action="<?= $escaper->escapeUrl($block->getUrl('route/action')) ?>" method="post">
```

### `escapeJs()`

Escapes values for use inside JavaScript string literals.

```php
<script type="text/x-magento-init">
{
    "#element": {
        "component": {
            "value": "<?= $escaper->escapeJs($viewModel->getValue()) ?>"
        }
    }
}
</script>
```

### `escapeCss()`

Escapes values for use inside CSS declarations.

```php
<div style="background-color: <?= $escaper->escapeCss($viewModel->getColor()) ?>">
```

## Quick Reference Table

| Context | Method | Example |
|---------|--------|---------|
| Text content | `escapeHtml()` | `<p><?= $escaper->escapeHtml($val) ?></p>` |
| Rich text | `escapeHtml($val, ['br','a'])` | Content with allowed HTML tags |
| Attribute value | `escapeHtmlAttr()` | `class="<?= $escaper->escapeHtmlAttr($val) ?>"` |
| URL (href/src) | `escapeUrl()` | `href="<?= $escaper->escapeUrl($url) ?>"` |
| JS string | `escapeJs()` | `"value": "<?= $escaper->escapeJs($val) ?>"` |
| CSS value | `escapeCss()` | `color: <?= $escaper->escapeCss($val) ?>` |
| Integer | `(int)` cast | `<?= (int)$viewModel->getCount() ?>` |

## Common Template Patterns

### Links

```php
<a href="<?= $escaper->escapeUrl($block->getUrl('customer/account')) ?>">
    <?= $escaper->escapeHtml(__('My Account')) ?>
</a>
```

### POST form

```php
<form action="<?= $escaper->escapeUrl($block->getUrl('module/controller/action')) ?>"
      method="post"
      data-mage-init='{"validation": {}}'>
    <?= $block->getBlockHtml('formkey') ?>

    <input type="text"
           name="field_name"
           value="<?= $escaper->escapeHtmlAttr($viewModel->getFieldValue()) ?>"
           title="<?= $escaper->escapeHtmlAttr(__('Field Label')) ?>"/>

    <button type="submit">
        <?= $escaper->escapeHtml(__('Submit')) ?>
    </button>
</form>
```

### Conditional rendering

```php
<?php if ($viewModel->isEnabled()): ?>
    <div class="feature-block">
        <?= $escaper->escapeHtml($viewModel->getContent()) ?>
    </div>
<?php endif; ?>
```

### Loop

```php
<?php foreach ($viewModel->getItems() as $item): ?>
    <li class="<?= $escaper->escapeHtmlAttr($item->getCssClass()) ?>">
        <a href="<?= $escaper->escapeUrl($item->getUrl()) ?>">
            <?= $escaper->escapeHtml($item->getName()) ?>
        </a>
    </li>
<?php endforeach; ?>
```

### Child block rendering

```php
<!-- Render a specific named child block -->
<?= $block->getChildHtml('child.block.alias') ?>

<!-- Render all child blocks -->
<?= $block->getChildHtml() ?>
```

## Complete Starter Template

```php
<?php
/**
 * Copyright © Monsoon Consulting. All rights reserved.
 * See LICENSE_MONSOON.txt for license details.
 */

/** @var \Magento\Framework\View\Element\Template $block */
/** @var \Magento\Framework\Escaper $escaper */
/** @var \Vendor\ModuleName\ViewModel\MyViewModel $viewModel */
$viewModel = $block->getData('view_model');
?>
<div class="my-component">
    <?php if ($viewModel->hasItems()): ?>
        <h2><?= $escaper->escapeHtml(__('Items')) ?></h2>
        <ul>
            <?php foreach ($viewModel->getItems() as $item): ?>
                <li>
                    <a href="<?= $escaper->escapeUrl($item->getUrl()) ?>">
                        <?= $escaper->escapeHtml($item->getName()) ?>
                    </a>
                    <span class="price"><?= $escaper->escapeHtml($item->getFormattedPrice()) ?></span>
                </li>
            <?php endforeach; ?>
        </ul>
    <?php else: ?>
        <p><?= $escaper->escapeHtml(__('No items found.')) ?></p>
    <?php endif; ?>
</div>
```
