-- Customer Churn Analysis & Customer Intelligence
-- SQL business questions for the project dataset.
-- Database: customer_churn.db
-- Tables: db_customer, db_subscription, db_support
--
-- Run this file in SQLite after opening customer_churn.db.
-- Churn is defined consistently with the Python notebook:
-- cancellation_date IS NOT NULL.
--
-- Important:
-- db_support may contain multiple rows per customer. Queries that join support
-- data aggregate it first so complaint rows do not multiply subscription rows.

-- =========================================================
-- 1. Overall churn and retention rates
-- Business question: What share of customers have churned?
-- =========================================================
SELECT
    COUNT(*) AS total_customers,
    SUM(CASE WHEN cancellation_date IS NOT NULL THEN 1 ELSE 0 END) AS churned_customers,
    ROUND(
        100.0 * SUM(CASE WHEN cancellation_date IS NOT NULL THEN 1 ELSE 0 END)
        / NULLIF(COUNT(*), 0), 2
    ) AS churn_rate_pct,
    ROUND(
        100.0 * SUM(CASE WHEN cancellation_date IS NULL THEN 1 ELSE 0 END)
        / NULLIF(COUNT(*), 0), 2
    ) AS retention_rate_pct
FROM db_subscription;


-- =========================================================
-- 2. Churn by plan type
-- Business question: Which plan has the highest churn rate?
-- =========================================================
SELECT
    plan_type,
    COUNT(*) AS total_customers,
    SUM(CASE WHEN cancellation_date IS NOT NULL THEN 1 ELSE 0 END) AS churned_customers,
    ROUND(
        100.0 * SUM(CASE WHEN cancellation_date IS NOT NULL THEN 1 ELSE 0 END)
        / NULLIF(COUNT(*), 0), 2
    ) AS churn_rate_pct
FROM db_subscription
GROUP BY plan_type
ORDER BY churn_rate_pct DESC;


-- =========================================================
-- 3. Churn by subscription type
-- Business question: Does churn vary by acquisition/subscription type?
-- =========================================================
SELECT
    subscription_type,
    COUNT(*) AS total_customers,
    SUM(CASE WHEN cancellation_date IS NOT NULL THEN 1 ELSE 0 END) AS churned_customers,
    ROUND(
        100.0 * SUM(CASE WHEN cancellation_date IS NOT NULL THEN 1 ELSE 0 END)
        / NULLIF(COUNT(*), 0), 2
    ) AS churn_rate_pct
FROM db_subscription
GROUP BY subscription_type
ORDER BY churn_rate_pct DESC;


-- =========================================================
-- 4. Churn by contract type
-- Business question: Which contract groups may need retention attention?
-- =========================================================
SELECT
    contract_type,
    COUNT(*) AS total_customers,
    SUM(CASE WHEN cancellation_date IS NOT NULL THEN 1 ELSE 0 END) AS churned_customers,
    ROUND(
        100.0 * SUM(CASE WHEN cancellation_date IS NOT NULL THEN 1 ELSE 0 END)
        / NULLIF(COUNT(*), 0), 2
    ) AS churn_rate_pct
FROM db_subscription
GROUP BY contract_type
ORDER BY churn_rate_pct DESC;


-- =========================================================
-- 5. Churn by state
-- Business question: How does churn differ across customer locations?
-- =========================================================
SELECT
    c.state,
    COUNT(*) AS total_customers,
    SUM(CASE WHEN s.cancellation_date IS NOT NULL THEN 1 ELSE 0 END) AS churned_customers,
    ROUND(
        100.0 * SUM(CASE WHEN s.cancellation_date IS NOT NULL THEN 1 ELSE 0 END)
        / NULLIF(COUNT(*), 0), 2
    ) AS churn_rate_pct
FROM db_subscription AS s
LEFT JOIN db_customer AS c
    ON c.customerid = s.customerid
GROUP BY c.state
ORDER BY churn_rate_pct DESC;


-- =========================================================
-- 6. Monthly charges and monthly charges at risk
-- Business question: What is the monthly charge total associated with churned customers?
-- Note: This sums monthly charges; it is not lifetime revenue lost.
-- =========================================================
SELECT
    ROUND(AVG(monthly_charges), 2) AS average_monthly_charges,
    ROUND(SUM(CASE WHEN cancellation_date IS NOT NULL
                   THEN monthly_charges ELSE 0 END), 2) AS churned_customers_monthly_charges,
    ROUND(SUM(CASE WHEN cancellation_date IS NULL
                   THEN monthly_charges ELSE 0 END), 2) AS active_customers_monthly_charges
FROM db_subscription;


