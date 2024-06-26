with
    quickbooks_data as (
        select * except (location), replace(location, 'TOTAL', 'All') as location
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
                    # OR LOWER(location) = 'plumbing' OR LOWER(location) = 'not
                    # specified')
                    # AND LOWER(location) not like '%deleted%', 'Cincinnati',
                    # IF(LOWER(location) like '%dayton%' AND LOWER(location) not like
                    # '%deleted%', 'Dayton', NULL)) as location
                    if(
                        report_date < '2024-01-01',
                        if(
                            lower(location) like '%dayton%'
                            and lower(location) not like '%deleted%',
                            'Dayton',
                            if(
                                location != 'TOTAL',
                                'Cincinnati',
                                if(location = 'TOTAL', 'TOTAL', null)
                            )
                        ),
                        if(
                            location = 'Dayton'
                            or location = 'Kentucky'
                            or location = 'Cincinnati'
                            or location = 'TOTAL',
                            location,
                            null
                        )
                    ) as location,
                    '1-Tom-Plumber' as platform
                from {{ source("src_quickbooks", "profit_loss") }}
            # WHERE location != 'TOTAL' #and Description NOT IN ('400 Job Income')
            # where (LOWER(location) like '%cincinnati%' OR LOWER(location) like
            # '%dayton%') AND LOWER(location) not like '%deleted%'
            )
        where location is not null
    ),
    ampg_data as (
        select
            account_group,
            max(timestamp) as timestamp,
            realm_id,
            date_trunc(parse_date('%m/%d/%Y', report_date), month) as report_date,
            sum(cast(replace(value, ',', '') as float64)) as value,
            if(
                account_group = 'Total Income',
                'Income',
                if(
                    account_group = 'Total COGS',
                    'COGS',
                    if(
                        account_group in (
                            'Warehouse Expenses',
                            'Sales Expenses',
                            'Administration Expenses'
                        ),
                        'Expenses',
                        if(
                            account_group = 'Other Income/Expenses',
                            'Other Expenses',
                            if(
                                description in (
                                    'Wages - Direct',
                                    'Payroll Taxes',
                                    '401(K) Plan',
                                    'Wages Direct'
                                ),
                                'Cost of Labor',
                                'Not Classified'
                            )
                        )
                    )
                )
            ) as category,
            'AMPG' as platform,
            'All' as location
        from {{ source("google_sheets", "profit_loss_ampg") }}
        where
            account_group in (
                'Total Income',
                'Total COGS',
                'Operating Expenses',
                'Other Income/Expenses',
                'Warehouse Expenses',
                'Sales Expenses',
                'Administration Expenses'
            )
            or (
                trim(description)
                in ('Wages - Direct', 'Payroll Taxes', '401(K) Plan', 'Wages Direct')
                and trim(account_group) in ('Warehouse Expenses', 'Manufacturing')
            )
        group by 1, 3, 4, 6
    )
select *
from quickbooks_data
union all
select *
from ampg_data
