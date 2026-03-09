# Admin Controller Templates

All controllers extend `Magento\Backend\App\Action` and implement the appropriate `Http*ActionInterface`.

## Index Controller — `Controller/Adminhtml/{Entity}/Index.php`

```php
<?php
/**
 * Copyright © Monsoon Consulting. All rights reserved.
 * See LICENSE_MONSOON.txt for license details.
 */

declare(strict_types=1);

namespace {Vendor}\{ModuleName}\Controller\Adminhtml\{Entity};

use Magento\Backend\App\Action;
use Magento\Backend\App\Action\Context;
use Magento\Framework\App\Action\HttpGetActionInterface;
use Magento\Framework\View\Result\PageFactory;
use Magento\Framework\View\Result\Page;

class Index extends Action implements HttpGetActionInterface
{
    public const ADMIN_RESOURCE = '{Vendor}_{ModuleName}::{entity_snake}';

    public function __construct(
        Context $context,
        private readonly PageFactory $resultPageFactory
    ) {
        parent::__construct($context);
    }

    public function execute(): Page
    {
        $resultPage = $this->resultPageFactory->create();
        $resultPage->setActiveMenu('{Vendor}_{ModuleName}::{entity_snake}');
        $resultPage->getConfig()->getTitle()->prepend(__('Manage {Entity Label}'));

        return $resultPage;
    }
}
```

## Edit Controller — `Controller/Adminhtml/{Entity}/Edit.php`

```php
<?php
/**
 * Copyright © Monsoon Consulting. All rights reserved.
 * See LICENSE_MONSOON.txt for license details.
 */

declare(strict_types=1);

namespace {Vendor}\{ModuleName}\Controller\Adminhtml\{Entity};

use Magento\Backend\App\Action;
use Magento\Backend\App\Action\Context;
use Magento\Framework\App\Action\HttpGetActionInterface;
use Magento\Framework\View\Result\PageFactory;
use Magento\Framework\View\Result\Page;
use {Vendor}\{ModuleName}\Api\{Entity}RepositoryInterface;
use Magento\Framework\Exception\NoSuchEntityException;

class Edit extends Action implements HttpGetActionInterface
{
    public const ADMIN_RESOURCE = '{Vendor}_{ModuleName}::{entity_snake}';

    public function __construct(
        Context $context,
        private readonly PageFactory $resultPageFactory,
        private readonly {Entity}RepositoryInterface $repository
    ) {
        parent::__construct($context);
    }

    public function execute(): Page|\Magento\Framework\Controller\Result\Redirect
    {
        $id = (int) $this->getRequest()->getParam('{primary_key}');

        if ($id) {
            try {
                $this->repository->getById($id);
            } catch (NoSuchEntityException) {
                $this->messageManager->addErrorMessage(__('This record no longer exists.'));
                return $this->resultRedirectFactory->create()->setPath('*/*/');
            }
        }

        $resultPage = $this->resultPageFactory->create();
        $resultPage->setActiveMenu('{Vendor}_{ModuleName}::{entity_snake}');
        $resultPage->getConfig()->getTitle()->prepend(
            $id ? __('Edit {Entity Label}') : __('New {Entity Label}')
        );

        return $resultPage;
    }
}
```

**If no repository exists**, replace the repository check with a direct model load:

```php
// Alternative: direct model load (no repository)
use {Vendor}\{ModuleName}\Model\{Entity}Factory;

// In constructor:
private readonly {Entity}Factory $entityFactory

// In execute():
if ($id) {
    $entity = $this->entityFactory->create();
    $this->resource->load($entity, $id);
    if (!$entity->getId()) {
        $this->messageManager->addErrorMessage(__('This record no longer exists.'));
        return $this->resultRedirectFactory->create()->setPath('*/*/');
    }
}
```

## NewAction Controller — `Controller/Adminhtml/{Entity}/NewAction.php`

