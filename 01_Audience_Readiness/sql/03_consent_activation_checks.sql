-- Project 1: Consumer Audience Readiness
-- Step 3: Consent compliance, activation readiness and taxonomy checks


-- 1. Count records with missing marketing consent
SELECT
    COUNT(*) AS missing_marketing_consent
FROM consumers_clean
WHERE marketing_consent IS NULL
   OR marketing_consent = '';


-- 2. Count records with missing analytics consent
SELECT
    COUNT(*) AS missing_analytics_consent
FROM consumers_clean
WHERE analytics_consent IS NULL
   OR analytics_consent = '';


-- 3. Count records by marketing activation status
SELECT
    activated_for_marketing,
    COUNT(*) AS number_of_records
FROM consumers_clean
GROUP BY activated_for_marketing;


-- 4. Identify consumers activated for marketing without valid consent
SELECT
    consumer_id,
    marketing_consent,
    activated_for_marketing
FROM consumers_clean
WHERE activated_for_marketing = 'YES'
  AND (
        marketing_consent = 'NO'
        OR marketing_consent IS NULL
        OR marketing_consent = ''
      );


-- 5. Count invalid marketing activations
SELECT
    COUNT(*) AS invalid_marketing_activations
FROM consumers_clean
WHERE activated_for_marketing = 'YES'
  AND (
        marketing_consent = 'NO'
        OR marketing_consent IS NULL
        OR marketing_consent = ''
      );


-- 6. Calculate activation compliance rate
SELECT
    ROUND(
        SUM(
            CASE
                WHEN activated_for_marketing = 'YES'
                 AND marketing_consent = 'YES'
                THEN 1
                ELSE 0
            END
        ) * 100.0
        /
        SUM(
            CASE
                WHEN activated_for_marketing = 'YES'
                THEN 1
                ELSE 0
            END
        ),
        2
    ) AS activation_compliance_rate_percent
FROM consumers_clean;


-- 7. Count invalid activations by source system
SELECT
    source_system,
    COUNT(*) AS invalid_activations
FROM consumers_clean
WHERE activated_for_marketing = 'YES'
  AND (
        marketing_consent = 'NO'
        OR marketing_consent IS NULL
        OR marketing_consent = ''
      )
GROUP BY source_system
ORDER BY invalid_activations DESC;


-- 8. Count invalid activations by country
SELECT
    country,
    COUNT(*) AS invalid_activations
FROM consumers_clean
WHERE activated_for_marketing = 'YES'
  AND (
        marketing_consent = 'NO'
        OR marketing_consent IS NULL
        OR marketing_consent = ''
      )
GROUP BY country
ORDER BY invalid_activations DESC;


-- 9. Count valid marketing activations
SELECT
    COUNT(*) AS valid_marketing_activations
FROM consumers_clean
WHERE activated_for_marketing = 'YES'
  AND marketing_consent = 'YES';


-- 10. Count records with missing audience segment
SELECT
    COUNT(*) AS missing_audience_segments
FROM consumers_clean
WHERE audience_segment IS NULL
   OR audience_segment = '';


-- 11. Inspect audience taxonomy
SELECT DISTINCT audience_segment
FROM consumers_clean
ORDER BY audience_segment;


-- 12. Inspect lifecycle-stage taxonomy
SELECT DISTINCT lifecycle_stage
FROM consumers_clean
ORDER BY lifecycle_stage;


-- 13. Count invalid lifecycle-stage values
SELECT
    lifecycle_stage,
    COUNT(*) AS records
FROM consumers_clean
WHERE lifecycle_stage NOT IN (
    'Prospect',
    'New Customer',
    'Active Customer',
    'Lapsed Customer'
)
GROUP BY lifecycle_stage
ORDER BY records DESC;


-- 14. Inspect product-interest taxonomy
SELECT DISTINCT product_interest
FROM consumers_clean
ORDER BY product_interest;


-- 15. Count records by product-interest value
SELECT
    product_interest,
    COUNT(*) AS records
FROM consumers_clean
GROUP BY product_interest
ORDER BY records DESC;


-- 16. Count stale profiles
-- A profile is considered stale if no activity has occurred in the last 365 days
SELECT
    COUNT(*) AS stale_profiles
FROM consumers_clean
WHERE last_activity_date < '2025-10-10';


-- 17. Count stale profiles that are still activated for marketing
SELECT
    COUNT(*) AS stale_activated_profiles
FROM consumers_clean
WHERE last_activity_date < '2025-10-10'
  AND activated_for_marketing = 'YES';