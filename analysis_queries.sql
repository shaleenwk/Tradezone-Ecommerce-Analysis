/* QUESTION 1: Customer Acquisition & 30-Day Conversion
Top 5 states by new sign-ups in 2024, with % who made at
least one purchase within their first 30 days. */

-- First counted customers who placed at least one order within 30 days of signing up
 
SELECT
    c.state,
    COUNT(DISTINCT c.customer_id)  AS new_customers,
    COUNT(DISTINCT CASE
        WHEN (o.order_date - c.signup_date) BETWEEN 0 AND 30
        THEN c.customer_id
    END)  AS converted_in_30_days,
   -- Then did the conversion rate as a percentage
    ROUND(
        COUNT(DISTINCT CASE
            WHEN (o.order_date - c.signup_date) BETWEEN 0 AND 30
            THEN c.customer_id
        END)::NUMERIC
        / COUNT(DISTINCT c.customer_id) * 100
    , 2)  AS conversion_rate_pct
 FROM customers c
LEFT JOIN orders o
       ON o.customer_id = c.customer_id
      AND o.order_status NOT IN ('cancelled', 'failed')
 WHERE EXTRACT(YEAR FROM c.signup_date) = 2024
GROUP BY c.state
ORDER BY new_customers DESC
LIMIT 5;



-- QUESTION 2: Product Performance
-- Top 10 products by total revenue in 2024.
 
SELECT
    p.product_id,
    p.product_name,
    p.category,
    COUNT(DISTINCT o.order_id)       AS total_orders,
    SUM(oi.line_total)               AS total_revenue
FROM products p
JOIN order_items oi ON oi.product_id = p.product_id
JOIN orders o       ON o.order_id    = oi.order_id 
WHERE EXTRACT(YEAR FROM o.order_date) = 2024
  AND o.order_status NOT IN ('cancelled', 'failed')
 GROUP BY p.product_id, p.product_name, p.category
ORDER BY total_revenue DESC
LIMIT 10;


-- QUESTION 3: Seller Fulfilment Efficiency
-- Top 20 fastest sellers by average fulfilment time (hours),
-- among sellers with at least 20 completed orders.
-- Including total completed orders and average customer rating.

SELECT DISTINCT order_status
FROM orders;

SELECT
    s.seller_id,
    s.seller_name,
    COUNT(DISTINCT o.order_id)  AS completed_orders,
    ROUND(
        AVG(
            EXTRACT(EPOCH FROM (o.delivery_date::TIMESTAMP - o.order_date::TIMESTAMP))
            / 3600
        )::NUMERIC
    , 2)                                    AS avg_fulfilment_hours,
    ROUND(AVG(r.rating)::NUMERIC, 2)        AS avg_customer_rating
FROM sellers s
JOIN orders o       ON o.seller_id = s.seller_id
LEFT JOIN reviews r ON r.order_id  = o.order_id
WHERE o.order_status = 'Delivered'
  AND o.delivery_date IS NOT NULL
GROUP BY s.seller_id, s.seller_name
HAVING COUNT(DISTINCT o.order_id) >= 20
ORDER BY avg_fulfilment_hours ASC
LIMIT 20;



-- QUESTION 4: Quarterly Revenue Trends
-- Revenue, average order value and order count per quarter
-- for 2023 and 2024. Identifies the quarter with the strongest
-- year-on-year revenue growth.
 
-- Step 1: Revenue summary per year and quarter
WITH quarterly AS (
    SELECT
        EXTRACT(YEAR FROM order_date)::INT      AS yr,
        EXTRACT(QUARTER FROM order_date)::INT   AS qtr,
        SUM(total_amount)                       AS total_revenue,
        ROUND(AVG(total_amount)::NUMERIC, 2)    AS avg_order_value,
        COUNT(order_id)                         AS total_orders
    FROM orders
    WHERE EXTRACT(YEAR FROM order_date) IN (2023, 2024)
      AND order_status NOT IN ('cancelled', 'failed')
    GROUP BY
        EXTRACT(YEAR FROM order_date),
        EXTRACT(QUARTER FROM order_date)
),
-- Step 2: Pivot 2023 and 2024 side by side for comparison
comparison AS (
    SELECT
        q1.qtr,
        q1.total_revenue                        AS revenue_2023,
        q2.total_revenue                        AS revenue_2024,
        q1.avg_order_value                      AS aov_2023,
        q2.avg_order_value                      AS aov_2024,
        q1.total_orders                         AS orders_2023,
        q2.total_orders                         AS orders_2024,
        -- Absolute revenue growth
        (q2.total_revenue - q1.total_revenue)   AS revenue_growth,
        -- Growth as a percentage
        ROUND(
            (q2.total_revenue - q1.total_revenue)::NUMERIC
            / q1.total_revenue * 100
        , 2)                                    AS growth_pct
    FROM quarterly q1
    JOIN quarterly q2
      ON q1.qtr = q2.qtr
     AND q1.yr  = 2023
     AND q2.yr  = 2024
)
SELECT
    'Q' || qtr   AS quarter,
    revenue_2023,
    revenue_2024,
    aov_2023,
    aov_2024,
    orders_2023,
    orders_2024,
    revenue_growth,
    growth_pct,
    -- Flag the single quarter with the highest growth
    CASE
        WHEN growth_pct = MAX(growth_pct) OVER()
        THEN 'Strongest Growth'
        ELSE ''
    END       AS growth_flag 
