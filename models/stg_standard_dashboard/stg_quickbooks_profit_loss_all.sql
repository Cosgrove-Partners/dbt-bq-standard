{{
    config(
        materialized="table",
        alias="quickbooks_profit_loss_all",
        schema="stg_standard_dashboard",
    )
}}

select *
from
    (
        select
            * except (location, report_date, value),
            cast(report_date as date) report_date,
            cast(value as float64) value,
            if(
                description like '4%',
                'Income',
                if(
                    description like '5%',
                    'COGS',
                    if(
                        description like '6%'
                        and description not like '604%'
                        and description not like '605%',
                        'Expenses',
                        if(
                            description like '604%'
                            or description like '605%'
                            or description like '7%',
                            'Other Expenses',
                            'Not Classified'
                        )
                    )
                )
            ) as category,
            # IF((LOWER(location) like '%cincinnati%'
            # OR LOWER(location) = 'plumbing' OR LOWER(location) = 'not specified')
            # AND LOWER(location) not like '%deleted%', 'Cincinnati',
            # IF(LOWER(location) like '%dayton%' AND LOWER(location) not like
            # '%deleted%', 'Dayton', NULL)) as location
            if(
                lower(location) like '%dayton%'
                and lower(location) not like '%deleted%',
                'Dayton',
                'Cincinnati'
            ) as location
        from {{ source("src_quickbooks", "profit_loss") }}
        where location != 'TOTAL'  # and Description NOT IN ('400 Job Income')
    # where (LOWER(location) like '%cincinnati%' OR LOWER(location) like '%dayton%')
    # AND LOWER(location) not like '%deleted%'
    )
where location is not null
