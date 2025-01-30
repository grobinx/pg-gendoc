--DROP FUNCTION gendoc.md_routines(aroutines jsonb, alocation jsonb);

CREATE OR REPLACE FUNCTION gendoc.md_routines(aroutines jsonb, alocation jsonb)
 RETURNS text
 LANGUAGE plpgsql
 IMMUTABLE
AS $function$
/**
 * Create routines markdown section
 *
 * @param {jsonb} aroutines routine series
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
  l_result := l_result || e'\n\n## '||(alocation->>'routines');
  l_result := l_result || (select string_agg(gendoc.md_routine(t, alocation), e'\n\n---' order by t->>'routine_name') from jsonb_array_elements(aroutines) t);
  --
  return l_result;
end;
$function$;

ALTER FUNCTION gendoc.md_routines(aroutines jsonb, alocation jsonb) OWNER TO gendoc;
COMMENT ON FUNCTION gendoc.md_routines(aroutines jsonb, alocation jsonb) IS '';
