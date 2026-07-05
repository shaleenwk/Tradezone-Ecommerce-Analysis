-- PART A - DATA CLEANING & PREPARATION

-- Preview of customers table, checking for missing values
SELECT *
FROM customers
WHERE email       IS NULL OR TRIM(email)  = ''
   OR city        IS NULL OR TRIM(city)   = ''
   OR signup_date IS NULL
   OR account_status IS NULL OR TRIM(account_status) = '';
   

-- Set a placeholder to the email (only column with NULLS in the customers table)
UPDATE customers
SET email = 'unknown@placeholder.com'
WHERE email IS NULL OR email = '' OR TRIM(email) = '';

-- Preview of sellers table, checking for missing values. No NULLs
SELECT *
FROM sellers
WHERE onboarding_date  IS NULL
   OR product_category IS NULL OR TRIM(product_category) = ''
   OR city             IS NULL OR TRIM(city)             = ''
   OR account_status   IS NULL OR TRIM(account_status)   = '';
   
-- Preview of orders table, checking for missing values (Nulls in the delivery and total butno changes made)
SELECT *
FROM orders
WHERE customer_id  IS NULL
   OR seller_id    IS NULL
   OR order_date   IS NULL
   OR order_status IS NULL OR TRIM(order_status) = ''
   OR total_amount IS NULL;

   
-- Preview of order_items table, checking for missing values
SELECT *
FROM order_items
WHERE order_id   IS NULL
   OR product_id IS NULL
   OR quantity   IS NULL
   OR unit_price IS NULL
   OR line_total IS NULL;
   
/* Deleted items where unit_price and line_total are NULL, includinng where
 quantity was recorded. Without a price theserows cannot be used for revenue,
 seller performance or order value analysis, and their presence would inflate
 item count metrics without adding any monetary value.*/
DELETE FROM order_items
WHERE unit_price IS NULL;


-- Preview of payments table, checking for missing values
SELECT *
FROM payments
WHERE order_id       IS NULL
   OR payment_method IS NULL OR TRIM(payment_method) = ''
   OR amount         IS NULL
   OR payment_date   IS NULL;
   
-- Checked how many rows have null values in the amount cclumn
SELECT COUNT(*) AS null_amount_count
FROM payments
WHERE amount IS NULL;

-- Checked if the correspondng orders have a total_amount to fill from
SELECT p.payment_id, p.order_id, p.payment_method, o.total_amount
FROM payments p
JOIN orders o ON o.order_id = p.order_id
WHERE p.amount IS NULL;

-- Filled NULL payment amounts from the corresponding order total
UPDATE payments
SET amount = o.total_amount
FROM orders o
WHERE payments.order_id = o.order_id
  AND payments.amount IS NULL;

-- Deleted payments where amount is NULL and cannot be recoveredfrom the linked order
DELETE FROM payments
WHERE payment_id IN (
    SELECT p.payment_id
    FROM payments p
    LEFT JOIN orders o ON o.order_id = p.order_id
    WHERE p.amount IS NULL
      AND (o.total_amount IS NULL OR o.order_id IS NULL)
);

-- -- Preview of paymnents table, checking for missing values (No NULLs)
SELECT *
FROM reviews
WHERE product_id  IS NULL
   OR customer_id IS NULL
   OR rating      IS NULL
   OR review_date IS NULL;
   
-- Preview count of duplicate customers ie with the same email
SELECT email, COUNT(*) AS cnt
FROM customers
WHERE email <> 'unknown@placeholder.com'
GROUP BY email
HAVING COUNT(*) > 1;

-- Moved orders from duplicate accounts to the original account
UPDATE orders
SET customer_id = original.customer_id
FROM (
    SELECT
        LOWER(TRIM(c1.email))  AS email,
        MIN(c1.customer_id)    AS customer_id
    FROM customers c1
    WHERE c1.email <> 'unknown@placeholder.com'
    GROUP BY LOWER(TRIM(c1.email))
) original
JOIN customers dup
  ON  LOWER(TRIM(dup.email)) = original.email
  AND dup.customer_id <> original.customer_id
WHERE orders.customer_id = dup.customer_id;

-- deleted te the duplicate accounts customers
DELETE FROM customers
WHERE customer_id IN (
    SELECT c1.customer_id
    FROM customers c1
    JOIN customers c2
      ON  LOWER(TRIM(c1.email)) = LOWER(TRIM(c2.email))
      AND c1.email <> 'unknown@placeholder.com'
      AND c2.email <> 'unknown@placeholder.com'
      AND (
            c1.signup_date > c2.signup_date
         OR (c1.signup_date = c2.signup_date AND c1.customer_id > c2.customer_id)
      )
);