```php
<?php
/**
 * Copyright © Monsoon Consulting. All rights reserved.
 * See LICENSE_MONSOON.txt for license details.
 */

declare(strict_types=1);

namespace {Vendor}\{ModuleName}\Controller\Adminhtml\{Entity};

use Magento\Backend\App\Action;
use Magento\Framework\App\Action\HttpGetActionInterface;
use Magento\Framework\Controller\ResultFactory;
use Magento\Framework\Controller\Result\Forward;

class NewAction extends Action implements HttpGetActionInterface
{
    public const ADMIN_RESOURCE = '{Vendor}_{ModuleName}::{entity_snake}_save';

    public function execute(): Forward
    {
        /** @var Forward $resultForward */
        $resultForward = $this->resultFactory->create(ResultFactory::TYPE_FORWARD);

        return $resultForward->forward('edit');
    }
}
```

## Save Controller — `Controller/Adminhtml/{Entity}/Save.php`

```php
<?php
/**
 * Copyright © Monsoon Consulting. All rights reserved.
 * See LICENSE_MONSOON.txt for license details.
 */

declare(strict_types=1);

namespace {Vendor}\{ModuleName}\Controller\Adminhtml\{Entity};

use Magento\Backend\App\Action;
use Magento\Backend\App\Action\Context;
use Magento\Framework\App\Action\HttpPostActionInterface;
use Magento\Framework\App\Request\DataPersistorInterface;
use Magento\Framework\Controller\Result\Redirect;
use Magento\Framework\Exception\LocalizedException;
use {Vendor}\{ModuleName}\Api\{Entity}RepositoryInterface;
use {Vendor}\{ModuleName}\Model\{Entity}Factory;

class Save extends Action implements HttpPostActionInterface
{
    public const ADMIN_RESOURCE = '{Vendor}_{ModuleName}::{entity_snake}_save';

    public function __construct(
        Context $context,
        private readonly {Entity}RepositoryInterface $repository,
        private readonly {Entity}Factory $entityFactory,
        private readonly DataPersistorInterface $dataPersistor
    ) {
        parent::__construct($context);
    }

    public function execute(): Redirect
    {
        $resultRedirect = $this->resultRedirectFactory->create();
        $data = $this->getRequest()->getPostValue();

        if (empty($data)) {
            return $resultRedirect->setPath('*/*/');
        }

        $id = (int) ($data['{primary_key}'] ?? 0);

        try {
            $entity = $id ? $this->repository->getById($id) : $this->entityFactory->create();
            $entity->setData($data);
            $this->repository->save($entity);
            $this->messageManager->addSuccessMessage(__('The record has been saved.'));
            $this->dataPersistor->clear('{entity_snake}');

            if ($this->getRequest()->getParam('back') === 'edit') {
                return $resultRedirect->setPath('*/*/edit', ['{primary_key}' => $entity->getId()]);
            }

            return $resultRedirect->setPath('*/*/');
        } catch (LocalizedException $e) {
            $this->messageManager->addErrorMessage($e->getMessage());
        } catch (\Exception $e) {
            $this->messageManager->addExceptionMessage($e, __('Something went wrong while saving the record.'));
        }

        $this->dataPersistor->set('{entity_snake}', $data);

        if ($id) {
            return $resultRedirect->setPath('*/*/edit', ['{primary_key}' => $id]);
        }

        return $resultRedirect->setPath('*/*/new');
    }
}
```

**If no repository exists**, replace repository calls with direct ResourceModel operations:

```php
// Alternative: direct ResourceModel (no repository)
use {Vendor}\{ModuleName}\Model\{Entity}Factory;
use {Vendor}\{ModuleName}\Model\ResourceModel\{Entity} as {Entity}Resource;

// In constructor:
private readonly {Entity}Factory $entityFactory,
private readonly {Entity}Resource $resource

// In execute():
$entity = $this->entityFactory->create();
if ($id) {
    $this->resource->load($entity, $id);
}
$entity->setData($data);
$this->resource->save($entity);
```

