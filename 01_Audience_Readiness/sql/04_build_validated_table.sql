-- Project 1: Consumer Audience Readiness
-- Step 4: Build validated consumer table
-- Purpose:
-- Standardize key taxonomy fields, add data-quality flags,
-- identify duplicate and consent issues, and classify activation readiness.


-- 1. Remove the validated table if it already exists
DROP TABLE IF EXISTS consumers_validated;


-- 2. Create the validated table with standardized taxonomy
--    and initial quality flags
CREATE TABLE consumers_validated AS
SELECT
    consumer_id,
    email,
    country,
    source_system,

    -- Standardize product-interest taxonomy
    CASE
        WHEN product_interest IN ('Skincare', 'Skin Care', 'skin-care')
            THEN 'Skincare'
        WHEN product_interest IN ('Allergy', 'Allergies', 'allergy')
            THEN 'Allergy'
        WHEN product_interest IN ('Pain Relief', 'Pain relief', 'Pain-Relief')
            THEN 'Pain Relief'
        WHEN product_interest IN ('Digestive Health', 'Digestive', 'digestive-health')
            THEN 'Digestive Health'
        ELSE 'Unknown'
    END AS product_interest,

    -- Standardize lifecycle-stage taxonomy
    CASE
        WHEN lifecycle_stage IN ('Prospect', 'Prospects')
            THEN 'Prospect'
        WHEN lifecycle_stage IN ('New Customer', 'NEW')
            THEN 'New Customer'
        WHEN lifecycle_stage IN ('Active Customer', 'Active')
            THEN 'Active Customer'
        WHEN lifecycle_stage IN ('Lapsed Customer', 'Lapsed')
            THEN 'Lapsed Customer'
        ELSE 'Unknown'
    END AS lifecycle_stage,

    marketing_consent,
    analytics_consent,
    last_activity_date,
    audience_segment,
    campaign_id,
    activated_for_marketing,
    profile_created_date,
    age_band,

    -- Flag missing email addresses
    CASE
        WHEN email IS NULL
          OR email = ''
        THEN 1
        ELSE 0
    END AS missing_email_flag,

    -- Flag malformed email addresses
    CASE
        WHEN email IS NOT NULL
         AND email <> ''
         AND email NOT LIKE '%@%.%'
        THEN 1
        ELSE 0
    END AS malformed_email_flag,

    -- Flag missing marketing consent
    CASE
        WHEN marketing_consent IS NULL
          OR marketing_consent = ''
        THEN 1
        ELSE 0
    END AS missing_marketing_consent_flag,

    -- Flag records activated without valid marketing consent
    CASE
        WHEN activated_for_marketing = 'YES'
        AND (marketing_consent IS NULL
            OR marketing_consent = ''
            OR marketing_consent = 'NO'    )
        THEN 1
        ELSE 0
    END AS invalid_activation_flag,

    -- Flag missing audience segmentation
    CASE
        WHEN audience_segment IS NULL
          OR audience_segment = ''
        THEN 1
        ELSE 0
    END AS missing_audience_segment_flag,

    -- Flag stale profiles
    -- Profiles with no activity in the last 365 days are considered stale
    CASE
        WHEN last_activity_date < '2025-10-10'
        THEN 1
        ELSE 0
    END AS stale_profile_flag

FROM consumers_clean;


-- 3. Inspect the first rows of the validated table
SELECT *
FROM consumers_validated
LIMIT 20;


-- 4. Validate standardized product taxonomy
SELECT DISTINCT product_interest
FROM consumers_validated
ORDER BY product_interest;


-- 5. Validate standardized lifecycle taxonomy
SELECT DISTINCT lifecycle_stage
FROM consumers_validated
ORDER BY lifecycle_stage;


-- 6. Add duplicate-consumer flag
ALTER TABLE consumers_validated
ADD COLUMN duplicated_consumer_flag INTEGER DEFAULT 0;


-- 7. Flag every record belonging to a duplicated consumer ID
UPDATE consumers_validated
SET duplicated_consumer_flag = 1
WHERE consumer_id IN (
    SELECT consumer_id
    FROM consumers_validated
    GROUP BY consumer_id
    HAVING COUNT(*) > 1
);


