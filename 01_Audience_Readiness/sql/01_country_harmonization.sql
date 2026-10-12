CREATE TABLE consumers_clean AS
SELECT
    consumer_id,
    email,
    CASE
        WHEN country IN ('Spain', 'ES', 'ESP') THEN 'Spain'
        WHEN country IN ('France', 'FR', 'FRA') THEN 'France'
        WHEN country IN ('Germany', 'DE', 'DEU') THEN 'Germany'
        WHEN country IN ('United Kingdom', 'UK', 'GB', 'GBR') THEN 'United Kingdom'
        ELSE 'Unknown'
    END AS country,
    source_system,
    product_interest,
    lifecycle_stage,
    marketing_consent,
    analytics_consent,
    last_activity_date,
    audience_segment,
    campaign_id,
    activated_for_marketing,
    profile_created_date,
    age_band
FROM consumers_raw;