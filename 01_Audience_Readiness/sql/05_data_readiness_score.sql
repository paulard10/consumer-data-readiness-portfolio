-- Project 1: Consumer Audience Readiness
-- Step 5: Data Readiness Score
-- Purpose:
-- Tighten activation-readiness logic, add taxonomy-quality checks,
-- calculate component scores, and generate an overall readiness score.


-- 1. Tighten activation-readiness logic
-- Missing, blank or negative marketing consent is NOT READY.
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


-- 2. Validate readiness logic by consent status
SELECT
    marketing_consent,
    activation_readiness,
    COUNT(*) AS records
FROM consumers_validated
GROUP BY
    marketing_consent,
    activation_readiness
ORDER BY
    marketing_consent,
    activation_readiness;


-- 3. Validation test:
-- There should be zero READY records without valid marketing consent.
SELECT
    COUNT(*) AS incorrectly_ready_records
FROM consumers_validated
WHERE activation_readiness = 'READY'
  AND (
        marketing_consent IS NULL
        OR marketing_consent = ''
        OR marketing_consent = 'NO'
      );


-- 4. Add taxonomy-quality flag
ALTER TABLE consumers_validated
ADD COLUMN taxonomy_issue_flag INTEGER DEFAULT 0;


-- 5. Flag records with unresolved taxonomy values
UPDATE consumers_validated
SET taxonomy_issue_flag =
    CASE
        WHEN country = 'Unknown'
          OR product_interest = 'Unknown'
          OR lifecycle_stage = 'Unknown'
        THEN 1
        ELSE 0
    END;


-- 6. Recalculate total quality-issue count
-- Includes the newly added taxonomy issue.
UPDATE consumers_validated
SET quality_issue_count =
      missing_email_flag
    + malformed_email_flag
    + missing_marketing_consent_flag
    + invalid_activation_flag
    + missing_audience_segment_flag
    + stale_profile_flag
    + duplicated_consumer_flag
    + consent_conflict_flag
    + taxonomy_issue_flag;


-- 7. Calculate Completeness Score
-- Based on email, marketing consent and audience segment availability.
SELECT
    ROUND(
        (
            SUM(
                CASE
                    WHEN missing_email_flag = 0
                    THEN 1
                    ELSE 0
                END
            )
            +
            SUM(
                CASE
                    WHEN missing_marketing_consent_flag = 0
                    THEN 1
                    ELSE 0
                END
            )
            +
            SUM(
                CASE
                    WHEN missing_audience_segment_flag = 0
                    THEN 1
                    ELSE 0
                END
            )
        ) * 100.0
        /
        (COUNT(*) * 3),
        2
    ) AS completeness_score
FROM consumers_validated;


-- 8. Calculate Consent Compliance Score
-- Of all activated records, what percentage had valid marketing consent?
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
    ) AS consent_compliance_score
FROM consumers_validated;


-- 9. Calculate Identity Quality Score
-- Records without duplicated identity issues or consent conflicts.
SELECT
    ROUND(
        SUM(
            CASE
                WHEN duplicated_consumer_flag = 0
                 AND consent_conflict_flag = 0
                THEN 1
                ELSE 0
            END
        ) * 100.0
        /
        COUNT(*),
        2
    ) AS identity_quality_score
FROM consumers_validated;


-- 10. Calculate Taxonomy Quality Score
-- Records whose standardized taxonomy does not contain unresolved values.
SELECT
    ROUND(
        SUM(
            CASE
                WHEN taxonomy_issue_flag = 0
                THEN 1
                ELSE 0
            END
        ) * 100.0
        /
        COUNT(*),
        2
    ) AS taxonomy_quality_score
FROM consumers_validated;


-- 11. Calculate Freshness Score
-- Profiles active within the last 365 days.
SELECT
    ROUND(
        SUM(
            CASE
                WHEN stale_profile_flag = 0
                THEN 1
                ELSE 0
            END
        ) * 100.0
        /
        COUNT(*),
        2
    ) AS freshness_score
FROM consumers_validated;


-- 12. Calculate all component scores and the weighted
-- overall Consumer Data Readiness Score.
--
-- Illustrative weighting:
-- Completeness:       20%
-- Consent Compliance:30%
-- Identity Quality:   20%
-- Taxonomy Quality:   15%
-- Freshness:          15%

