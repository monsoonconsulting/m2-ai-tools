# Column Types & Constraints Reference

> Companion file for m2-db-schema. Referenced from SKILL.md.

## Column Types Reference

### Integer Types

| xsi:type | MySQL Type | Attributes | Use Case |
|----------|-----------|------------|----------|
| `int` | INT | `unsigned`, `nullable`, `identity`, `default` | Standard IDs, quantities |
| `smallint` | SMALLINT | `unsigned`, `nullable`, `identity`, `default` | Status codes, small counts |
| `bigint` | BIGINT | `unsigned`, `nullable`, `identity`, `default` | Large IDs, timestamps as int |
| `tinyint` | TINYINT | `unsigned`, `nullable`, `identity`, `default` | Boolean-like flags |

### String Types

| xsi:type | MySQL Type | Attributes | Use Case |
|----------|-----------|------------|----------|
| `varchar` | VARCHAR | `length`, `nullable`, `default` | Names, titles, short text |
| `text` | TEXT | `nullable` | Descriptions, long content |
| `mediumtext` | MEDIUMTEXT | `nullable` | Serialized data, large content |
| `longtext` | LONGTEXT | `nullable` | Very large serialized/JSON data |
| `blob` | BLOB | `nullable` | Binary data |
| `varbinary` | VARBINARY | `length`, `nullable`, `default` | Short binary data, hashes |

### Real (Decimal/Float) Types

| xsi:type | MySQL Type | Attributes | Use Case |
|----------|-----------|------------|----------|
| `decimal` | DECIMAL | `precision`, `scale`, `unsigned`, `nullable`, `default` | Prices, weights, exact decimals |
| `float` | FLOAT | `unsigned`, `nullable`, `default` | Approximate decimals |
| `double` | DOUBLE | `unsigned`, `nullable`, `default` | High-range approximate decimals |

### Date/Time Types

| xsi:type | MySQL Type | Attributes | Use Case |
|----------|-----------|------------|----------|
| `datetime` | DATETIME | `nullable`, `default`, `on_update` | Timestamps (created_at, updated_at) |
| `timestamp` | TIMESTAMP | `nullable`, `default`, `on_update` | Auto-updating timestamps |
| `date` | DATE | `nullable`, `default` | Date-only values |

### Other Types

| xsi:type | MySQL Type | Attributes | Use Case |
|----------|-----------|------------|----------|
| `boolean` | TINYINT(1) | `nullable`, `default` | True/false flags |
| `json` | JSON | `nullable` | Structured JSON data |

### Common Attribute Patterns

**Auto-increment primary key:**
```xml
<column xsi:type="int" name="entity_id" unsigned="true" nullable="false" identity="true" comment="Entity ID"/>
```

**Price column** (matches Magento core `sales_order.grand_total`, etc.):
```xml
<column xsi:type="decimal" name="price" precision="20" scale="4" unsigned="false" nullable="false" default="0" comment="Price"/>
```

**Quantity column:**
```xml
<column xsi:type="decimal" name="qty" precision="12" scale="4" unsigned="false" nullable="false" default="0" comment="Quantity"/>
```

**Timestamps (created_at / updated_at):**
```xml
<column xsi:type="timestamp" name="created_at" nullable="false" default="CURRENT_TIMESTAMP" comment="Created At"/>
<column xsi:type="timestamp" name="updated_at" nullable="false" default="CURRENT_TIMESTAMP" on_update="true" comment="Updated At"/>
```

**Boolean flag:**
```xml
<column xsi:type="boolean" name="is_active" nullable="false" default="true" comment="Is Active"/>
```

**Store ID (for store-scoped tables):**
```xml
<column xsi:type="smallint" name="store_id" unsigned="true" nullable="false" default="0" comment="Store ID"/>
```

## Constraint & Index Reference

### Constraints

**Primary key:**
```xml
<constraint xsi:type="primary" referenceId="PRIMARY">
    <column name="entity_id"/>
</constraint>
```

**Composite primary key:**
```xml
<constraint xsi:type="primary" referenceId="PRIMARY">
    <column name="entity_id"/>
    <column name="store_id"/>
</constraint>
```

**Unique constraint:**
```xml
<constraint xsi:type="unique" referenceId="ACME_BLOG_POST___URL_KEY">
    <column name="url_key"/>
</constraint>
```

**Foreign key:**
```xml
<constraint xsi:type="foreign"
            referenceId="ACME_BLOG_POST__STORE_ID___STORE__STORE_ID"
            table="acme_blog_post"
            column="store_id"
            referenceTable="store"
            referenceColumn="store_id"
            onDelete="CASCADE"/>
```

`onDelete` options: `CASCADE` (delete child rows), `SET NULL` (set FK column to null), `NO ACTION` (prevent delete), `RESTRICT` (same as NO ACTION).

- Use `CASCADE` for child/association tables (e.g., store-scoped link tables)
- Use `SET NULL` when the child row should survive parent deletion (requires `nullable="true"` on FK column)
- Use `NO ACTION` or `RESTRICT` when parent deletion must be explicitly handled

### Indexes

**B-tree index (default, most common):**
```xml
<index referenceId="ACME_BLOG_POST___STATUS" indexType="btree">
    <column name="status"/>
</index>
```

**Composite index:**
```xml
<index referenceId="ACME_BLOG_POST___STATUS___CREATED_AT" indexType="btree">
    <column name="status"/>
    <column name="created_at"/>
</index>
```

**Fulltext index (for search):**
```xml
<index referenceId="ACME_BLOG_POST___TITLE___CONTENT" indexType="fulltext">
    <column name="title"/>
    <column name="content"/>
</index>
```

Index types: `btree` (default, range + equality), `fulltext` (text search), `hash` (exact equality only).

### Table Attributes

```xml
<table name="acme_blog_post" resource="default" engine="innodb" comment="Blog Posts">
```

- `resource` — database connection: `default`, `checkout`, `sales` (use `default` unless the table belongs to checkout or sales domain)
- `engine` — always `innodb` (MyISAM is not supported for declarative schema)
- `comment` — human-readable table description
