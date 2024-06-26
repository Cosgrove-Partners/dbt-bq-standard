with
    clean_data as (
        select
            first_name,
            last_name,
            gender,
            city,
            status,
            title,
            department,
            branch,
            fte,
            if(
                birthdate = 'Unknown', null, parse_date('%m/%d/%Y', birthdate)
            ) as birthdate,
            if(
                start_date = 'Unknown', null, parse_date('%m/%d/%Y', start_date)
            ) as start_date,
            if(
                end_date = 'Unknown' or end_date = 'N/A',
                null,
                parse_date('%m/%d/%Y', replace(end_date, '//', '/1/'))
            ) as end_date,
            tenant,
            platform
        from
            (
                select
                    first_name,
                    last_name,
                    gender,
                    city,
                    status,
                    title,
                    department,
                    branch,
                    fte,
                    birthdate,
                    start_date,
                    end_date,
                    '1-Tom-Plumber' as tenant,
                    '1-Tom-Plumber' as platform
                from {{ source("google_sheets", "census_data_1tomplumber") }}
                union all
                select
                    first_name,
                    last_name,
                    gender,
                    city,
                    status,
                    title,
                    department,
                    branch,
                    fte,
                    birthdate,
                    start_date,
                    end_date,
                    'Revive' as tenant,
                    'Revive' as platform
                from {{ source("google_sheets", "census_data_revive") }}
                union all
                select
                    first_name,
                    last_name,
                    gender,
                    city,
                    status,
                    title,
                    department,
                    null as branch,
                    fte,
                    birthdate,
                    start_date,
                    end_date,
                    'AMPG' as tenant,
                    'AMPG' as platform
                from {{ source("google_sheets", "census_data_ampg") }}
            )
        where first_name is not null
    ),
    generated_dates as (
        select report_month
        from
            unnest(
                generate_date_array(
                    (select date_trunc(min(start_date), month) from clean_data),
                    current_date(),
                    interval 1 month
                )
            ) as report_month
    ),
    transformed_data as (
        select
            *,
            date_trunc(start_date, month) as start_month,
            date_trunc(end_date, month) as end_month,
            date_diff(current_date(), birthdate, year) as age
        from clean_data
    ),
    prepared_data as (
        select t2.report_month, t1.*
        from transformed_data t1
        cross join generated_dates t2
        where
            (t1.start_month < report_month)
            and (
                t1.end_month >= report_month
                or (status != 'Terminated' and end_month is null)
            )
    )
select * except (branch), 'All' as location
from prepared_data
union all
select * except (branch), branch as location
from prepared_data
