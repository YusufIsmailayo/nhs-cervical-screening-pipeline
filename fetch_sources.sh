#!/usr/bin/env bash
# I download every raw source file for the cervical screening pipeline.
# I run this from my own Terminal on the Mac, not from a sandboxed shell,
# because the sandbox proxy blocks the NHS and GOV.UK file hosts.
#
#   cd ~/projects/nhs-cervical-screening-pipeline && bash fetch_sources.sh
#
# Every file lands under data/bronze/raw/ and nothing downstream reaches
# the network again — Bronze is the only layer that touches the internet.

set -u
cd "$(dirname "$0")" || exit 1
RAW="data/bronze/raw"
mkdir -p "$RAW/annual_2023_24" "$RAW/mi_quarterly" "$RAW/govuk_quarterly"

get () {
  # get <destination path> <url>
  if [ -s "$1" ]; then
    echo "skip (already have)  $1"
    return
  fi
  echo "fetching             $1"
  curl -sSL --fail --retry 3 --connect-timeout 30 -o "$1" "$2" \
    || echo "FAILED               $1"
}

echo "== Annual publication, Cervical Screening Programme England 2023-24 =="
echo "== NHS England Digital, published 28 November 2024                  =="
get "$RAW/annual_2023_24/cervical-screening-programme-eng-2023-24-tab.xlsx" \
    "https://files.digital.nhs.uk/7F/F4B9D8/cervical-screening-programme-eng-2023-24-tab.xlsx"
get "$RAW/annual_2023_24/cervical-programme-annual-2023-24-csvs.zip" \
    "https://files.digital.nhs.uk/7E/4984C9/cervical-programme-annual-2023-24-csvs.zip"

echo
echo "== Quarterly management information dashboard, publication ceased   =="
echo "== NHS England Digital, last data 7 January 2025 (Q1 2024-25)       =="
get "$RAW/mi_quarterly/cerv-scre-cov-stats-csv.zip" \
    "https://files.digital.nhs.uk/A7/2F8C4D/cerv-scre-cov-stats-csv.zip"
get "$RAW/mi_quarterly/q1-2024-25-data-quality-issue.xlsx" \
    "https://files.digital.nhs.uk/E6/CBC257/Q1%202024_25%20Data%20Quality%20Issue%20-%20Duplicated%20GP%20practices.xlsx"

echo
echo "== GOV.UK quarterly coverage reports, 2023 collection page          =="
get "$RAW/govuk_quarterly/coverage_data_tables_Mar_23.ods" \
    "https://assets.publishing.service.gov.uk/media/653bd1c980884d0013f71ccb/Cervical_Screening_Coverage_Report_Data_Tables_Mar_23.ods"
get "$RAW/govuk_quarterly/coverage_data_tables_Jun_23.ods" \
    "https://assets.publishing.service.gov.uk/media/653bc657d10f3500139a6ac6/Cervical_Screening_Coverage_Report_Data_Tables_Jun_23.ods"
get "$RAW/govuk_quarterly/coverage_data_tables_Sep_23.ods" \
    "https://assets.publishing.service.gov.uk/media/65c10043704282000d752245/Cervical_Screening_Coverage_Report_Data_Tables_SEP_23.ods"
get "$RAW/govuk_quarterly/coverage_data_tables_Dec_23.ods" \
    "https://assets.publishing.service.gov.uk/media/662a511055e1582b6ca7e611/Cervical_Screening_Coverage_Report_Data_Tables_Dec_23.ods"

echo
echo "== GOV.UK quarterly coverage reports, 2024 page                     =="
echo "== published 16 July 2025, March 2024 only, not listed in the       =="
echo "== collection index                                                 =="
get "$RAW/govuk_quarterly/coverage_data_tables_Mar_24.ods" \
    "https://assets.publishing.service.gov.uk/media/66d838847a73423428aa2f0f/Cervical_Screening_Coverage_Report_Data_Tables_Mar_24.ods"
get "$RAW/govuk_quarterly/coverage_subicb_gp_Mar_24.xlsx" \
    "https://assets.publishing.service.gov.uk/media/66d8389bdbffedc7eb44d1ce/Cervical_Screening_Coverage_Report_SubICB_GP_Mar2024_v1.0.xlsx"

echo
echo "== What landed =="
find "$RAW" -type f -exec ls -lh {} \; | awk '{print $5"\t"$9}'
