select *
from {{ source("src_google_analytics", "ga4_page_all") }}
where yearmonth >= '2023-07-01' and platform != 'Cosgrove Partners'
union all
select *
from {{ source("src_google_analytics", "ua_page_all") }}
where yearmonth < '2023-07-01' and platform != 'Cosgrove Partners'
