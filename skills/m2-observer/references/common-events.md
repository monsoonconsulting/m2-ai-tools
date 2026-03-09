# Common Magento 2 Events Reference

## How Model Events Work

Magento models that extend `Magento\Framework\Model\AbstractModel` automatically dispatch events based on their `_eventPrefix` property. The event system generates events using this pattern:

```
{_eventPrefix}_{action}
```

**Automatic event suffixes for models:**

| Suffix | When Dispatched |
|--------|----------------|
| `_load_before` | Before loading a model by ID |
| `_load_after` | After loading a model by ID |
| `_save_before` | Before saving (inside transaction) |
| `_save_after` | After saving (inside transaction) |
| `_save_commit_after` | After save transaction commits |
| `_delete_before` | Before deleting (inside transaction) |
| `_delete_after` | After deleting (inside transaction) |
| `_delete_commit_after` | After delete transaction commits |
| `_clear` | When collection is cleared |

**Data keys for model events:**
- The model object is available via the `_eventPrefix` value as the key (e.g., `product`, `order`)
- The `_eventObject` property defines the data key name (often same as prefix)
- `data_object` is always available as an alias

## Common `_eventPrefix` Values

| Entity | `_eventPrefix` | `_eventObject` |
|--------|---------------|----------------|
| Product | `catalog_product` | `product` |
| Category | `catalog_category` | `category` |
| Order | `sales_order` | `order` |
| Quote | `sales_quote` | `quote` |
| Invoice | `sales_order_invoice` | `invoice` |
| Shipment | `sales_order_shipment` | `shipment` |
| Credit Memo | `sales_order_creditmemo` | `creditmemo` |
| Customer | `customer` | `customer` |
| Customer Address | `customer_address` | `customer_address` |
| CMS Page | `cms_page` | `page` |
| CMS Block | `cms_block` | `object` |

## Before vs After vs Commit After

| Event Type | Inside Transaction? | Use When |
|-----------|-------------------|----------|
| `_before` | Yes | Validate, modify data before persistence |
| `_after` | Yes | React to changes that need rollback support |
| `_commit_after` | No (after commit) | External API calls, async jobs, cache invalidation |

**Rule:** Use `_commit_after` for anything that cannot be rolled back (HTTP requests, queue messages, email sending). Use `_after` only when you need transaction consistency with the save.

## Catalog Events (Product & Category)

### Product Events

| Event Name | Data Keys | Area | Use Case |
|-----------|-----------|------|----------|
| `catalog_product_save_before` | `product` | Global | Modify product data before save |
| `catalog_product_save_after` | `product` | Global | React to product save (in transaction) |
| `catalog_product_save_commit_after` | `product` | Global | External sync after product save |
| `catalog_product_delete_before` | `product` | Global | Validate before product deletion |
| `catalog_product_delete_after` | `product` | Global | Cleanup after product deletion |
| `catalog_product_delete_commit_after` | `product` | Global | External cleanup after deletion committed |
| `catalog_product_load_after` | `product`, `data_object` | Global | Enrich product data after load |
| `catalog_product_is_salable_before` | `product` | Global | Modify salability check inputs |
| `catalog_product_is_salable_after` | `product`, `salable` | Global | Override salability result |
| `catalog_product_new_action` | `product` | Adminhtml | Admin: new product form init |
| `catalog_product_edit_action` | `product` | Adminhtml | Admin: edit product form init |
| `catalog_product_prepare_save` | `product`, `request` | Adminhtml | Admin: before product save from form |
| `catalog_product_attribute_update_before` | `attributes_data`, `product_ids`, `store_id` | Global | Mass attribute update starting |

### Category Events

| Event Name | Data Keys | Area | Use Case |
|-----------|-----------|------|----------|
| `catalog_category_save_before` | `category` | Global | Modify category before save |
| `catalog_category_save_after` | `category` | Global | React to category save |
| `catalog_category_save_commit_after` | `category` | Global | External sync after category save |
| `catalog_category_delete_before` | `category` | Global | Validate before category deletion |
| `catalog_category_delete_after` | `category` | Global | Cleanup after category deletion |
| `catalog_category_move_before` | `category`, `parent`, `category_id`, `prev_parent_id` | Global | Before category tree move |
| `catalog_category_move_after` | `category`, `parent`, `category_id`, `prev_parent_id` | Global | After category tree move |
| `catalog_category_prepare_save` | `category`, `request` | Adminhtml | Admin: before category save from form |

## Sales Events (Order & Quote)

### Order Events

| Event Name | Data Keys | Area | Use Case |
|-----------|-----------|------|----------|
| `sales_order_save_before` | `order` | Global | Modify order before save |
| `sales_order_save_after` | `order` | Global | React to order save |
| `sales_order_save_commit_after` | `order` | Global | External sync after order save |
| `sales_order_load_after` | `order` | Global | Enrich order after load |
| `sales_order_place_before` | `order` | Global | Validate before order placement |
| `sales_order_place_after` | `order` | Global | React after order placement |
| `order_cancel_after` | `order` | Global | React to order cancellation |
| `sales_order_payment_pay` | `payment`, `invoice` | Global | Payment captured |
| `sales_order_invoice_save_after` | `invoice` | Global | React to invoice save |
| `sales_order_shipment_save_after` | `shipment` | Global | React to shipment save |
| `sales_order_creditmemo_save_after` | `creditmemo` | Global | React to credit memo save |

