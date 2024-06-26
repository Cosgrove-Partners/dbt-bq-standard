{{
    config(
        materialized="materialized_view",
        on_configuration_change="apply",
        enable_refresh=True,
        refresh_interval_minutes=30,
        max_staleness="INTERVAL 60 MINUTE",
    )
}}

select
    * except (tenant),
    if(platform like '1-Tom-Plumber%', '1-Tom-Plumber', tenant) as tenant
from {{ source("datashake", "google_reviews") }}
where tenant not in ('Dayton', 'Kentucky')
