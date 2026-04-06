-- ============================================================
--  ZORVYN FINTECH — DATA ANALYST PROJECT
--  Author: Vivek Ranjan  | Data Analyst
-- ============================================================



-- 1 How many total transactions happened on Zorvyn's platform last month?
SELECT
    COUNT(txn_id)   AS total_transactions
FROM fact_transactions
WHERE txn_status = 'SUCCESS'
  AND txn_type   = 'PAYMENT'
  AND MONTH(txn_timestamp) = MONTH(CURDATE()) - 1
  AND YEAR(txn_timestamp)  = YEAR(CURDATE());



-- 2 What is Zorvyn's total GMV and number of transactions per month?
SELECT
    YEAR(txn_timestamp)        AS txn_year,
    MONTH(txn_timestamp)       AS txn_month,
    COUNT(txn_id)              AS total_transactions,
    ROUND(SUM(amount), 2)                AS total_gmv_inr
FROM fact_transactions
WHERE txn_status = 'SUCCESS'
  AND txn_type   = 'PAYMENT'
GROUP BY YEAR(txn_timestamp), MONTH(txn_timestamp)
ORDER BY txn_year, txn_month;


-- 3 Who are Zorvyn's Top 10 merchants by total transaction amount?
SELECT
    merchant_id,
    COUNT(txn_id)         AS total_transactions,
    SUM(amount)           AS total_gmv_inr,
    ROUND(AVG(amount), 0) AS avg_order_value
FROM fact_transactions
WHERE txn_status = 'SUCCESS'
  AND txn_type   = 'PAYMENT'
GROUP BY merchant_id
ORDER BY total_gmv_inr DESC
LIMIT 10;


-- 4 What is the total GMV and transaction count for each
-- payment method — UPI, Card, Wallet, Net Banking?
SELECT
    pm.method_name,
    COUNT(t.txn_id)         AS total_transactions,
    ROUND(SUM(t.amount), 2)           AS total_gmv_inr,
    ROUND(AVG(t.amount), 0) AS avg_transaction_value
FROM fact_transactions t
JOIN dim_payment_method pm
    ON t.method_id = pm.method_id
WHERE t.txn_status = 'SUCCESS'
GROUP BY pm.method_name
ORDER BY total_gmv_inr DESC;


-- 5. What are the top failure reasons
-- how many transactions failed due to each reason?
SELECT fr.reason_label, fr.reason_category,
       fr.is_recoverable,
    COUNT(t.txn_id)   AS failed_count,
    SUM(t.amount)     AS failed_gmv_inr
FROM fact_transactions t
JOIN dim_failure_reason fr
    ON t.failure_reason_id = fr.reason_id
WHERE t.txn_status = 'FAILED'
GROUP BY fr.reason_label, fr.reason_category, fr.is_recoverable
ORDER BY failed_count DESC;


-- 6. How many merchants does Zorvyn have in each business
-- category, and how many are currently active vs inactive?
SELECT
    business_category,
    merchant_tier,
    COUNT(merchant_id)                                AS total_merchants,
    COUNT(CASE WHEN is_active = TRUE  THEN 1 END)    AS active_merchants,
    COUNT(CASE WHEN is_active = FALSE THEN 1 END)    AS inactive_merchants
FROM dim_merchants
GROUP BY business_category, merchant_tier
ORDER BY total_merchants DESC;


-- 7. What is the Transaction Success Rate for each payment method 
-- and is it Healthy, Needs Attention, or Critical?
SELECT
    pm.method_name,
    COUNT(t.txn_id)                                           AS total_attempts,
    COUNT(CASE WHEN t.txn_status = 'SUCCESS' THEN 1 END)     AS successful,
    COUNT(CASE WHEN t.txn_status = 'FAILED'  THEN 1 END)     AS failed,
    ROUND(
        COUNT(CASE WHEN t.txn_status = 'SUCCESS' THEN 1 END) * 100.0
        / COUNT(t.txn_id), 2)                             AS success_rate_pct,
    CASE
        WHEN COUNT(CASE WHEN t.txn_status = 'SUCCESS' THEN 1 END) * 100.0
             / COUNT(t.txn_id) >= 95  THEN 'Healthy'
        WHEN COUNT(CASE WHEN t.txn_status = 'SUCCESS' THEN 1 END) * 100.0
             / COUNT(t.txn_id) >= 90  THEN 'Needs Attention'
        ELSE 'Critical'
    END                                                       AS health_status
FROM fact_transactions t
JOIN dim_payment_method pm
    ON t.method_id = pm.method_id
GROUP BY pm.method_name
ORDER BY success_rate_pct DESC;


-- 8. Classify every merchant as Active, At Risk, or Churned
-- based on when they last made a transaction.
SELECT m.merchant_name,
    MAX(t.txn_timestamp)                       AS last_transaction_date,
    DATEDIFF(CURDATE(), MAX(t.txn_timestamp))  AS days_inactive,
    CASE
        WHEN DATEDIFF(CURDATE(), MAX(t.txn_timestamp)) <= 30  THEN 'Active'
        WHEN DATEDIFF(CURDATE(), MAX(t.txn_timestamp)) <= 60  THEN 'At Risk'
        ELSE 'Churned'
    END                                        AS merchant_status
FROM fact_transactions t
JOIN dim_merchants m
    ON t.merchant_id = m.merchant_id
WHERE t.txn_status = 'SUCCESS'
GROUP BY m.merchant_name, m.merchant_tier, m.business_category
ORDER BY days_inactive DESC;

-- 9. Which merchants have raised chargebacks, and how many?
-- Show merchants with zero chargebacks too.
SELECT m.merchant_name, m.merchant_tier,
		m.business_category,
    COUNT(cb.chargeback_id)     AS total_chargebacks,
    SUM(cb.dispute_amount)      AS total_disputed_amount_inr
FROM dim_merchants m
LEFT JOIN fact_chargebacks cb
    ON m.merchant_id = cb.merchant_id
GROUP BY m.merchant_name, m.merchant_tier, m.business_category
ORDER BY total_chargebacks DESC;


-- 10. Which business category generates the highest average
-- transaction value for Zorvyn?
SELECT
    m.business_category,
    COUNT(t.txn_id)          AS total_transactions,
    SUM(t.amount)            AS total_gmv_inr,
    ROUND(AVG(t.amount), 0)  AS avg_transaction_value,
    ROUND(MIN(t.amount), 0)  AS min_transaction_value,
    ROUND(MAX(t.amount), 0)  AS max_transaction_value
FROM fact_transactions t
JOIN dim_merchants m
    ON t.merchant_id = m.merchant_id
WHERE t.txn_status = 'SUCCESS'
  AND t.txn_type   = 'PAYMENT'
GROUP BY m.business_category
ORDER BY avg_transaction_value DESC;


-- 11.` Which 5 merchants were onboarded most recently and how
-- many transactions have they done so far?
SELECT m.merchant_name, m.business_category,
    m.merchant_tier, m.onboard_date,
    COUNT(t.txn_id)   AS total_transactions,
    SUM(t.amount)     AS total_gmv_inr
FROM dim_merchants m
LEFT JOIN fact_transactions t
    ON m.merchant_id  = t.merchant_id
    AND t.txn_status  = 'SUCCESS'
GROUP BY m.merchant_name, m.business_category, m.merchant_tier, m.onboard_date
ORDER BY m.onboard_date DESC
LIMIT 5;

