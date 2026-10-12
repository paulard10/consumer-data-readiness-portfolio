import pandas as pd


# -----------------------------
# Load dataset
# -----------------------------

data = pd.read_csv("data/novacare_consumers_raw.csv")

print(data.head())
total_rows = data.shape[0]
total_columns = data.shape[1]


# -----------------------------
# Missing email check
# -----------------------------

missing_emails = (
    data["email"].isna()
    | (data["email"] == "")
).sum()


# -----------------------------
# Malformed email check
# -----------------------------

malformed_email_mask = (
    data["email"].notna()
    & (data["email"] != "")
    & ~data["email"].str.contains(r"@", na=False)
)

malformed_emails = malformed_email_mask.sum()


# -----------------------------
# Identity / duplicated checks
# -----------------------------

unique_consumers = data["consumer_id"].nunique()

duplicated_records = total_rows - unique_consumers

duplicated_mask = data["consumer_id"].duplicated(keep=False)

duplicated_flagged_records = duplicated_mask.sum()


# -----------------------------
# Marketing consent checks
# -----------------------------

missing_consent = (
    data["marketing_consent"].isna()
    | (data["marketing_consent"] == "")
).sum()


invalid_activation_mask = (
    (data["activated_for_marketing"] == "YES")
    &
    (
        data["marketing_consent"].isna()
        | (data["marketing_consent"] == "")
        | (data["marketing_consent"] == "NO")
    )
)

invalid_activations = invalid_activation_mask.sum()


# -----------------------------
# Audience segmentation check
# -----------------------------

missing_audience_segment = (
    data["audience_segment"].isna()
    | (data["audience_segment"] == "")
).sum()


# -----------------------------
# Freshness check
# -----------------------------

data["last_activity_date"] = pd.to_datetime(
    data["last_activity_date"]
)

cutoff_date = pd.Timestamp("2025-10-10")

stale_mask = data["last_activity_date"] < cutoff_date

stale_profiles = stale_mask.sum()


# -----------------------------
# Consent conflict check
# -----------------------------

consent_values_per_consumer = (
    data.groupby("consumer_id")["marketing_consent"]
    .nunique()
)

consumers_with_consent_conflicts = (
    consent_values_per_consumer > 1
).sum()

# -----------------------------
# Create row-level quality flags
# -----------------------------

data["missing_email_flag"] = (
    data["email"].isna()
    | (data["email"] == "")
).astype(int)

data["malformed_email_flag"] = malformed_email_mask.astype(int)

data["duplicated_consumer_flag"] = duplicated_mask.astype(int)

data["missing_marketing_consent_flag"] = (
    data["marketing_consent"].isna()
    | (data["marketing_consent"] == "")
).astype(int)

data["invalid_activation_flag"] = invalid_activation_mask.astype(int)

data["missing_audience_segment_flag"] = (
    data["audience_segment"].isna()
    | (data["audience_segment"] == "")
).astype(int)

data["stale_profile_flag"] = stale_mask.astype(int)

conflicting_consumer_ids = (
    consent_values_per_consumer[
        consent_values_per_consumer > 1
    ]
    .index
)

data["consent_conflict_flag"] = (
    data["consumer_id"]
    .isin(conflicting_consumer_ids)
    .astype(int)
)

approved_countries = {
    "Spain",
    "France",
    "Germany",
    "United Kingdom"
}

approved_products = {
    "Skincare",
    "Allergy",
    "Pain Relief",
    "Digestive Health"
}

approved_lifecycle_stages = {
    "Prospect",
    "New Customer",
    "Active Customer",
    "Lapsed Customer"
}

country_mapping = {
    "Spain": "Spain",
    "ES": "Spain",
    "ESP": "Spain",

    "France": "France",
    "FR": "France",
    "FRA": "France",

    "Germany": "Germany",
    "DE": "Germany",
    "DEU": "Germany",

    "United Kingdom": "United Kingdom",
    "UK": "United Kingdom",
    "GB": "United Kingdom",
    "GBR": "United Kingdom"
}

data["country_standardized"] = (
    data["country"]
    .map(country_mapping)
    .fillna("Unknown")
)

product_mapping = {
    "Skincare": "Skincare",
    "Skin Care": "Skincare",
    "skin-care": "Skincare",

    "Allergy": "Allergy",
    "Allergies": "Allergy",
    "allergy": "Allergy",

    "Pain Relief": "Pain Relief",
    "Pain relief": "Pain Relief",
    "Pain-Relief": "Pain Relief",

    "Digestive Health": "Digestive Health",
    "Digestive": "Digestive Health",
    "digestive-health": "Digestive Health"
}

