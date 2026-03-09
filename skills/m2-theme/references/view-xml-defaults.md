# etc/view.xml Image Dimension Reference

The `etc/view.xml` file configures image dimensions for product images, category images, and thumbnails. All image IDs belong to `module="Magento_Catalog"` unless noted otherwise.

## Common Product Image IDs

| Image ID | Type | Default Width | Default Height | Used On |
|----------|------|--------------|----------------|---------|
| `product_page_image_medium` | `image` | 700 | 700 | PDP main image |
| `product_page_image_large` | `image` | 700 | 700 | PDP fullscreen/zoom |
| `product_page_image_small` | `thumbnail` | 88 | 110 | PDP thumbnail strip |
| `product_page_more_views` | `thumbnail` | 88 | 110 | PDP "More Views" |
| `category_page_grid` | `small_image` | 240 | 300 | Category grid view |
| `category_page_list` | `small_image` | 240 | 300 | Category list view |
| `product_small_image` | `small_image` | 135 | 135 | Cross-sells, related |
| `product_thumbnail_image` | `thumbnail` | 75 | 75 | Cart, mini-cart |
| `product_base_image` | `image` | 265 | 265 | Widgets, recently viewed |
| `product_swatch_image_small` | `swatch_image` | 30 | 30 | Swatch thumbnail |
| `product_swatch_image_medium` | `swatch_image` | 95 | 95 | Swatch tooltip |
| `product_swatch_image_large` | `swatch_image` | 143 | 143 | Swatch listing |
| `recently_viewed_products_grid_content_widget` | `small_image` | 240 | 300 | Recently viewed widget |
| `recently_viewed_products_images_names_widget` | `small_image` | 240 | 300 | Recently viewed widget |
| `recently_compared_products_grid_content_widget` | `small_image` | 240 | 300 | Compare widget |
| `new_products_content_widget_grid` | `small_image` | 240 | 300 | New products widget |
| `cart_cross_sell_products` | `thumbnail` | 200 | 248 | Cart cross-sells |
| `mini_cart_product_thumbnail` | `thumbnail` | 75 | 75 | Mini-cart items |

## XML Structure

```xml
<?xml version="1.0"?>
<view xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
      xsi:noNamespaceSchemaLocation="urn:magento:framework:Config/etc/view.xsd">
    <media>
        <images module="Magento_Catalog">
            <image id="{image_id}" type="{type}">
                <width>{width}</width>
                <height>{height}</height>
            </image>
        </images>
    </media>
</view>
```

## Image Types

| Type | Description |
|------|-------------|
| `image` | Base/main product image |
| `small_image` | Used in listings, grids, widgets |
| `thumbnail` | Small thumbnail (cart, galleries) |
| `swatch_image` | Color/visual swatch images |
| `swatch_thumb` | Swatch thumbnails in layered nav |

## Optional Attributes

Each `<image>` element can include additional child elements:

```xml
<image id="category_page_grid" type="small_image">
    <width>300</width>
    <height>300</height>
    <frame>true</frame>           <!-- Keep aspect ratio with padding (true/false) -->
    <constrain>true</constrain>   <!-- Constrain image within dimensions -->
    <aspect_ratio>true</aspect_ratio>  <!-- Maintain aspect ratio -->
    <transparency>true</transparency>  <!-- Preserve PNG transparency -->
    <background>[255,255,255]</background>  <!-- Background fill color (RGB) -->
</image>
```

## Tips

- Only override image IDs you want to change. Unspecified IDs inherit from the parent theme.
- After changing `view.xml`, flush the image cache: `bin/magento catalog:images:resize`
- Use `frame=false` for product grid images to avoid whitespace padding around non-square images.
- The `background` attribute accepts an RGB array and fills transparent areas on resize.
