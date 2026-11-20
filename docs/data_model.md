# Data Model — Olist Star Schema

Two facts at different grains + four conformed dimensions. Built in dbt (`olist_dbt/models/marts`).

```mermaid
erDiagram
    dim_customers ||--o{ fct_orders : "customer_unique_id"
    dim_date      ||--o{ fct_orders : "purchase_date"
    fct_orders    ||--|{ fct_order_items : "order_id"
    dim_products  ||--o{ fct_order_items : "product_id"
    dim_sellers   ||--o{ fct_order_items : "seller_id"
    dim_customers ||--o{ fct_order_items : "customer_unique_id"
    dim_date      ||--o{ fct_order_items : "purchase_date"

    fct_orders {
        varchar order_id PK
        varchar customer_unique_id FK
        date purchase_date FK
        varchar order_status
        varchar customer_state
        int n_items
        int n_sellers
        decimal items_value
        decimal freight_value
        decimal order_value
        decimal paid_value
        varchar main_payment_type
        int delivery_days
        int delay_days
        boolean is_late
        int review_score
    }
    fct_order_items {
        varchar order_id PK
        int order_item_id PK
        varchar product_id FK
        varchar seller_id FK
        varchar customer_unique_id FK
        date purchase_date FK
        decimal price
        decimal freight_value
        decimal item_value
    }
    dim_customers {
        varchar customer_unique_id PK
        varchar customer_state
        varchar customer_city
        date first_order_date
        int n_orders
        boolean is_repeat
    }
    dim_products {
        varchar product_id PK
        varchar category
        varchar category_pt
        int weight_g
    }
    dim_sellers {
        varchar seller_id PK
        varchar seller_state
        varchar seller_city
    }
    dim_date {
        date date_day PK
        int year
        int month
        date month_start
        boolean is_analysis_window
    }
```

## Grain

| Table | Grain | Key |
|---|---|---|
| fct_order_items | one item in one order | (order_id, order_item_id) |
| fct_orders | one order | order_id |
| dim_customers | one real customer | customer_unique_id |
| dim_products | one product | product_id |
| dim_sellers | one seller | seller_id |
| dim_date | one calendar day, 2016-01-01 → 2018-12-31 | date_day |

## Design decisions

| Decision | Why |
|---|---|
| Two facts (items + orders) | Category / seller revenue needs item grain; delivery, review and payment KPIs live at order grain. One fact would force fan-out. |
| Payments and reviews folded into `fct_orders` | Aggregated to one row per order before joining (no fan-out). Latest review per order. |
| `customer_unique_id` as customer key | `customer_id` is generated per order (Data Quality Decision 1). |
| `customer_state` kept on `fct_orders` | 39 customers ordered from more than one state; delivery is analysed by the state the order shipped to. |
| `seller_id` only on items | 1,278 orders contain items from more than one seller. |
| Category translation folded into `dim_products` | Star, not snowflake: one join from fact to dimension. |
| No geolocation dimension | Not one row per zip (52.6 rows / zip); state level is complete. |

## Metric definitions

| Metric | Definition |
|---|---|
| GMV | SUM(price) — excludes freight |
| Order value | SUM(price + freight_value) per order |
| Delivery days | purchase → delivered to customer, delivered orders only |
| Late | delivered date > estimated date (date level) |
| Review score | latest review per order; NULL if none |
| Repeat customer | customer_unique_id with ≥ 2 orders |
| Analysis window | purchases 2017-01-01 → 2018-08-31 |