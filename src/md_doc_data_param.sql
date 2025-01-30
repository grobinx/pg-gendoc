--DROP FUNCTION gendoc.md_doc_data_param(adoc_data jsonb, aarguments jsonb, alocation jsonb);

CREATE OR REPLACE FUNCTION gendoc.md_doc_data_param(adoc_data jsonb, aarguments jsonb, alocation jsonb)
 RETURNS text
 LANGUAGE plpgsql
 IMMUTABLE
AS $function$
/**
 * Creates a collection of information from doc_data about parameters
 *
 * @param {jsonb} adoc_data doc data
 * @param {jsonb} aarguments routine arguments
 * @param {jsonb} alocation tarnslation strings
 * @returns {text}
 * 
 * @author Andrzej Kałuża
 * @created 2025-01-29
 * @version 1.0
 * @since 2.0
 */
declare
  l_result text := '';
begin
  if adoc_data->'param' is not null or jsonb_array_length(aarguments) > 0 then    
    l_result := l_result || e'\n\n#### '||(alocation->>'arguments');
    l_result := l_result || e'\n\n'
      '|'||(alocation->>'argument_no_th')||'|'||(alocation->>'argument_name_th')||
      '|'||(alocation->>'data_type_th')||'|'||(alocation->>'default_value_th')||
      '|'||(alocation->>'mode_th')||'|'||(alocation->>'description_th')||'|'||
      e'\n|---:|----|----|----|----|----|';
    --
    l_result := l_result ||
      string_agg(e'\n'
         '|'||coalesce(ra->>'argument_no', '')||'|'||coalesce(ra->>'argument_name', rp->>'name')||
         '|'||coalesce(ra->>'data_type', rp->>'type')||'|'||coalesce(ra->>'default_value', rp->>'default', '')||
         '|'||coalesce(ra->>'mode', '')||'|'||coalesce(rp->>'description', '')||'|',
       '' order by (ra->>'argument_no')::numeric, coalesce(ra->>'argument_name', rp->>'name'))
      from jsonb_array_elements(aarguments) ra 
           full join jsonb_array_elements(adoc_data->'param') rp on rp->>'name' = ra->>'argument_name';
  end if;
  --
  return l_result;
end;
$function$;

ALTER FUNCTION gendoc.md_doc_data_param(adoc_data jsonb, aarguments jsonb, alocation jsonb) OWNER TO gendoc;
COMMENT ON FUNCTION gendoc.md_doc_data_param(adoc_data jsonb, aarguments jsonb, alocation jsonb) IS '';
