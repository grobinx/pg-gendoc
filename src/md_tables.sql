--DROP FUNCTION gendoc.md_tables(atables jsonb, alocation jsonb);

CREATE OR REPLACE FUNCTION gendoc.md_tables(atables jsonb, alocation jsonb)
 RETURNS text
 LANGUAGE plpgsql
 IMMUTABLE
AS $function$
/**
 * Create tables markdown section
 *
 * @param {jsonb} atables tables series
 * @param {jsonb} alocation tarnslation strings
 * @returns {text}
 * 
 * @author Andrzej Kałuża
 * @created 2025-01-26
 * @version 1.0
 * @since 2.0
 */
declare
  l_result text := '';
begin
  l_result := l_result || e'\n\n## '||(alocation->>'tables');
  l_result := l_result || (select string_agg(gendoc.md_table(t, alocation), e'\n\n---' order by t->>'table_name') from jsonb_array_elements(atables) t);
  --
  return l_result;
end;
$function$;

ALTER FUNCTION gendoc.md_tables(atables jsonb, alocation jsonb) OWNER TO gendoc;
COMMENT ON FUNCTION gendoc.md_tables(atables jsonb, alocation jsonb) IS '';
