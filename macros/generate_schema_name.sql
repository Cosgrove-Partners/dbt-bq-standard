{% macro generate_schema_name(custom_schema_name, node) %}
    {% if target.name == "dev" %} np_{{ custom_schema_name }}
    {% else %} {{ custom_schema_name }}
    {% endif %}
{% endmacro %}
