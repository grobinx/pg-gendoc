--DROP FUNCTION gendoc.html_doc_data_param(adoc_data jsonb, aarguments jsonb, alocation jsonb);

CREATE OR REPLACE FUNCTION gendoc.html_doc_data_param(adoc_data jsonb, aarguments jsonb, alocation jsonb)
 RETURNS text
 LANGUAGE plpgsql
 IMMUTABLE
AS $function$
/**
 * Creates a collection of information from doc_data about arguments
 *
 * @summary create information about arguments
 *
 * @param {jsonb} adoc_data doc data
 * @param {jsonb} aarguments routine arguments
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
  if adoc_data->'param' is not null or jsonb_array_length(aarguments) > 0 then    
    l_result := l_result || '<h4>'||(alocation->>'arguments')||'</h4>';
    l_result := l_result || '<table>';
    l_result := l_result || '<thead>';
    l_result := l_result || 
      '<tr><th>'||(alocation->>'argument_no_th')||'</th><th>'||(alocation->>'argument_name_th')||'</th>'||
      '<th>'||(alocation->>'data_type_th')||'</th>'||'<th>'||(alocation->>'default_value_th')||'</th>'||
      '<th>'||(alocation->>'mode_th')||'</th><th>'||(alocation->>'description_th')||'</th>'||
      '</tr>';
    l_result := l_result || '</thead>';
    --
    l_result := l_result || '<tbody>';
    l_result := l_result ||
      string_agg(
         '<tr><td>'||coalesce(ra->>'argument_no', '')||'</td><td>'||coalesce(ra->>'argument_name', rp->>'name')||'</td>'||
         '<td>'||coalesce(ra->>'data_type', rp->>'type')||'</td><td>'||coalesce(ra->>'default_value', rp->>'default', '')||'</td>'||
         '<td>'||coalesce(ra->>'mode', '')||'</td><td>'||coalesce(rp->>'description', '')||'</td></tr>',
       '' order by (ra->>'argument_no')::numeric, coalesce(ra->>'argument_name', rp->>'name'))
      from jsonb_array_elements(aarguments) ra 
           full join jsonb_array_elements(adoc_data->'param') rp on rp->>'name' = ra->>'argument_name';
    l_result := l_result || '</tbody>';
    --
    l_result := l_result || '</table>';
  end if;
  --
  return l_result;
end;
$function$;

ALTER FUNCTION gendoc.html_doc_data_param(adoc_data jsonb, aarguments jsonb, alocation jsonb) OWNER TO gendoc;
COMMENT ON FUNCTION gendoc.html_doc_data_param(adoc_data jsonb, aarguments jsonb, alocation jsonb) IS '';
