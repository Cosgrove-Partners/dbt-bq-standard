with
    quickbooks_data as (
        select
            description,
            cat1,
            cat2,
            cat3,
            cat4,
            cat5,
            cat6,
            cat7,
            timestamp,
            realm_id,
            cat8,
            report_date,
            value,
            location,
            platform
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
                    ) as location,
                    '1-Tom-Plumber' as platform
                from {{ source("src_quickbooks", "balance_sheet") }}
                where location != 'TOTAL'
            )
        where location is not null
    ),
    ampg_data as (
        select
            description,
            cat1,
            cat2,
            cat3,
            cast(null as string) as cat4,
            cast(null as string) as cat5,
            cast(null as string) as cat6,
            cast(null as string) as cat7,
            timestamp,
            realm_id,
            cast(null as string) as cat8,
            date_trunc(parse_date('%m/%d/%Y', report_date), month) report_date,
            cast(replace(value, ',', '') as float64) as value,
            'All' as location,
            'AMPG' as platform
        from {{ source("google_sheets", "balance_sheet_ampg") }}
        where cat1 is not null
    )
select *
from quickbooks_data
union all
select *
from ampg_data
