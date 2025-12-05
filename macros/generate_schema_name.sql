{% macro generate_schema_name(custom_schema_name, node) -%}

    {%- set default_schema = target.schema -%}
    
    {#- 
        Environment Logic:
        1. Production: Use the target schema (db_analytics_prod) combined with custom schema.
        2. CI: Use a PR-specific schema.
        3. Dev: Use the user's development schema.
    -#}

    {%- if target.name == 'prod' -%}

        {%- if custom_schema_name is none -%}
            {{ default_schema }}
        {%- else -%}
            {{ default_schema }}_{{ custom_schema_name | trim }}
        {%- endif -%}

    {%- elif target.name == 'ci' -%}

        {#- CI Schema Logic: db_ci_pr_<id> -#}
        {%- set pr_id = env_var('DBT_CLOUD_PR_ID', 'manual') -%}
        {%- set ci_schema_prefix = 'db_ci_pr_' ~ pr_id -%}

        {%- if custom_schema_name is none -%}
            {{ ci_schema_prefix }}
        {%- else -%}
            {{ ci_schema_prefix }}_{{ custom_schema_name | trim }}
        {%- endif -%}

    {%- else -%}

        {#- Development (default) -#}
        {%- if custom_schema_name is none -%}
            {{ default_schema }}
        {%- else -%}
            {{ default_schema }}_{{ custom_schema_name | trim }}
        {%- endif -%}

    {%- endif -%}

{%- endmacro %}