### Quote Events

| Event Name | Data Keys | Area | Use Case |
|-----------|-----------|------|----------|
| `sales_quote_save_before` | `quote` | Global | Modify quote before save |
| `sales_quote_save_after` | `quote` | Global | React to quote save |
| `sales_quote_item_qty_set_after` | `item` | Global | React to qty change in cart |
| `sales_quote_remove_item` | `quote_item` | Global | React to item removal from cart |
| `sales_quote_add_item` | `quote_item` | Global | React to item added to cart |
| `sales_quote_product_add_after` | `items` | Global | After product added to quote |
| `checkout_cart_add_product_complete` | `product`, `request` | Frontend | Cart add completed |
| `checkout_cart_update_items_after` | `cart`, `info` | Frontend | After cart item quantities updated |

## Customer Events

| Event Name | Data Keys | Area | Use Case |
|-----------|-----------|------|----------|
| `customer_save_before` | `customer` | Global | Modify customer before save |
| `customer_save_after` | `customer` | Global | React to customer save |
| `customer_save_commit_after` | `customer` | Global | External sync after customer save |
| `customer_delete_before` | `customer` | Global | Validate before customer deletion |
| `customer_delete_after` | `customer` | Global | Cleanup after customer deletion |
| `customer_register_success` | `account_controller`, `customer` | Frontend | Successful registration |
| `customer_login` | `customer` | Frontend | Customer logged in |
| `customer_logout` | `customer` | Frontend | Customer logged out |
| `customer_address_save_before` | `customer_address` | Global | Before address save |
| `customer_address_save_after` | `customer_address` | Global | After address save |

## CMS Events

| Event Name | Data Keys | Area | Use Case |
|-----------|-----------|------|----------|
| `cms_page_save_before` | `page` | Global | Modify CMS page before save |
| `cms_page_save_after` | `page` | Global | React to CMS page save |
| `cms_page_delete_before` | `page` | Global | Before CMS page deletion |
| `cms_page_delete_after` | `page` | Global | After CMS page deletion |
| `cms_block_save_before` | `object` | Global | Before CMS block save |
| `cms_block_save_after` | `object` | Global | After CMS block save |
| `cms_page_render` | `page`, `controller_action` | Frontend | Before CMS page renders |

## Admin & Controller Events

| Event Name | Data Keys | Area | Use Case |
|-----------|-----------|------|----------|
| `controller_action_predispatch` | `controller_action`, `request` | Global | Before any controller action |
| `controller_action_predispatch_{route}_{controller}_{action}` | `controller_action`, `request` | Global | Before specific controller action |
| `controller_action_postdispatch` | `controller_action`, `request`, `response` | Global | After any controller action |
| `controller_action_postdispatch_{route}_{controller}_{action}` | `controller_action`, `request`, `response` | Global | After specific controller action |
| `backend_auth_user_login_success` | `user` | Adminhtml | Admin user logged in |
| `backend_auth_user_login_failed` | `user_name`, `exception` | Adminhtml | Admin login failed |
| `admin_system_config_changed_section_{section}` | `website`, `store` | Adminhtml | Admin config section saved |
| `adminhtml_cache_flush_all` | — | Adminhtml | All caches flushed from admin |

## Checkout Events

| Event Name | Data Keys | Area | Use Case |
|-----------|-----------|------|----------|
| `checkout_submit_all_after` | `order`, `quote` | Global | After order submitted from checkout |
| `checkout_onepage_controller_success_action` | `order_ids` | Frontend | Checkout success page loaded |
| `checkout_type_onepage_save_order_after` | `order`, `quote` | Frontend | After order saved in one-page checkout |
| `payment_method_is_active` | `result`, `method_instance`, `quote` | Global | Payment method availability check |
| `checkout_allow_guest` | `quote`, `store`, `result` | Global | Guest checkout permission check |

## Layout and Rendering Events

| Event Name | Data Keys | Area | Use Case |
|-----------|-----------|------|----------|
| `layout_load_before` | `full_action_name`, `layout` | Global | Before layout XML is loaded |
| `layout_generate_blocks_after` | `full_action_name`, `layout` | Global | After layout blocks generated |
| `layout_render_before` | `layout` | Global | Before layout renders output |
| `view_block_abstract_to_html_before` | `block` | Global | Before block renders to HTML |
| `view_block_abstract_to_html_after` | `block`, `transport` | Global | After block renders to HTML |

## Store and Config Events

| Event Name | Data Keys | Area | Use Case |
|-----------|-----------|------|----------|
| `store_add` | `store` | Global | New store created |
| `store_delete` | `store` | Global | Store deleted |
| `admin_system_config_changed_section_{section}` | `website`, `store` | Adminhtml | Config section saved |
| `core_config_data_save_before` | `data_object` | Global | Before config value save |
| `core_config_data_save_after` | `data_object` | Global | After config value save |
| `clean_cache_by_tags` | `object` | Global | Cache tags cleaned |
