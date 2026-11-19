-- Fail if the CDO UNION ALL view drops, duplicates, or changes source-team
-- position rows or their approved financial totals. This checks POC data
-- consistency, not cross-currency or snapshot aggregation correctness.
with expected as (
    select
        'TEAM_A'::text as source_team,
        count(*)::bigint as row_count,
        coalesce(sum(profit_loss), 0)::numeric as pnl,
        coalesce(sum(mtm), 0)::numeric as mtm,
        coalesce(sum(cash), 0)::numeric as cash,
        0::numeric as settled_cash
    from {{ ref('stg_team_a_positions') }}
    union all
    select
        'TEAM_C'::text as source_team,
        count(*)::bigint as row_count,
        coalesce(sum(profit_loss), 0)::numeric as pnl,
        0::numeric as mtm,
        0::numeric as cash,
        coalesce(sum(settled_cash), 0)::numeric as settled_cash
    from {{ ref('stg_team_c_positions') }}
),
actual as (
    select
        source_team,
        count(*)::bigint as row_count,
        coalesce(sum(profit_loss), 0)::numeric as pnl,
        coalesce(sum(mtm), 0)::numeric as mtm,
        coalesce(sum(cash), 0)::numeric as cash,
        coalesce(sum(settled_cash), 0)::numeric as settled_cash
    from {{ ref('cdo_enterprise_positions') }}
    group by source_team
)
select
    coalesce(e.source_team, a.source_team) as source_team,
    e.row_count as expected_rows,
    a.row_count as actual_rows,
    e.pnl as expected_pnl,
    a.pnl as actual_pnl
from expected e
full outer join actual a on e.source_team = a.source_team
where e.source_team is null
   or a.source_team is null
   or e.row_count is distinct from a.row_count
   or e.pnl is distinct from a.pnl
   or e.mtm is distinct from a.mtm
   or e.cash is distinct from a.cash
   or e.settled_cash is distinct from a.settled_cash