-- Standardised city names, dates, and category casing
-- City names in customer table
UPDATE customers
SET city = CASE
    WHEN LOWER(TRIM(city)) IN ('lagos', 'lago s')
        THEN 'Lagos'
    WHEN LOWER(TRIM(city)) IN ('abuja', 'abj', 'fct')
        THEN 'Abuja'
    WHEN LOWER(TRIM(city)) IN ('port harcourt', 'portharcourt', 'port-harcourt', 'ph')
        THEN 'Port Harcourt'
    WHEN LOWER(TRIM(city)) = 'kano'
        THEN 'Kano'
    WHEN LOWER(TRIM(city)) = 'ibadan'
        THEN 'Ibadan'
ELSE TRIM(city)
END;

-- City names in sellers table
SELECT DISTINCT city
FROM sellers;

UPDATE sellers
SET city = CASE
    WHEN LOWER(TRIM(city)) IN ('lagos', 'lago s')
        THEN 'Lagos'
    WHEN LOWER(TRIM(city)) IN ('abuja')
        THEN 'Abuja'
    WHEN LOWER(TRIM(city)) IN ('port harcourt', 'portharcourt', 'port-harcourt')
        THEN 'Port Harcourt'
    WHEN LOWER(TRIM(city)) IN ('kano')
        THEN 'Kano'
    WHEN LOWER(TRIM(city)) IN ('ibadan')
        THEN 'Ibadan'
ELSE TRIM(city)
END;


-- Preview date formats (ALL OK)

SELECT customer_id, signup_date
FROM customers
WHERE TO_CHAR(signup_date, 'YYYY-MM-DD') != signup_date::TEXT
   OR signup_date IS NULL;

-- Standardised category casing
UPDATE products
SET category = CASE
    WHEN LOWER(TRIM(category)) IN ('electronics', 'electronis')
        THEN 'Electronics'
    WHEN LOWER(TRIM(category)) IN ('fashion', 'fasion', 'fashon')
        THEN 'Fashion'
    WHEN LOWER(TRIM(category)) IN ('home & garden', 'home and garden')
        THEN 'Home And Garden'
    WHEN LOWER(TRIM(category)) IN ('beauty', 'beauty and personal care', 'beauty & personal care')
        THEN 'Beauty And Personal Care'
    WHEN LOWER(TRIM(category)) IN ('sports', 'sports and fitness', 'sports & fitness')
        THEN 'Sports And Fitness'
    WHEN LOWER(TRIM(category)) IN ('food', 'food and beverages', 'food & beverages')
        THEN 'Food And Beverages'
    WHEN LOWER(TRIM(category)) IN ('books', 'books & stationery', 'books and stationery')
        THEN 'Books And Stationery'
ELSE category
END;


-- Flag orders where total_amount – SUM(line_total) greter than ₦10.
CREATE TABLE IF NOT EXISTS flagged_order_totals (
    order_id          VARCHAR(12),
    recorded_total    NUMERIC(14,2),
    calculated_total  NUMERIC(14,2),
    difference        NUMERIC(14,2),
    flagged_at        TIMESTAMP DEFAULT NOW()
);


INSERT INTO flagged_order_totals (order_id, recorded_total, calculated_total, difference)
SELECT
    o.order_id,
    o.total_amount                           AS recorded_total,
    SUM(oi.line_total)                       AS calculated_total,
    ABS(o.total_amount - SUM(oi.line_total)) AS difference
FROM orders o
JOIN order_items oi ON oi.order_id = o.order_id
GROUP BY o.order_id, o.total_amount
HAVING ABS(o.total_amount - SUM(oi.line_total)) > 10;

-- Preview flagged orders
SELECT * FROM flagged_order_totals ORDER BY difference DESC;


UPDATE orders
SET total_amount = sub.correct_total
FROM (
    SELECT oi.order_id, SUM(oi.line_total) AS correct_total
    FROM order_items oi
    JOIN flagged_order_totals f ON f.order_id = oi.order_id
    GROUP BY oi.order_id
) sub
WHERE orders.order_id = sub.order_id;


-- REVIEW RATINGS OUT OF RANGE (must be 1–5)
 
CREATE TABLE IF NOT EXISTS flagged_reviews (
    review_id   VARCHAR(12),
    rating      INT,
    flagged_at  TIMESTAMP DEFAULT NOW()
);
 
INSERT INTO flagged_reviews (review_id, rating)
SELECT review_id, rating
FROM reviews
WHERE rating < 1 OR rating > 5;
 
SELECT * FROM flagged_reviews;

-- Deleted reviews outside 1-5
DELETE FROM reviews
USING flagged_reviews f
WHERE reviews.review_id = f.review_id;


-- NEGATIVE PRODUCT PRICES (No changes made after review)
 
CREATE TABLE IF NOT EXISTS flagged_product_prices (
    product_id  VARCHAR(10),
    unit_price  NUMERIC(12,2),
    flagged_at  TIMESTAMP DEFAULT NOW()
);
 
INSERT INTO flagged_product_prices (product_id, unit_price)
SELECT product_id, unit_price
FROM products
WHERE unit_price < 0;
 
SELECT * FROM flagged_product_price