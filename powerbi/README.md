# Power BI Dashboard

Sales analytics dashboard built on the Gold layer of the data warehouse.

> Save the report in this folder as `Sales_Analytics.pbix`, and page screenshots in `docs/`.

## Screenshots
<!-- Add after building the report, for example:
![Executive Overview](../docs/dashboard_overview.png)
![Customers](../docs/dashboard_customers.png)
![Products & Margin](../docs/dashboard_margin.png)
-->

---

## 1. Data Connection
- **Source:** SQL Server, database `DataWarehouse`
- **Mode:** Import
- **Tables:** `gold.fact_sales`, `gold.dim_customers`, `gold.dim_products`, `gold.customer_rfm`

## 2. Date Table
```DAX
Date =
ADDCOLUMNS (
    CALENDAR ( DATE ( 2010, 1, 1 ), DATE ( 2014, 12, 31 ) ),
    "Year", YEAR ( [Date] ),
    "Month Number", MONTH ( [Date] ),
    "Month", FORMAT ( [Date], "MMM" ),
    "Year-Month", FORMAT ( [Date], "YYYY-MM" )
)
```
- Marked as date table.
- `Month` sorted by `Month Number`.

## 3. Data Model (Star Schema)
| From (many)                | To (one)                     | Direction |
|----------------------------|------------------------------|-----------|
| `fact_sales[product_key]`  | `dim_products[product_key]`  | Single    |
| `fact_sales[customer_key]` | `dim_customers[customer_key]`| Single    |
| `fact_sales[order_date]`   | `Date[Date]`                 | Single    |
| `customer_rfm[customer_key]` | `dim_customers[customer_key]` | One-to-one, single |

Because `dim_products` is SCD Type 2, `fact_sales[product_key]` points to the product **version** valid on the order date.

## 4. Calculated Column
In `fact_sales`, today's cost of the product sold (used only to show what margin would look like without history):
```DAX
Current Unit Cost =
LOOKUPVALUE (
    dim_products[cost],
    dim_products[product_number], RELATED ( dim_products[product_number] ),
    dim_products[is_current], 1
)
```

## 5. Measures
All measures are stored in the `_Measures` table.

```DAX
Total Sales = SUM ( fact_sales[sales_amount] )
Total Orders = DISTINCTCOUNT ( fact_sales[order_number] )
Total Customers = DISTINCTCOUNT ( fact_sales[customer_key] )
Avg Order Value = DIVIDE ( [Total Sales], [Total Orders] )

Sales PY = CALCULATE ( [Total Sales], SAMEPERIODLASTYEAR ( 'Date'[Date] ) )
Sales YoY % = DIVIDE ( [Total Sales] - [Sales PY], [Sales PY] )
Running Total Sales =
    CALCULATE (
        [Total Sales],
        FILTER ( ALL ( 'Date'[Date] ), 'Date'[Date] <= MAX ( 'Date'[Date] ) )
    )

-- Historical cost: RELATED() follows the SCD2 link, so each sale uses the cost valid on its order date
Historical Cost = SUMX ( fact_sales, fact_sales[quantity] * RELATED ( dim_products[cost] ) )
Gross Margin % = DIVIDE ( [Total Sales] - [Historical Cost], [Total Sales] )

-- Comparison: what margin would look like if every sale used today's cost
Current Cost = SUMX ( fact_sales, fact_sales[quantity] * fact_sales[Current Unit Cost] )
Margin % at Current Cost = DIVIDE ( [Total Sales] - [Current Cost], [Total Sales] )
Margin Misstatement (pts) = ( [Gross Margin %] - [Margin % at Current Cost] ) * 100
```

## 6. Report Pages

### Executive Overview
*How is the business performing?*
- KPI cards: Total Sales, Total Orders, Total Customers, Avg Order Value, Sales YoY %
- Line chart: Total Sales and Running Total Sales by Year-Month
- Bar charts: Total Sales by category, Total Sales by country
- Slicers: Year, category, country

### Customers
*Who are our most valuable customers, and who is at risk?*
- Bar chart: Total Customers and Total Sales by `rfm_segment`
- Table: top 10 customers by sales
- Bar chart: Total Sales by gender and marital status

### Products & Margin
*What is our true margin, and how wrong would it be without product history?*
- Clustered column chart: Gross Margin % vs Margin % at Current Cost, by Year
- Card: Margin Misstatement (pts)
- Matrix: category > subcategory with Total Sales, Historical Cost, Gross Margin %
- Bar chart: top 10 products by sales
