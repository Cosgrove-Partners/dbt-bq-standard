{{
    config(
        materialized="table",
        alias="quickbooks_balance_sheet_all",
        schema="stg_standard_dashboard",
    )
}}

select *
from
    (
        select
            * except (location, report_date, value),
            cast(report_date as date) report_date,
            cast(if(value = '', '0', value) as float64) value,
            if(
                lower(location) like '%dayton%'
                and lower(location) not like '%deleted%',
                'Dayton',
                'Cincinnati'
            ) as location
        from {{ source("src_quickbooks", "balance_sheet") }}
        where location != 'TOTAL'
    )
where location is not null