data["product_interest_standardized"] = (
    data["product_interest"]
    .map(product_mapping)
    .fillna("Unknown")
)

lifecycle_mapping = {
    "Prospect": "Prospect",
    "Prospects": "Prospect",

    "New Customer": "New Customer",
    "NEW": "New Customer",

    "Active Customer": "Active Customer",
    "Active": "Active Customer",

    "Lapsed Customer": "Lapsed Customer",
    "Lapsed": "Lapsed Customer"
}

data["lifecycle_stage_standardized"] = (
    data["lifecycle_stage"]
    .map(lifecycle_mapping)
    .fillna("Unknown")
)

data["taxonomy_issue_flag"] = (
    (data["country_standardized"] == "Unknown")
    | (data["product_interest_standardized"] == "Unknown")
    | (data["lifecycle_stage_standardized"] == "Unknown")
).astype(int)

quality_flag_columns = [
    "missing_email_flag",
    "malformed_email_flag",
    "duplicated_consumer_flag",
    "missing_marketing_consent_flag",
    "invalid_activation_flag",
    "missing_audience_segment_flag",
    "stale_profile_flag",
    "consent_conflict_flag",
    "taxonomy_issue_flag"
]

data["quality_issue_count"] = data[
    quality_flag_columns
].sum(axis=1)

def classify_readiness(row):
    if (
        pd.isna(row["marketing_consent"])
        or row["marketing_consent"] == ""
        or row["marketing_consent"] == "NO"
    ):
        return "NOT READY"

    if row["consent_conflict_flag"] == 1:
        return "REVIEW"

    if row["missing_email_flag"] == 1:
        return "REVIEW"

    if row["malformed_email_flag"] == 1:
        return "REVIEW"

    if row["missing_audience_segment_flag"] == 1:
        return "REVIEW"

    if row["stale_profile_flag"] == 1:
        return "REVIEW"

    return "READY"

data["activation_readiness"] = data.apply(
    classify_readiness, axis=1)

data.to_csv(
    "output/validated_data.csv",
    index=False
)

exceptions = data[
    data["quality_issue_count"] > 0
].copy()

exceptions.to_csv(
    "output/exceptions_report.csv",
    index=False
)

summary = pd.DataFrame({
    "metric": [
        "Total Records",
        "Unique Consumers",
        "Missing Emails",
        "Malformed Emails",
        "Duplicated Records",
        "Duplicated-Flagged Records",
        "Missing Marketing Consent",
        "Invalid Marketing Activations",
        "Missing Audience Segments",
        "Stale Profiles",
        "Consumers with Consent Conflicts",
        "Taxonomy Issues"
    ],
    "value": [
        total_rows,
        unique_consumers,
        missing_emails,
        malformed_emails,
        duplicated_records,
        duplicated_flagged_records,
        missing_consent,
        invalid_activations,
        missing_audience_segment,
        stale_profiles,
        consumers_with_consent_conflicts,
        data["taxonomy_issue_flag"].sum()
    ]
})

summary.to_csv(
    "output/data_quality_summary.csv",
    index=False
)

readiness_counts = (
    data["activation_readiness"]
    .value_counts()
)

print()
print("Activation Readiness:")
print(readiness_counts)
print()

# -----------------------------
# Calculate quality rates
# -----------------------------

missing_email_rate = missing_emails / total_rows

malformed_email_rate = malformed_emails / total_rows

duplicated_flagged_rate = (
    duplicated_flagged_records / total_rows
)

missing_consent_rate = (
    missing_consent / total_rows
)

invalid_activation_rate = (
    invalid_activations / total_rows
)

missing_audience_segment_rate = (
    missing_audience_segment / total_rows
)

stale_profile_rate = (
    stale_profiles / total_rows
)

consent_conflict_rate = (
    consumers_with_consent_conflicts
    / unique_consumers
)

taxonomy_issue_rate = (
    data["taxonomy_issue_flag"].sum()
    / total_rows
)

# -----------------------------
# Severity classification
# -----------------------------

def classify_severity(
    rate,
    warning_threshold,
    critical_threshold
):
    if rate >= critical_threshold:
        return "CRITICAL"

    if rate >= warning_threshold:
        return "WARNING"

    return "OK"

# -----------------------------
# Monitoring thresholds
# -----------------------------

