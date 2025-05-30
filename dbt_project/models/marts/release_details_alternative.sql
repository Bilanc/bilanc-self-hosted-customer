WITH pull_requests AS (
    SELECT 
        id
        , title
        , user_id
        , repo
        , merged_at
        , base_ref
        , body
        , diff_url
        , branch_name
        , number
        , tenant
    FROM {{ ref('stg_github__pull_requests') }}
)
, release_dates AS (
    SELECT
        id                      AS release_id
        , repo
        , title                 AS version
        , merged_at::timestamp  AS release_date
        , body                  AS notes
        , user_id               AS author_id
        , tenant
        , LAG(merged_at::timestamp) OVER (PARTITION BY repo, tenant ORDER BY merged_at) AS previous_release_date
    FROM pull_requests
    WHERE
        base_ref IN ('main', 'master')
),
teams AS (
  SELECT
    merged_user_id
    , tenant       AS tenant
    , source_user_id
    , role
    , name
    , ARRAY_AGG(DISTINCT department) AS departments
    , ARRAY_AGG(DISTINCT team_name) AS team_names
    , ARRAY_AGG(DISTINCT team_id) AS team_ids

  FROM {{ ref('team_users') }}
  GROUP BY 1, 2, 3, 4, 5
)
, additions_and_deletions AS (
    SELECT
        id AS pr_id
        , SUM(additions) AS additions
        , SUM(deletions) AS deletions
    FROM {{ ref('stg_github__pull_request_details') }}
    GROUP BY 1
)
, release_prs AS (
    SELECT 
        r.release_id
        , r.version
        , r.release_date
        , r.notes
        , r.tenant
        , r.repo
        , pr.id
        , pr.title
        , pr.user_id AS pr_author_id
        , r.author_id
        , REPLACE(pr.diff_url, '.diff', '') as url
        , pr.branch_name
        , pr.number
        , prs.pr_ai_summary
        , ad.additions
        , ad.deletions
    FROM release_dates r
    LEFT JOIN pull_requests pr
        ON pr.repo = r.repo
        AND pr.merged_at::timestamp <= r.release_date
        AND (
            pr.merged_at::timestamp > r.previous_release_date
            OR r.previous_release_date IS NULL
        )
        AND pr.tenant = r.tenant
        AND pr.base_ref IN ('main', 'master')
    LEFT JOIN {{ ref('stg_public__ai_pull_request_summaries') }} prs
        ON pr.id = prs.pr_id
        AND prs.tenant = r.tenant
    LEFT JOIN additions_and_deletions ad
        ON pr.id::VARCHAR = ad.pr_id::VARCHAR
),
release_issues AS (
    SELECT 
        rp.release_id
        , i.issue_id
        , i.issue_title
        , i.state_name AS status
        , i.issue_url
        , i.tenant
        , i.creator_name
        , ts.summary
    FROM release_prs rp
    JOIN {{ ref('issues') }} i
        ON i.branch_name = rp.branch_name
        AND i.tenant = rp.tenant
    LEFT JOIN {{ ref('stg_public__ai_ticket_summaries') }} ts
        ON i.issue_id = ts.issue_id
        AND ts.tenant = rp.tenant
),
ai_summary AS (
    SELECT
        release_id
        , tenant
        , ai_release_summary

    FROM {{ ref("stg_public__ai_release_summary") }}
)
SELECT 
    r.release_id
    , r.version
    , r.release_date
    , r.notes
    , r.repo AS repository
    , r.author_id               AS author_source_user_id
    , tu.merged_user_id         AS merged_user_id
    , tu.name
    , tu.team_names
    , tu.team_ids
    , tu.role
    , tu.departments
    , r.tenant
    , ais.ai_release_summary
    , JSONB_AGG(
        DISTINCT JSONB_BUILD_OBJECT(
            'id', r.id
            , 'title', r.title
            , 'author', pr_tu.name
            , 'url', r.url
            , 'number', r.number
            , 'summary', r.pr_ai_summary
            , 'additions', r.additions
            , 'deletions', r.deletions
        )
    ) FILTER (WHERE r.id IS NOT NULL) AS pull_requests
    , JSONB_AGG(
        DISTINCT JSONB_BUILD_OBJECT(
            'id', ri.issue_id
            , 'title', ri.issue_title
            , 'status', ri.status
            , 'url', ri.issue_url
            , 'summary', ri.summary
            , 'name', ri.creator_name
        )
    ) FILTER (WHERE ri.issue_id IS NOT NULL) AS tickets
FROM release_prs r
LEFT JOIN release_issues ri 
    ON r.release_id = ri.release_id
    AND r.tenant = ri.tenant
LEFT JOIN teams pr_tu 
    ON r.pr_author_id = pr_tu.source_user_id
LEFT JOIN teams tu
    ON tu.source_user_id = r.author_id
    AND r.tenant = tu.tenant
LEFT JOIN ai_summary ais 
    ON ais.release_id = r.release_id
    AND ais.tenant = r.tenant
GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14