--DROP FUNCTION gendoc.html_routines(aroutines jsonb, alocation jsonb);

CREATE OR REPLACE FUNCTION gendoc.html_routines(aroutines jsonb, alocation jsonb)
 RETURNS text
 LANGUAGE plpgsql
 IMMUTABLE
AS $function$
/**
 * Create routines html section
 *
 * @param {jsonb} aroutines routine series
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
  l_result := l_result || '<section id="routines"><h2>'||(alocation->>'routines')||'</h2>';
  l_result := l_result || (select string_agg(gendoc.html_routine(t, alocation), '' order by t->>'routine_name') from jsonb_array_elements(aroutines) t);
  l_result := l_result || '</section>';
  --
  return l_result;
end;
$function$;

ALTER FUNCTION gendoc.html_routines(aroutines jsonb, alocation jsonb) OWNER TO gendoc;
COMMENT ON FUNCTION gendoc.html_routines(aroutines jsonb, alocation jsonb) IS '';