-- 8. Review duplicated-flag distribution
SELECT
    duplicated_consumer_flag,
    COUNT(*) AS records
FROM consumers_validated
GROUP BY duplicated_consumer_flag;


-- 9. Add consent-conflict flag
ALTER TABLE consumers_validated
ADD COLUMN consent_conflict_flag INTEGER DEFAULT 0;


-- 10. Flag consumers with inconsistent marketing-consent values
UPDATE consumers_validated
SET consent_conflict_flag = 1
WHERE consumer_id IN (
    SELECT consumer_id
    FROM consumers_validated
    GROUP BY consumer_id
    HAVING COUNT(DISTINCT marketing_consent) > 1
);


-- 11. Add total quality-issue count
ALTER TABLE consumers_validated
ADD COLUMN quality_issue_count INTEGER DEFAULT 0;


-- 12. Calculate number of quality issues for each record
UPDATE consumers_validated
SET quality_issue_count =
      missing_email_flag
    + malformed_email_flag
    + missing_marketing_consent_flag
    + invalid_activation_flag
    + missing_audience_segment_flag
    + stale_profile_flag
    + duplicated_consumer_flag
    + consent_conflict_flag;


-- 13. Add activation-readiness status
ALTER TABLE consumers_validated
ADD COLUMN activation_readiness TEXT;


-- 14. Classify records as READY, REVIEW or NOT READY
UPDATE consumers_validated
SET activation_readiness =
    CASE
        -- No valid marketing consent means the record should not be activated
        WHEN marketing_consent IS NULL
         OR marketing_consent = ''
         OR marketing_consent = 'NO'
        THEN 'NOT READY'

        -- Consent conflicts require investigation
        WHEN consent_conflict_flag = 1
            THEN 'REVIEW'

        -- Missing email may limit matching and activation
        WHEN missing_email_flag = 1
            THEN 'REVIEW'

        -- Malformed email may prevent correct matching
        WHEN malformed_email_flag = 1
            THEN 'REVIEW'

        -- Missing audience classification reduces activation usability
        WHEN missing_audience_segment_flag = 1
            THEN 'REVIEW'

        -- Old activity may make the consumer profile less relevant
        WHEN stale_profile_flag = 1
            THEN 'REVIEW'

        -- If no critical issue is detected, the record is ready
        ELSE 'READY'
    END;


-- 15. Review activation-readiness distribution
SELECT
    activation_readiness,
    COUNT(*) AS records
FROM consumers_validated
GROUP BY activation_readiness
ORDER BY records DESC;


-- 16. Inspect non-ready and review records
SELECT
    consumer_id,
    email,
    country,
    marketing_consent,
    activated_for_marketing,
    quality_issue_count,
    activation_readiness
FROM consumers_validated
WHERE activation_readiness <> 'READY'
ORDER BY quality_issue_count DESC
LIMIT 50;


-- 17. Calculate percentage of activation-ready records
SELECT
    ROUND(
        SUM(
            CASE
                WHEN activation_readiness = 'READY'
                THEN 1
                ELSE 0
            END
        ) * 100.0 / COUNT(*),
        2
    ) AS ready_records_percent
FROM consumers_validated;


-- 18. Review distribution of quality issues
SELECT
    quality_issue_count,
    COUNT(*) AS records
FROM consumers_validated
GROUP BY quality_issue_count
ORDER BY quality_issue_count;

UPDATE consumers_validated
SET activation_readiness =
    CASE
        WHEN marketing_consent IS NULL
          OR marketing_consent = ''
          OR marketing_consent = 'NO'
            THEN 'NOT READY'

        WHEN consent_conflict_flag = 1
            THEN 'REVIEW'

        WHEN missing_email_flag = 1
            THEN 'REVIEW'

        WHEN malformed_email_flag = 1
            THEN 'REVIEW'

        WHEN missing_audience_segment_flag = 1
            THEN 'REVIEW'

        WHEN stale_profile_flag = 1
            THEN 'REVIEW'

        ELSE 'READY'
    END;