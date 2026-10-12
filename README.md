# Consumer Data & Media Analytics Portfolio

A three-part portfolio built around **NovaCare**, a fictional global Consumer Health company operating across Spain, France, Germany and the United Kingdom.

Together, the projects follow one storyline: from **assessing whether consumer data is ready for marketing activation**, to **automating those quality checks**, to **connecting data quality with media performance** in a business-facing dashboard.

> All data in this repository is synthetic. No real consumer or personal data is included.

---

## Projects

| # | Project | Focus | Tools |
|---|---|---|---|
| 01 | [Audience Readiness](01_Audience_Readiness/) | Profiling, harmonizing and validating consumer data; weighted Data Readiness Score | SQL (SQLite), DB Browser for SQLite, Excel |
| 02 | [Data Quality Automation](02_Data_Quality_Automation/) | Automated, rule-based quality monitoring with severity thresholds and generated reports | Python, pandas |
| 03 | [Media Dashboard](03_Media_Dashboard/) | Media performance, audience activation and data-quality monitoring in one report | Power BI, DAX, star-schema modelling |

---

### 01 · Consumer Data Readiness Analysis

Evaluates 10,150 consumer records from four source systems (Website, CRM, Mobile App, Retail Partner) for accuracy, consistency, consent compliance and activation readiness.

- Standardized country, product and lifecycle taxonomies with SQL `CASE` logic, keeping raw data untouched
- Built row-level quality flags and classified profiles as `READY`, `REVIEW` or `NOT READY`
- Designed an illustrative five-dimension **Data Readiness Score** (overall: **81.09**)
- Key risks surfaced: **2,006 invalid marketing activations** (19.76%) and **49.59% stale profiles**

➡️ [Read more](01_Audience_Readiness/README.md)

### 02 · Automated Consumer Data Quality Monitor

Turns the manual SQL workflow into a reusable Python monitor.

- Ingests raw data, applies quality checks and taxonomy standardization, and flags issues per record
- Classifies each metric as `OK`, `WARNING` or `CRITICAL` against configurable thresholds
- Automatically generates five output reports (validated data, exceptions queue, summary, alerts, monitoring status)
- Cross-validated against the SQL results, which exposed and fixed a `NULL`-handling bug in the original consent rule

➡️ [Read more](02_Data_Quality_Automation/README.md)

### 03 · Media Activation & Performance Dashboard

A Power BI report linking campaign results to the quality of the data behind them.

- Star schema with one fact table (media performance) and two dimensions (audience taxonomy, campaign metadata)
- DAX measures for core media KPIs (ROAS, CPA, CTR, conversion rate) and data-quality KPIs (consent validity, unmapped audiences, missing tags, delayed feeds)
- Four report pages: Executive Overview, Audience & Activation, Data Quality & Monitoring, Executive Recommendations

➡️ [Read more](03_Media_Dashboard/README.md)

---

### Why does Project 01 say GOOD while Project 02 says CRITICAL?

These statuses answer different questions. Project 01 uses a weighted readiness score across multiple dimensions, producing an overall status of **GOOD**. Project 02 uses rule-based monitoring thresholds, where a single severe metric can trigger an overall **CRITICAL** alert. The two results are therefore complementary rather than contradictory.

---

## Key Takeaways

- **Data readiness is more than clean data.** Records can be complete and well structured yet still unusable for activation without valid consent.
- **Automation needs governance.** Thresholds, consent rules and identity-survivorship logic must be agreed with Privacy, Data Governance and Marketing stakeholders.
- **Test business rules across implementations.** Comparing SQL and Python outputs caught a logic error that technically valid code had hidden.
- **Media performance depends on data quality.** Strong ROAS means little if the underlying audiences are unconsented, unmapped or mistagged.

---

## Repository Structure

```text
consumer-data-readiness-portfolio/
├── 01_Audience_Readiness/        # SQL + Excel readiness analysis
│   ├── data/
│   ├── sql/
│   ├── excel/
│   ├── screenshots/
│   └── README.md
├── 02_Data_Quality_Automation/   # Python data-quality monitor
│   ├── data/
│   ├── scripts/
│   ├── output/
│   ├── screenshots/
│   └── README.md
├── 03_Media_Dashboard/           # Power BI dashboard
│   ├── data/
│   ├── powerbi/
│   ├── screenshots/
│   └── README.md
├── .gitignore
└── README.md
```

---

## Running Project 02

```bash
cd 02_Data_Quality_Automation
pip install pandas
python scripts/01_data_quality_monitor.py
```

Outputs are written to `02_Data_Quality_Automation/output/`.
