-- One row per calendar day
with days as (
    select unnest(generate_series(date '2016-01-01', date '2018-12-31', interval 1 day))::date as date_day
)

select
    date_day,
    year(date_day)                                   as year,
    quarter(date_day)                                as quarter,
    month(date_day)                                  as month,
    date_trunc('month', date_day)::date              as month_start,
    strftime(date_day, '%Y-%m')                      as year_month,
    dayname(date_day)                                as day_name,
    isodow(date_day)                                 as day_of_week,      -- 1 = Monday
    isodow(date_day) in (6, 7)                       as is_weekend,
    date_day between date '2017-01-01' and date '2018-08-31' as is_analysis_window
from days