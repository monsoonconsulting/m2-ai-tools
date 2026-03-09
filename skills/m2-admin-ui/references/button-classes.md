# Button Classes

All buttons implement `Magento\Framework\View\Element\UiComponent\Control\ButtonProviderInterface`.

## GenericButton (Base Class) — `Block/Adminhtml/{Entity}/Edit/GenericButton.php`

This is the only button class that is NOT `final` — it serves as a base for all entity-specific buttons.

```php
<?php
/**
 * Copyright © Monsoon Consulting. All rights reserved.
 * See LICENSE_MONSOON.txt for license details.
 */

declare(strict_types=1);

namespace {Vendor}\{ModuleName}\Block\Adminhtml\{Entity}\Edit;

use Magento\Backend\Block\Widget\Context;

class GenericButton
{
    public function __construct(
        private readonly Context $context
    ) {
    }

    public function getEntityId(): ?int
    {
        $id = $this->context->getRequest()->getParam('{primary_key}');

        return $id ? (int) $id : null;
    }

    public function getUrl(string $route = '', array $params = []): string
    {
        return $this->context->getUrlBuilder()->getUrl($route, $params);
    }
}
```

## BackButton — `Block/Adminhtml/{Entity}/Edit/BackButton.php`

```php
<?php
/**
 * Copyright © Monsoon Consulting. All rights reserved.
 * See LICENSE_MONSOON.txt for license details.
 */

declare(strict_types=1);

namespace {Vendor}\{ModuleName}\Block\Adminhtml\{Entity}\Edit;

use Magento\Framework\View\Element\UiComponent\Control\ButtonProviderInterface;

final class BackButton extends GenericButton implements ButtonProviderInterface
{
    public function getButtonData(): array
    {
        return [
            'label' => __('Back'),
            'on_click' => sprintf("location.href = '%s';", $this->getUrl('*/*/')),
            'class' => 'back',
            'sort_order' => 10,
        ];
    }
}
```

## SaveButton — `Block/Adminhtml/{Entity}/Edit/SaveButton.php`

Includes a "Save & Continue Edit" dropdown option.

```php
<?php
/**
 * Copyright © Monsoon Consulting. All rights reserved.
 * See LICENSE_MONSOON.txt for license details.
 */

declare(strict_types=1);

namespace {Vendor}\{ModuleName}\Block\Adminhtml\{Entity}\Edit;

use Magento\Framework\View\Element\UiComponent\Control\ButtonProviderInterface;

final class SaveButton extends GenericButton implements ButtonProviderInterface
{
    public function getButtonData(): array
    {
        return [
            'label' => __('Save'),
            'class' => 'save primary',
            'data_attribute' => [
                'mage-init' => [
                    'buttonAdapter' => [
                        'actions' => [
                            [
                                'targetName' => '{entity_snake}_form.{entity_snake}_form',
                                'actionName' => 'save',
                                'params' => [false],
                            ],
                        ],
                    ],
                ],
            ],
            'class_name' => \Magento\Backend\Block\Widget\Button\SplitButton::class,
            'options' => $this->getOptions(),
            'sort_order' => 90,
        ];
    }

    private function getOptions(): array
    {
        return [
            [
                'id_hard' => 'save_and_continue',
                'label' => __('Save & Continue Edit'),
                'data_attribute' => [
                    'mage-init' => [
                        'buttonAdapter' => [
                            'actions' => [
                                [
                                    'targetName' => '{entity_snake}_form.{entity_snake}_form',
                                    'actionName' => 'save',
                                    'params' => [true, ['back' => 'edit']],
                                ],
                            ],
                        ],
                    ],
                ],
            ],
        ];
    }
}
```

## DeleteButton — `Block/Adminhtml/{Entity}/Edit/DeleteButton.php`

Only shown when editing an existing entity (not on "new" form).

```php
<?php
/**
 * Copyright © Monsoon Consulting. All rights reserved.
 * See LICENSE_MONSOON.txt for license details.
 */

declare(strict_types=1);

namespace {Vendor}\{ModuleName}\Block\Adminhtml\{Entity}\Edit;

use Magento\Framework\View\Element\UiComponent\Control\ButtonProviderInterface;

final class DeleteButton extends GenericButton implements ButtonProviderInterface
{
    public function getButtonData(): array
    {
        if (!$this->getEntityId()) {
            return [];
        }

        return [
            'label' => __('Delete'),
            'class' => 'delete',
            'on_click' => sprintf(
                "deleteConfirm('%s', '%s', {data: {}})",
                __('Are you sure you want to delete this record?'),
                $this->getUrl('*/*/delete', ['{primary_key}' => $this->getEntityId()])
            ),
            'sort_order' => 20,
        ];
    }
}
```

## Notes

- **GenericButton** is intentionally `class` (not `final`) because the button subclasses extend it.
- The `{entity_snake}_form.{entity_snake}_form` target in SaveButton must match the form UI component namespace.
- DeleteButton returns an empty array for new entities (no ID) so it's not rendered on the "Add New" form.
- The `on_click` for DeleteButton uses `deleteConfirm()` which is a built-in Magento JS function that shows a confirmation dialog before sending a POST request.