-- =========================================================
-- 7. Churn by churn-risk band
-- Business question: How are customers distributed across score-based risk bands?
-- =========================================================
WITH scored_customers AS (
    SELECT
        customerid,
        churn_score,
        CASE
            WHEN churn_score < 50 THEN 'Low'
            WHEN churn_score < 70 THEN 'Medium'
            WHEN churn_score >= 70 THEN 'High'
            ELSE 'Unknown'
        END AS churn_risk,
        CASE WHEN cancellation_date IS NOT NULL THEN 1 ELSE 0 END AS churn_flag
    FROM db_subscription
)
SELECT
    churn_risk,
    COUNT(*) AS total_customers,
    SUM(churn_flag) AS churned_customers,
    ROUND(100.0 * AVG(churn_flag), 2) AS actual_churn_rate_pct
FROM scored_customers
GROUP BY churn_risk
ORDER BY
    CASE churn_risk
        WHEN 'High' THEN 1
        WHEN 'Medium' THEN 2
        WHEN 'Low' THEN 3
        ELSE 4
    END;


-- =========================================================
-- 8. Customer tenure
-- Business question: What is the average observed tenure in days?
-- For churned customers, use cancellation date.
-- For active customers, use today's date.
-- =========================================================
SELECT
    ROUND(AVG(
        CAST(
            julianday(COALESCE(cancellation_date, date('now')))
            - julianday(subscription_start_date)
            AS INTEGER
        )
    ), 0) AS average_tenure_days,
    ROUND(AVG(
        CASE WHEN cancellation_date IS NOT NULL
             THEN julianday(cancellation_date) - julianday(subscription_start_date)
        END
    ), 0) AS average_churned_customer_tenure_days,
    ROUND(AVG(
        CASE WHEN cancellation_date IS NULL
             THEN julianday(date('now')) - julianday(subscription_start_date)
        END
    ), 0) AS average_active_customer_tenure_days
FROM db_subscription;


-- =========================================================
-- 9. Support complaints and escalations by churn status
-- Business question: Are support issues more common among churned customers?
-- Support is aggregated to one row per customer to avoid duplicate joins.
-- =========================================================
WITH support_by_customer AS (
    SELECT
        customerid,
        COUNT(*) AS complaint_count,
        MAX(CASE WHEN UPPER(escalations) = 'Y' THEN 1 ELSE 0 END) AS has_escalation
    FROM db_support
    GROUP BY customerid
),
customer_summary AS (
    SELECT
        s.customerid,
        CASE WHEN s.cancellation_date IS NOT NULL THEN 1 ELSE 0 END AS churn_flag,
        COALESCE(sp.complaint_count, 0) AS complaint_count,
        COALESCE(sp.has_escalation, 0) AS has_escalation
    FROM db_subscription AS s
    LEFT JOIN support_by_customer AS sp
        ON sp.customerid = s.customerid
)
SELECT
    CASE WHEN churn_flag = 1 THEN 'Churned' ELSE 'Active' END AS customer_status,
    COUNT(*) AS customers,
    ROUND(AVG(complaint_count), 2) AS average_complaints_per_customer,
    ROUND(100.0 * AVG(has_escalation), 2) AS customers_with_escalation_pct
FROM customer_summary
GROUP BY churn_flag
ORDER BY churn_flag DESC;


-- =========================================================
-- 10. Customer-level analysis table
-- Business question: What does a joined, customer-level dataset look like?
-- This query returns one row per subscription/customer and aggregates support.
-- =========================================================
WITH support_by_customer AS (
    SELECT
        customerid,
        COUNT(*) AS complaint_count,
        MAX(CASE WHEN UPPER(escalations) = 'Y' THEN 1 ELSE 0 END) AS has_escalation,
        ROUND(AVG(csat_score), 2) AS average_csat_score
    FROM db_support
    GROUP BY customerid
)
SELECT
    s.customerid,
    c.customer_name,
    c.country,
    c.state,
    c.gender,
    s.subscription_type,
    s.plan_type,
    s.contract_type,
    s.subscription_start_date,
    s.renewal_date,
    s.cancellation_date,
    s.monthly_charges,
    s.cltv,
    s.churn_score,
    CASE WHEN s.cancellation_date IS NOT NULL THEN 1 ELSE 0 END AS churn_flag,
    COALESCE(sp.complaint_count, 0) AS complaint_count,
    COALESCE(sp.has_escalation, 0) AS has_escalation,
    sp.average_csat_score
FROM db_subscription AS s
LEFT JOIN db_customer AS c
    ON c.customerid = s.customerid
LEFT JOIN support_by_customer AS sp
    ON sp.customerid = s.customerid
ORDER BY s.customerid;