WITH scores AS (

    SELECT

        -- Completeness Score
        ROUND(
            (
                SUM(
                    CASE
                        WHEN missing_email_flag = 0
                        THEN 1
                        ELSE 0
                    END
                )
                +
                SUM(
                    CASE
                        WHEN missing_marketing_consent_flag = 0
                        THEN 1
                        ELSE 0
                    END
                )
                +
                SUM(
                    CASE
                        WHEN missing_audience_segment_flag = 0
                        THEN 1
                        ELSE 0
                    END
                )
            ) * 100.0
            /
            (COUNT(*) * 3),
            2
        ) AS completeness_score,


        -- Consent Compliance Score
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
        ) AS consent_compliance_score,


        -- Identity Quality Score
        ROUND(
            SUM(
                CASE
                    WHEN duplicated_consumer_flag = 0
                     AND consent_conflict_flag = 0
                    THEN 1
                    ELSE 0
                END
            ) * 100.0
            /
            COUNT(*),
            2
        ) AS identity_quality_score,


        -- Taxonomy Quality Score
        ROUND(
            SUM(
                CASE
                    WHEN taxonomy_issue_flag = 0
                    THEN 1
                    ELSE 0
                END
            ) * 100.0
            /
            COUNT(*),
            2
        ) AS taxonomy_quality_score,


        -- Freshness Score
        ROUND(
            SUM(
                CASE
                    WHEN stale_profile_flag = 0
                    THEN 1
                    ELSE 0
                END
            ) * 100.0
            /
            COUNT(*),
            2
        ) AS freshness_score

    FROM consumers_validated
)

SELECT
    completeness_score,
    consent_compliance_score,
    identity_quality_score,
    taxonomy_quality_score,
    freshness_score,

    ROUND(
          completeness_score * 0.20
        + consent_compliance_score * 0.30
        + identity_quality_score * 0.20
        + taxonomy_quality_score * 0.15
        + freshness_score * 0.15,
        2
    ) AS overall_data_readiness_score

FROM scores;


-- 13. Final scorecard with business interpretation

WITH scores AS (

    SELECT

        (
            (
                SUM(
                    CASE
                        WHEN missing_email_flag = 0
                        THEN 1
                        ELSE 0
                    END
                )
                +
                SUM(
                    CASE
                        WHEN missing_marketing_consent_flag = 0
                        THEN 1
                        ELSE 0
                    END
                )
                +
                SUM(
                    CASE
                        WHEN missing_audience_segment_flag = 0
                        THEN 1
                        ELSE 0
                    END
                )
            ) * 100.0
            /
            (COUNT(*) * 3)
        ) AS completeness_score,


        (
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
            )
        ) AS consent_compliance_score,


        (
            SUM(
                CASE
                    WHEN duplicated_consumer_flag = 0
                     AND consent_conflict_flag = 0
                    THEN 1
                    ELSE 0
                END
            ) * 100.0
            /
            COUNT(*)
        ) AS identity_quality_score,


        (
            SUM(
                CASE
                    WHEN taxonomy_issue_flag = 0
                    THEN 1
                    ELSE 0
                END
            ) * 100.0
            /
            COUNT(*)
        ) AS taxonomy_quality_score,


        (
            SUM(
                CASE
                    WHEN stale_profile_flag = 0
                    THEN 1
                    ELSE 0
                END
            ) * 100.0
            /
            COUNT(*)
        ) AS freshness_score

    FROM consumers_validated
),

final_score AS (

    SELECT
        completeness_score,
        consent_compliance_score,
        identity_quality_score,
        taxonomy_quality_score,
        freshness_score,

        (
              completeness_score * 0.20
            + consent_compliance_score * 0.30
            + identity_quality_score * 0.20
            + taxonomy_quality_score * 0.15
            + freshness_score * 0.15
        ) AS overall_score

    FROM scores
)

SELECT
    ROUND(completeness_score, 2)
        AS completeness_score,

    ROUND(consent_compliance_score, 2)
        AS consent_compliance_score,

    ROUND(identity_quality_score, 2)
        AS identity_quality_score,

    ROUND(taxonomy_quality_score, 2)
        AS taxonomy_quality_score,

    ROUND(freshness_score, 2)
        AS freshness_score,

    ROUND(overall_score, 2)
        AS overall_data_readiness_score,

    CASE
        WHEN overall_score >= 90
            THEN 'EXCELLENT'

        WHEN overall_score >= 80
            THEN 'GOOD'

        WHEN overall_score >= 70
            THEN 'NEEDS IMPROVEMENT'

        ELSE 'HIGH RISK'
    END AS readiness_status

FROM final_score;