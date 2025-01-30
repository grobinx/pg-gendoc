--DROP FUNCTION gendoc.html_doc_data_prop(adoc_data jsonb, alocation jsonb);

CREATE OR REPLACE FUNCTION gendoc.html_doc_data_prop(adoc_data jsonb, alocation jsonb)
 RETURNS text
 LANGUAGE plpgsql
 IMMUTABLE
AS $function$
/**
 * Creates a collection of information from doc_data about properties
 *
 * @summary create information about properties
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
    l_result := l_result || '<h4>'||(alocation->>'propeties')||'</h4>';
    l_result := l_result || '<table>';
    l_result := l_result || '<thead>';
    l_result := l_result || 
      '<tr><th>'||(alocation->>'name_th')||'</th><th>'||(alocation->>'data_type_th')||'</th>'||
      '<th>'||(alocation->>'default_value_th')||'</th><th>'||(alocation->>'description_th')||'</th>'||
      '</tr>';
    l_result := l_result || '</thead>';
    --
    l_result := l_result || '<tbody>';
    l_result := l_result || 
      string_agg(
        '<tr><td>'||coalesce(v->>'name', '')||'</td><td>'||coalesce(v->>'type', '')||'</td>'||
        '<td>'||coalesce(v->>'default', '')||'</td><td>'||coalesce(v->>'description', '')||'</td></tr>',
      '')
      from jsonb_array_elements(adoc_data->'property') v;
    l_result := l_result || '</tbody>';
    --
    l_result := l_result || '</table>';
  end if;
  --
  return l_result;
end;
$function$;

ALTER FUNCTION gendoc.html_doc_data_prop(adoc_data jsonb, alocation jsonb) OWNER TO gendoc;
COMMENT ON FUNCTION gendoc.html_doc_data_prop(adoc_data jsonb, alocation jsonb) IS '';