## Delete Controller — `Controller/Adminhtml/{Entity}/Delete.php`

```php
<?php
/**
 * Copyright © Monsoon Consulting. All rights reserved.
 * See LICENSE_MONSOON.txt for license details.
 */

declare(strict_types=1);

namespace {Vendor}\{ModuleName}\Controller\Adminhtml\{Entity};

use Magento\Backend\App\Action;
use Magento\Backend\App\Action\Context;
use Magento\Framework\App\Action\HttpPostActionInterface;
use Magento\Framework\Controller\Result\Redirect;
use {Vendor}\{ModuleName}\Api\{Entity}RepositoryInterface;

class Delete extends Action implements HttpPostActionInterface
{
    public const ADMIN_RESOURCE = '{Vendor}_{ModuleName}::{entity_snake}_delete';

    public function __construct(
        Context $context,
        private readonly {Entity}RepositoryInterface $repository
    ) {
        parent::__construct($context);
    }

    public function execute(): Redirect
    {
        $resultRedirect = $this->resultRedirectFactory->create();
        $id = (int) $this->getRequest()->getParam('{primary_key}');

        if (!$id) {
            $this->messageManager->addErrorMessage(__('We can\'t find the record to delete.'));
            return $resultRedirect->setPath('*/*/');
        }

        try {
            $this->repository->deleteById($id);
            $this->messageManager->addSuccessMessage(__('The record has been deleted.'));
        } catch (\Exception $e) {
            $this->messageManager->addErrorMessage($e->getMessage());
        }

        return $resultRedirect->setPath('*/*/');
    }
}
```

## MassDelete Controller — `Controller/Adminhtml/{Entity}/MassDelete.php`

```php
<?php
/**
 * Copyright © Monsoon Consulting. All rights reserved.
 * See LICENSE_MONSOON.txt for license details.
 */

declare(strict_types=1);

namespace {Vendor}\{ModuleName}\Controller\Adminhtml\{Entity};

use Magento\Backend\App\Action;
use Magento\Backend\App\Action\Context;
use Magento\Framework\App\Action\HttpPostActionInterface;
use Magento\Framework\Controller\Result\Redirect;
use Magento\Ui\Component\MassAction\Filter;
use {Vendor}\{ModuleName}\Model\ResourceModel\{Entity}\CollectionFactory;
use {Vendor}\{ModuleName}\Api\{Entity}RepositoryInterface;

class MassDelete extends Action implements HttpPostActionInterface
{
    public const ADMIN_RESOURCE = '{Vendor}_{ModuleName}::{entity_snake}_delete';

    public function __construct(
        Context $context,
        private readonly Filter $filter,
        private readonly CollectionFactory $collectionFactory,
        private readonly {Entity}RepositoryInterface $repository
    ) {
        parent::__construct($context);
    }

    public function execute(): Redirect
    {
        $collection = $this->filter->getCollection($this->collectionFactory->create());
        $count = 0;

        foreach ($collection as $entity) {
            try {
                $this->repository->delete($entity);
                $count++;
            } catch (\Exception $e) {
                $this->messageManager->addErrorMessage($e->getMessage());
            }
        }

        if ($count) {
            $this->messageManager->addSuccessMessage(
                __('A total of %1 record(s) have been deleted.', $count)
            );
        }

        return $this->resultRedirectFactory->create()->setPath('*/*/');
    }
}
```

## Notes

- **ADMIN_RESOURCE** must exactly match an `<resource id="...">` in `acl.xml`. If it doesn't match, the controller returns a 403 Forbidden.
- **NewAction** simply forwards to Edit — this avoids duplicating the form page. The Edit controller checks whether an ID is present to determine new vs. edit mode.
- **Save controller `back` param** — the "Save & Continue Edit" button sends `back=edit` to redirect back to the form after saving.
- **DataPersistor** key (`{entity_snake}`) must match the key used in the DataProvider to repopulate the form after validation errors.
