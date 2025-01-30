--DROP FUNCTION gendoc.html_tables(atables jsonb, alocation jsonb);

CREATE OR REPLACE FUNCTION gendoc.html_tables(atables jsonb, alocation jsonb)
 RETURNS text
 LANGUAGE plpgsql
 IMMUTABLE
AS $function$
/**
 * Create tables html section
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
  l_result := l_result || '<section id="tables"><h2>'||(alocation->>'tables')||'</h2>';
  l_result := l_result || (select string_agg(gendoc.html_table(t, alocation), '' order by t->>'table_name') from jsonb_array_elements(atables) t);
  l_result := l_result || '</section>';
  --
  return l_result;
end;
$function$;

ALTER FUNCTION gendoc.html_tables(atables jsonb, alocation jsonb) OWNER TO gendoc;
COMMENT ON FUNCTION gendoc.html_tables(atables jsonb, alocation jsonb) IS 'Create tables html section';
