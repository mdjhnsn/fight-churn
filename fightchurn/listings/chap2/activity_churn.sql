set start_date = '2022-01-01';
set end_date = '2022-02-01';
set inactivity_interval = '30';
with date_range as (
    select to_date(getvariable('start_date'))::DATE           as start_date,
           to_date(getvariable('end_date'))::DATE             as end_date,
           to_number(getvariable('inactivity_interval'))::INT as inactivity_interval
),
     start_accounts as
         (
             select distinct client_sid
             from client_event_fact_ext e
                      inner join date_range d
                                 on e.event_occurred_utc > dateadd(days, -inactivity_interval, start_date)
                                     and e.event_occurred_utc <= start_date
         ),
     start_count as (
         select count(*) as n_start
         from start_accounts
     ),
     end_accounts as
         (
             select distinct client_sid
             from client_event_fact_ext e
                      inner join date_range d
                                 on e.event_occurred_utc > dateadd(days, -inactivity_interval, end_date)
                                     and e.event_occurred_utc <= end_date
         ),
     end_count as (
         select count(*) as n_end
         from end_accounts
     ),
     churned_accounts as
         (
             select distinct s.client_sid
             from start_accounts s
                      left outer join end_accounts e on
                 s.client_sid = e.client_sid
             where e.client_sid is null
         ),
     churn_count as (
         select count(*) as n_churn
         from churned_accounts
     )
select
--        n_churn::float / n_start::float       as churn_rate,
--        1.0 - n_churn::float / n_start::float as retention_rate,
n_start,
n_churn
from start_count,
     end_count,
     churn_count
