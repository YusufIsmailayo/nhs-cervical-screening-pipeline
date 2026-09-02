# NHS Cervical Screening Coverage Pipeline

An end-to-end data engineering pipeline over every public source that reports cervical screening
coverage in England, built using a Bronze→Silver→Gold medallion architecture.

**Key finding: none of England's 151 local authorities reached the 80% screening coverage target at
31 March 2024 — and that date is still the most recent for which a national figure has been
published.**

## Project Overview

On 25 August 2026 NHS England announced HPV self-testing kits for nearly 4 million women who had not
attended cervical screening, citing coverage of 68.8% against a target of 80%. The release does not
date that figure.

This pipeline was built to find out how current it was, and whether anything more recent exists. It
ingests all three public series that report the metric — the annual statistical bulletin, the
quarterly management information dashboard, and the quarterly coverage reports on GOV.UK — and
conforms them onto one coverage timeline so that reference date and publication date can be compared
directly.

The answer is that 68.8% describes 31 March 2024, and no public figure describes any period after
30 June 2024.

## Data Sources

| Source | Publisher | Published | Status |
|---|---|---|---|
| [Cervical Screening Programme, England 2023-24](https://digital.nhs.uk/data-and-information/publications/statistical/cervical-screening-annual/england-2023-24) | NHS England Digital | 28 Nov 2024 | Latest annual; 2024-25 edition delayed |
| [Coverage Statistics (Management Information)](https://digital.nhs.uk/data-and-information/publications/statistical/cervical-screening-programme/cervical-screening-programme-coverage-statistics-management-information) | NHS England Digital | 7 Jan 2025 | Publication ceased 1 Aug 2025 |
| [Quarterly coverage data reports](https://www.gov.uk/government/collections/cervical-screening-programme-data) | NHS England (GOV.UK) | to 16 Jul 2025 | 2024 report holds one quarter |
| [HPV self-testing announcement](https://www.england.nhs.uk/2026/08/nhs-rolls-out-discreet-home-testing-kits-against-cervical-cancer-for-millions-of-women/) | NHS England | 25 Aug 2026 | Context for the analysis |

Contains public sector information licensed under the Open Government Licence v3.0.

## Pipeline Architecture

Bronze → Silver → Gold

| Layer | Description | Output |
|---|---|---|
| Bronze | 13 sources declared by hand (9 used, 4 rejected with reasons), hashed, landed as text with provenance on every row | 14 Parquet tables, 7,338 rows, 20/20 checks |
| Silver | Three series conformed onto one grain; types, age bands, geography systems and comparability flags all decided explicitly | 11,181 rows, 14/14 checks |
| Gold | Distribution, timeline, publication register and a facts table the article reads from | 5 tables, 47 named facts, 10/10 checks |

Bronze is the only layer that touches the network, and it does so once. Every figure in the
accompanying article is a named row in `data/gold/facts.csv`, carrying its source and whether it was
computed from data or read off a page.

## Key Findings

- **0 of 151 local authorities** reached the 80% target at 31 March 2024. The highest, East Riding of
  Yorkshire, was 77.8%
- **31.1 percentage point spread** across local authorities, from Kensington and Chelsea at 46.7% to
  East Riding at 77.8%; the five lowest are all in London
- **68.8% is 877 days old** at the date of the announcement, and the last public observation of any
  kind describes 30 June 2024 — 786 days before it
- **643 days** since the last annual publication, against a longest previous gap of **418 days**
  across 20 editions since 2004-05
- **Coverage has fallen 5.4 points in a decade**, from 74.2% in March 2014, dropping in seven of ten
  years
- **The GOV.UK reports are not an independent series.** They agree with the ceased dashboard to
  within 0.0003 percentage points, and match exactly on two of five shared quarters
- **Two defensible national figures exist for the same day**: 68.80% counting women by residence,
  69.94% by GP registration, on eligible populations differing by 301,884 people
- **1,852,580 additional screens** would be needed to reach 80% — the publisher's own per-authority
  calculation, summed

## Provenance and Evidence

This repository differs from my other pipelines in one respect: `data/bronze/evidence/` is committed
rather than gitignored.

The central claims here are not in any spreadsheet. They are sentences on web pages — "This dashboard
is no longer produced", "The 2024-25 bulletin is delayed whilst we transition the reporting of data".
Pages get edited. Bronze therefore takes dated, hashed copies of all seven source pages plus three
GOV.UK Content API responses, and those copies are version-controlled. Everything else in `data/` can
be rebuilt from the fetch script; those cannot.

The Bronze manifest records every source with its URL, publisher, publication date, reference period
end, SHA-256 hash and retrieval timestamp — including the four sources examined and rejected, with
the reason for each.

## Reproducibility Check

The pipeline rebuilds NHS England's published headline from its own tables, summing numerators and
denominators across 151 local authorities:

```
England row in file      68.7988%
Summed from 151 LAs      68.7988%
Published figure         68.8%
Mean of LA percentages   68.5860%   <- the wrong method, out by 0.21pp
```

## Tech Stack

- Python (pandas, numpy)
- Parquet (pyarrow), ODS (odfpy), HTML parsing (beautifulsoup4)
- matplotlib
- JupyterLab / Anaconda
- Medallion architecture (Bronze→Silver→Gold)

## Notebooks

| Notebook | Purpose |
|---|---|
| `01_bronze.ipynb` | Declares and hashes sources, captures the source pages, lands raw tables |
| `02_silver.ipynb` | Conforms three series onto one grain; every transformation decision made here |
| `03_gold.ipynb` | Distribution, timeline, publication register, facts table |
| `04_charts.ipynb` | Two figures plus a table view of each |

## Repository Structure

```
nhs-cervical-screening-pipeline/
├── notebooks/
│   ├── 01_bronze.ipynb
│   ├── 02_silver.ipynb
│   ├── 03_gold.ipynb
│   └── 04_charts.ipynb
├── data/
│   ├── bronze/
│   │   ├── raw/            # gitignored — regenerate with fetch_sources.sh
│   │   ├── tables/         # gitignored — regenerate by running 01_bronze
│   │   ├── evidence/       # committed: dated copies of the source pages
│   │   ├── manifest.csv
│   │   └── manifest.parquet
│   ├── silver/
│   └── gold/
│       ├── facts.csv
│       ├── la_coverage_2024_03_31.csv
│       ├── publication_register.csv
│       └── annual_publication_cadence.csv
├── charts/
├── fetch_sources.sh
├── .gitignore
└── README.md
```

## How to Reproduce

```bash
git clone https://github.com/YusufIsmailayo/nhs-cervical-screening-pipeline.git
cd nhs-cervical-screening-pipeline
pip install pandas pyarrow odfpy beautifulsoup4 matplotlib
bash fetch_sources.sh
jupyter lab
```

Then run notebooks 01 → 02 → 03 → 04 in order.

`fetch_sources.sh` downloads ten files from NHS England Digital and GOV.UK. If a publisher has
amended a file since this repository was built, the hash in `data/bronze/manifest.csv` will no longer
match and Bronze will tell you which one — which is the point of recording them.

## Article

*Four Million Test Kits, Measured Against a Number From March 2024* — on Medium.

## Author

Yusuf Ismail — Data Engineer | NHS & Public Sector Analytics
[GitHub](https://github.com/YusufIsmailayo) |
[Medium](https://medium.com/@yusufismail_91982)
