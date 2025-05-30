python dbt_project/scripts/update_tenant_seats.py
./dbt/bin/dbt build --model merged_users github_teams --profiles-dir dbt_project/profiles --project-dir dbt_project
./dbt/bin/dbt run-operation merge_users --profiles-dir dbt_project/profiles --project-dir dbt_project
./dbt/bin/dbt run-operation onboard_users  --profiles-dir dbt_project/profiles --project-dir dbt_project
./dbt/bin/dbt build --profiles-dir dbt_project/profiles --project-dir dbt_project --exclude stg_github__releases+ dim_dates