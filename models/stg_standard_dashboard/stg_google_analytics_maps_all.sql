{{
    config(
        materialized="table",
        alias="google_analytics_maps_all",
        schema="stg_standard_dashboard",
    )
}}

select *
from {{ source("src_google_analytics", "ga4_maps_all") }}
where yearmonth >= '2023-07-01' and platform != 'Cosgrove Partners'
union all
select *
from {{ source("src_google_analytics", "ua_maps_all") }}
where yearmonth < '2023-07-01' and platform != 'Cosgrove Partners'