FROM comparison
ORDER BY qtr;




-- QUESTION 5: Customer Spend Segmentation
-- Segment 2024 customers into High / Medium / Low spenders.
 
WITH customer_spend AS (
    SELECT
        c.customer_id,
        SUM(o.total_amount)                     AS total_spend
    FROM customers c
    JOIN orders o ON o.customer_id = c.customer_id
    WHERE EXTRACT(YEAR FROM o.order_date) = 2024
      AND o.order_status NOT IN ('cancelled', 'failed')
    GROUP BY c.customer_id
),
segmented AS (
    SELECT
        customer_id,
        total_spend,
        CASE
            WHEN total_spend >= 100000 THEN 'High Spender'
            WHEN total_spend >= 50000  THEN 'Medium Spender'
            ELSE                            'Low Spender'
        END                                     AS spend_segment
    FROM customer_spend
)
SELECT
    spend_segment,
    COUNT(customer_id)                          AS customer_count,
    ROUND(AVG(total_spend)::NUMERIC, 2)         AS avg_spend_per_customer,
    SUM(total_spend)                            AS total_revenue_contribution
FROM segmented
GROUP BY spend_segment
ORDER BY
    CASE spend_segment
        WHEN 'High Spender'   THEN 1
        WHEN 'Medium Spender' THEN 2
        WHEN 'Low Spender'    THEN 3
    END;




-- QUESTION 6: Payment Method Preferences by State
-- Transaction count and total amount per payment method
-- per state. Identifies the most popular method per state.
 
WITH payment_summary AS (
    SELECT
        c.state,
        p.payment_method,
        COUNT(p.payment_id)                     AS transaction_count,
        SUM(p.amount)                           AS total_amount
    FROM payments p
    JOIN orders o    ON o.order_id    = p.order_id
    JOIN customers c ON c.customer_id = o.customer_id
    GROUP BY c.state, p.payment_method
),
-- Rank payment methods within each state by transaction count
ranked AS (
    SELECT
        state,
        payment_method,
        transaction_count,
        total_amount,
        RANK() OVER (
            PARTITION BY state
            ORDER BY transaction_count DESC
        )                                       AS rnk
    FROM payment_summary
)
SELECT
    state,
    payment_method,
    transaction_count,
    ROUND(total_amount::NUMERIC, 2)             AS total_amount,
    CASE WHEN rnk = 1 THEN 'Most Popular' ELSE '' END AS popularity_flag
FROM ranked
ORDER BY state, transaction_count DESC;




-- QUESTION 7: Review Ratings and Sales Performance
-- Group products by average rating into High / Mid / Low.
-- Includes product count, total revenue and avg unit price.
 
WITH product_ratings AS (
    SELECT
        p.product_id,
        p.product_name,
        p.unit_price,
        ROUND(AVG(r.rating)::NUMERIC, 2)        AS avg_rating,
        SUM(oi.line_total)                      AS total_revenue
    FROM products p
    LEFT JOIN reviews r      ON r.product_id  = p.product_id
    LEFT JOIN order_items oi ON oi.product_id = p.product_id
    LEFT JOIN orders o       ON o.order_id    = oi.order_id
                             AND o.order_status NOT IN ('cancelled', 'failed')
    GROUP BY p.product_id, p.product_name, p.unit_price
),
categorised AS (
    SELECT
        product_id,
        unit_price,
        total_revenue,
        avg_rating,
        CASE
            WHEN avg_rating >= 4.0 THEN 'High Rated'
            WHEN avg_rating >= 3.0 THEN 'Mid Rated'
            ELSE                        'Low Rated'
        END                                     AS rating_category
    FROM product_ratings
    WHERE avg_rating IS NOT NULL
)
SELECT
    rating_category,
    COUNT(product_id)                           AS product_count,
    ROUND(AVG(unit_price)::NUMERIC, 2)          AS avg_unit_price,
    ROUND(SUM(total_revenue)::NUMERIC, 2)       AS total_revenue
FROM categorised
GROUP BY rating_category
ORDER BY
    CASE rating_category
        WHEN 'High Rated' THEN 1
        WHEN 'Mid Rated'  THEN 2
        WHEN 'Low Rated'  THEN 3
    END;





-- QUESTION 8: Top Seller Bonus Qualification
-- Top 10 sellers in 2024 by revenue with at least 10 completed
-- orders and an average customer rating of 4.0 or above.
 
SELECT
    s.seller_id,
    s.seller_name,
    s.city,
    s.state,
    COUNT(DISTINCT o.order_id)                  AS total_orders,
    ROUND(AVG(r.rating)::NUMERIC, 2)            AS avg_rating,
    ROUND(SUM(o.total_amount)::NUMERIC, 2)      AS total_revenue
FROM sellers s
JOIN orders o      ON o.seller_id  = s.seller_id
LEFT JOIN reviews r ON r.order_id  = o.order_id
WHERE EXTRACT(YEAR FROM o.order_date) = 2024
  AND o.order_status NOT IN ('cancelled', 'failed')
GROUP BY s.seller_id, s.seller_name, s.city, s.state
HAVING COUNT(DISTINCT o.order_id)          >= 10
   AND ROUND(AVG(r.rating)::NUMERIC, 2)   >= 4.0
ORDER BY total_revenue DESC
LIMIT 10;