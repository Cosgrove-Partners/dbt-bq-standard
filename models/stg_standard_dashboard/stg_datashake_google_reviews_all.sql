{{
    config(
        materialized="materialized_view",
        on_configuration_change="apply",
        enable_refresh=True,
        refresh_interval_minutes=30,
        max_staleness="INTERVAL 60 MINUTE",
        alias="datashake_google_reviews_all",
        schema="stg_standard_dashboard",
    )
}}

select *
from {{ source("datashake", "google_reviews") }}