monitoring_rules = {
    "Missing Email": {
        "rate": missing_email_rate,
        "warning": 0.02,
        "critical": 0.05
    },

    "Malformed Email": {
        "rate": malformed_email_rate,
        "warning": 0.01,
        "critical": 0.02
    },

    "Duplicated-Flagged Records": {
        "rate": duplicated_flagged_rate,
        "warning": 0.02,
        "critical": 0.05
    },

    "Missing Marketing Consent": {
        "rate": missing_consent_rate,
        "warning": 0.03,
        "critical": 0.05
    },

    "Invalid Marketing Activation": {
        "rate": invalid_activation_rate,
        "warning": 0.02,
        "critical": 0.05
    },

    "Missing Audience Segment": {
        "rate": missing_audience_segment_rate,
        "warning": 0.02,
        "critical": 0.05
    },

    "Stale Profiles": {
        "rate": stale_profile_rate,
        "warning": 0.10,
        "critical": 0.20
    },

    "Consent Conflicts": {
        "rate": consent_conflict_rate,
        "warning": 0.001,
        "critical": 0.005
    },

    "Taxonomy Issues": {
        "rate": taxonomy_issue_rate,
        "warning": 0.01,
        "critical": 0.03
    }
}

alerts = []

for metric_name, rule in monitoring_rules.items():

    severity = classify_severity(
        rule["rate"],
        rule["warning"],
        rule["critical"]
    )

    alerts.append({
        "metric": metric_name,
        "current_rate": rule["rate"],
        "warning_threshold": rule["warning"],
        "critical_threshold": rule["critical"],
        "severity": severity
    })

alerts_df = pd.DataFrame(alerts)

alerts_df["current_rate_percent"] = (
    alerts_df["current_rate"] * 100
).round(2)

alerts_df["warning_threshold_percent"] = (
    alerts_df["warning_threshold"] * 100
).round(2)

alerts_df["critical_threshold_percent"] = (
    alerts_df["critical_threshold"] * 100
).round(2)

if (
    alerts_df["severity"] == "CRITICAL"
).any():
    overall_monitoring_status = "CRITICAL"

elif (
    alerts_df["severity"] == "WARNING"
).any():
    overall_monitoring_status = "WARNING"

else:
    overall_monitoring_status = "OK"

# -----------------------------
# Report
# -----------------------------

print()
print("NOVACARE CONSUMER DATA QUALITY REPORT")
print("-------------------------------------")

print("Total records:", total_rows)
print("Total columns:", total_columns)
print("Unique consumers:", unique_consumers)

print()

print("Missing emails:", missing_emails)
print("Malformed emails:", malformed_emails)
print("Duplicated records:", duplicated_records)
print("Duplicated-flagged records:", duplicated_flagged_records)
print("Missing marketing consent:", missing_consent)
print("Invalid marketing activations:", invalid_activations)
print("Missing audience segments:", missing_audience_segment)
print("Stale profiles:", stale_profiles)
print(
    "Consumers with consent conflicts:",
    consumers_with_consent_conflicts
)

print()
print("AUTOMATED MONITORING STATUS")
print("---------------------------")
print(
    "Overall status:",
    overall_monitoring_status)

print()

for _, alert in alerts_df.iterrows():

    print(
        f"{alert['severity']:<8} | "
        f"{alert['metric']}: "
        f"{alert['current_rate_percent']:.2f}% "
        f"| Warning: "
        f"{alert['warning_threshold_percent']:.2f}% "
        f"| Critical: "
        f"{alert['critical_threshold_percent']:.2f}%"
    )

alerts_df.to_csv(
    "output/monitoring_alerts.csv",
    index=False
)

monitoring_summary = pd.DataFrame({
    "overall_monitoring_status": [
        overall_monitoring_status
    ],
    "critical_alerts": [
        (
            alerts_df["severity"]
            == "CRITICAL"
        ).sum()
    ],
    "warning_alerts": [
        (
            alerts_df["severity"]
            == "WARNING"
        ).sum()
    ],
    "ok_metrics": [
        (
            alerts_df["severity"]
            == "OK"
        ).sum()
    ]
})

monitoring_summary.to_csv(
    "output/monitoring_summary.csv",
    index=False
)

print()
print("Files generated successfully:")
print("- output/validated_data.csv")
print("- output/exceptions_report.csv")
print("- output/data_quality_summary.csv")
print("- output/monitoring_alerts.csv")
print("- output/monitoring_summary.csv")