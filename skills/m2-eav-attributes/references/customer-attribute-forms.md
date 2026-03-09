# Customer Attribute Form Codes Reference

Customer and customer address attributes must be explicitly assigned to forms via `used_in_forms`. Without this assignment, the attribute exists in the database but is invisible in all admin and storefront forms.

## Customer Form Codes

| Form Code | Area | Description |
|-----------|------|-------------|
| `adminhtml_customer` | Admin | Customer edit form in admin panel |
| `customer_account_create` | Frontend | Registration form (create account) |
| `customer_account_edit` | Frontend | "My Account > Account Information" edit form |
| `adminhtml_checkout` | Admin | Admin-created orders (customer info step) |
| `customer_account_login` | Frontend | Login form (rarely used for custom attributes) |

## Customer Address Form Codes

| Form Code | Area | Description |
|-----------|------|-------------|
| `adminhtml_customer_address` | Admin | Address edit in admin customer form |
| `customer_address_edit` | Frontend | "My Account > Address Book" edit form |
| `customer_register_address` | Frontend | Address fields on registration form |

## Recommendation Matrix

### Typical customer attribute (e.g., tax ID, company name)
```php
$attribute->setData('used_in_forms', [
    'adminhtml_customer',
    'customer_account_create',
    'customer_account_edit',
]);
```

### Admin-only customer attribute (e.g., internal notes, loyalty tier)
```php
$attribute->setData('used_in_forms', [
    'adminhtml_customer',
]);
```

### Customer attribute visible everywhere
```php
$attribute->setData('used_in_forms', [
    'adminhtml_customer',
    'adminhtml_checkout',
    'customer_account_create',
    'customer_account_edit',
]);
```

### Typical customer address attribute (e.g., delivery instructions)
```php
$attribute->setData('used_in_forms', [
    'adminhtml_customer_address',
    'customer_address_edit',
    'customer_register_address',
]);
```

### Admin-only address attribute
```php
$attribute->setData('used_in_forms', [
    'adminhtml_customer_address',
]);
```

## Form Assignment Code Pattern

Form assignment must happen **after** the attribute is created, in the same `apply()` method:

```php
// For customer attributes:
$attribute = $customerSetup->getEavConfig()
    ->getAttribute(\Magento\Customer\Model\Customer::ENTITY, '{attribute_code}');

$attribute->setData('used_in_forms', [
    'adminhtml_customer',
    'customer_account_create',
    'customer_account_edit',
]);

$attribute->getResource()->save($attribute);
```

```php
// For customer address attributes:
$attribute = $customerSetup->getEavConfig()
    ->getAttribute('customer_address', '{attribute_code}');

$attribute->setData('used_in_forms', [
    'adminhtml_customer_address',
    'customer_address_edit',
    'customer_register_address',
]);

$attribute->getResource()->save($attribute);
```

## Debugging Missing Form Attributes

If a customer attribute doesn't appear in a form:

1. **Check form assignment:**
   ```sql
   SELECT cfa.form_code, ea.attribute_code
   FROM customer_form_attribute cfa
   JOIN eav_attribute ea ON ea.attribute_id = cfa.attribute_id
   WHERE ea.attribute_code = '{attribute_code}';
   ```

2. **Check attribute exists:**
   ```sql
   SELECT * FROM eav_attribute
   WHERE attribute_code = '{attribute_code}'
   AND entity_type_id = (SELECT entity_type_id FROM eav_entity_type WHERE entity_type_code = 'customer');
   ```

3. **Check `is_visible` and `is_system`:**
   ```sql
   SELECT is_visible, is_system FROM customer_eav_attribute
   WHERE attribute_id = {attribute_id};
   ```
   `is_visible` must be `1` and `is_system` must be `0` for user-defined attributes to appear.
