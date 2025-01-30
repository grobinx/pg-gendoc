--DROP FUNCTION gendoc.md_doc_data_prop(adoc_data jsonb, alocation jsonb);

CREATE OR REPLACE FUNCTION gendoc.md_doc_data_prop(adoc_data jsonb, alocation jsonb)
 RETURNS text
 LANGUAGE plpgsql
 IMMUTABLE
AS $function$
/**
 * Creates a collection of information from doc_data about properties
 *
 * @param {jsonb} adoc_data tabl
 * @param {jsonb} alocation tarnslation strings
 * @returns {text}
 * 
 * @author Andrzej Kałuża
 * @created 2025-01-28
 * @version 1.0
 * @since 2.0
 */
declare
  l_result text := '';
begin
  if adoc_data->'property' is not null then
    l_result := l_result || e'\n\n#### '||(alocation->>'propeties');
    l_result := l_result || e'\n\n'
      '|'||(alocation->>'name_th')||'|'||(alocation->>'data_type_th')||
      '|'||(alocation->>'default_value_th')||'|'||(alocation->>'description_th')||'|'||
      e'\n|----|----|----|----|';
    --
    l_result := l_result || 
      string_agg(e'\n'||
        '|'||coalesce(v->>'name', '')||'|'||coalesce(v->>'type', '')||
        '|'||coalesce(v->>'default', '')||'|'||coalesce(v->>'description', '')||'|',
      '')
      from jsonb_array_elements(adoc_data->'property') v;
  end if;
  --
  return l_result;
end;
$function$;

ALTER FUNCTION gendoc.md_doc_data_prop(adoc_data jsonb, alocation jsonb) OWNER TO gendoc;
COMMENT ON FUNCTION gendoc.md_doc_data_prop(adoc_data jsonb, alocation jsonb) IS '';
