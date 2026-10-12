-- Project 1: Consumer Audience Readiness
-- Step 2: Duplicate detection and identity quality


-- Count all records
SELECT COUNT(*) AS total_records
FROM consumers_clean;


-- Count unique consumers
SELECT COUNT(DISTINCT consumer_id) AS unique_consumers
FROM consumers_clean;


-- Identify duplicate consumer IDs
SELECT
    consumer_id,
    COUNT(*) AS record_count
FROM consumers_clean
GROUP BY consumer_id
HAVING COUNT(*) > 1
ORDER BY record_count DESC;


-- Calculate duplicate record count
SELECT
    COUNT(*) - COUNT(DISTINCT consumer_id) AS duplicate_records
FROM consumers_clean;


-- Calculate duplicate rate
SELECT
    ROUND(
        (COUNT(*) - COUNT(DISTINCT consumer_id)) * 100.0 / COUNT(*),
        2
    ) AS duplicate_rate_percent
FROM consumers_clean;


-- Identify duplicate emails
SELECT
    email,
    COUNT(*) AS record_count
FROM consumers_clean
WHERE email IS NOT NULL
  AND email <> ''
GROUP BY email
HAVING COUNT(*) > 1
ORDER BY record_count DESC;


-- Count missing email records
SELECT
    COUNT(*) AS missing_email_records
FROM consumers_clean
WHERE email IS NULL
   OR email = '';


-- Count malformed email records
SELECT
    COUNT(*) AS malformed_email_records
FROM consumers_clean
WHERE email IS NOT NULL
  AND email <> ''
  AND email NOT LIKE '%@%.%';


-- Identify consumers with conflicting marketing consent
SELECT
    consumer_id,
    COUNT(DISTINCT marketing_consent) AS different_consent_values
FROM consumers_clean
GROUP BY consumer_id
HAVING COUNT(DISTINCT marketing_consent) > 1;


-- Count consumers with conflicting marketing consent
SELECT COUNT(*) AS consumers_with_consent_conflicts
FROM (
    SELECT consumer_id
    FROM consumers_clean
    GROUP BY consumer_id
    HAVING COUNT(DISTINCT marketing_consent) > 1
);