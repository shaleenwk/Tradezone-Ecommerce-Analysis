# TradeZone E-Commerce Data Analysis
 
## Project Overview

End-to-end SQL data analysis of TradeZone, a Nigerian e-commerce platform experiencing strong revenue growth but declining customer retention and seller quality issues. The project covers data cleaning and preparation, eight structured business analysis queries, and a formal analyst memo addressed to senior leadership.


## Repository Structure
 
| File | Description |
|------|-------------|
| `data_cleaning_script.sql` | Part A - Full data cleaning script (PostgreSQL) |
| `analysis_queries.sql` | Part B - 8 business analysis queries (PostgreSQL) |
| `analyst_memo.pdf` | Part C - Analyst memo addressed to Head of Growth and Head of Seller Operations |


## Business Context
TradeZone operates across five major Nigerian cities; Lagos, Abuja, Port Harcourt, Kano and Ibadan. Leadership identified three concerns heading into 2025:
- Strong top-line growth but unclear sustainability
- Dropping customer retention rates
- Sellers dragging down overall platform ratings
This project investigates each concern using transaction, customer, seller, product, payment and review data, and translates the findings into actionable business recommendations.


## Database Schema
The dataset spans **7 tables**: `customers`, `sellers`, `products`, `orders`, `order_items`, `payments` and `reviews`.

## Part A - Data Cleaning Summary
### Missing Values
| Table | Issue | Decision |
|-------|-------|----------|
| customers | NULL emails | Replaced with `unknown@placeholder.com` |
| orders | NULL delivery dates | Left as NULL; correct for non-delivered orders |
| orders | NULL total amounts | Recalculated from order_items line totals |
| order_items | NULL unit_price and line_total | Deleted; no recoverable price from any source |
| payments | NULL amounts | Filled from linked order total where available |


### Duplicates, Formatting and Validation
- Removed duplicate customer accounts, retaining the earliest sign-up and reassigning linked orders before deletion
- Standardised city name variants and product category casing across all affected tables
- Flagged and corrected order totals that differed from line item sums by more than ₦10
- Deleted review ratings outside the valid 1–5 range


## Part B - Key Results
 
### Customer Acquisition & 30-Day Conversion
| State | New Customers | Converted in 30 Days | Conversion Rate |
|-------|--------------|----------------------|-----------------|
| Lagos | 142 | 68 | 47.89% |
| FCT | 92 | 37 | 40.22% |
| Rivers | 65 | 25 | 38.46% |
| Kano | 57 | 18 | 31.58% |
| Oyo | 60 | 17 | 28.33% |
 
> No state exceeded 50% conversion; more than half of new customers did not make a purchase within their first 30 days.
 
### Quarterly Revenue Trends
| Quarter | Revenue 2023 | Revenue 2024 | Growth % |
|---------|-------------|-------------|----------|
| Q1 | ₦7.04M | ₦115.8M | 1,544.45% |
| Q2 | ₦18.27M | ₦144.1M | 688.62% |
| Q3 | ₦51.2M | ₦227.3M | 343.72% |
| Q4 | ₦72.0M | ₦350.8M | 387.33% |
 
> Q4 2024 was the highest revenue quarter at ₦350.8M. All four quarters showed triple-digit year-on-year growth.
 
### Customer Spend Segmentation
| Segment | Customers | Avg Spend | Revenue Contribution |
|---------|-----------|-----------|----------------------|
| High Spender (≥ ₦100,000) | 587 | ₦1,422,396 | ₦834.9M (99.5%) |
| Medium Spender (₦50K–₦99,999) | 29 | ₦69,272 | ₦2.0M (0.2%) |
| Low Spender (< ₦50,000) | 53 | ₦22,800 | ₦1.1M (0.1%) |
 
> Platform revenue is almost entirely dependent on 587 customers, a significant concentration risk.
 
### Other Findings
- **Product Performance:** All top 10 revenue-generating products were Electronics, led by the HP Pavilion Laptop at ₦23.8M
- **Seller Fulfilment:** The fastest seller (RunFast NG, 91.2 hrs) holds only a 3.25 rating, which means speed does not correlate with customer satisfaction
- **Payment Methods:** Card dominates in Lagos, FCT and Rivers; Cash on Delivery leads in Oyo and Kano
- **Seller Bonus:** 10 sellers qualified with 4.0+ ratings and 10+ completed orders; SportsCentral NG led with ₦15M revenue
---
 
## Part C - Analyst Memo
A structured business memo addressed to the **Head of Growth** and **Head of Seller Operations** covering:
1. Executive summary of platform performance
2. Three key findings with specific figures and business interpretation
3. Two data-backed recommendations with responsible owners and 60–90 day expected outcomes
4. Data quality decisions and their potential impact on analysis
5. One unanswerable business question and the data needed to address it
   
See `analyst_memo.pdf` for the full document.
 
---
 
## Key Takeaways
- TradeZone grew 400%+ in revenue across 2024, but growth is concentrated and fragile
- New customer activation is the most urgent problem — no state converts more than 50% of sign-ups
- Seller quality, not speed, is what drives customer satisfaction
- Electronics dominates both product revenue and the top 10 rankings
- Oyo and Kano show the weakest conversion rates and prefer Cash on Delivery over card payments

---

### Author
Shaleen - Data Science & Analytics
