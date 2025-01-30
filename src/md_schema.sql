--DROP FUNCTION gendoc.md_schema(aschema jsonb, alocation jsonb);

CREATE OR REPLACE FUNCTION gendoc.md_schema(aschema jsonb, alocation jsonb)
 RETURNS text
 LANGUAGE plpgsql
 IMMUTABLE
AS $function$
/**
 * Create schema markdown section
 *
 * @param {jsonb} atable tabl
 * @param {jsonb} alocation tarnslation strings
 * @returns {text}
 * 
 * @author Andrzej Kałuża
 * @created 2025-01-30
 * @version 1.0
 * @since 2.0
 */
declare
  l_result text := '';
  l_authors text := '';
  l_doc_data jsonb := aschema->'doc_data';
begin
  l_result := l_result || e'\n\n## '||(alocation->>'schema');
  --
  if l_doc_data->>'root' is not null then
    l_result := l_result || (l_doc_data->>'root');
  elsif aschema->>'description' is not null then
    l_result := l_result || (aschema->>'description');
  end if;
  --
  --raise debug '% %', (aroutine->>'routine_name'), length(l_result);
  l_result := l_result || gendoc.md_doc_data_prop(l_doc_data, alocation);
  l_result := l_result || gendoc.md_doc_data_uni(l_doc_data, alocation);
  --
  return l_result;
end;
$function$;

ALTER FUNCTION gendoc.md_schema(aschema jsonb, alocation jsonb) OWNER TO gendoc;
COMMENT ON FUNCTION gendoc.md_schema(aschema jsonb, alocation jsonb) IS '';
