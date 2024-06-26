{{
    config(
        materialized="table",
        alias="google_analytics_site_all",
        schema="stg_standard_dashboard",
    )
}}

select *
from {{ source("src_google_analytics", "ga4_site_all") }}
where
    (yearmonth >= '2023-07-01' or type = 'to_date') and platform != 'Cosgrove Partners'
union all
select *
from {{ source("src_google_analytics", "ua_site_all") }}
where yearmonth < '2023-07-01' and platform != 'Cosgrove Partners'
