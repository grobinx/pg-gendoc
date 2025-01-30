--DROP FUNCTION gendoc.html_views(aviews jsonb, alocation jsonb);

CREATE OR REPLACE FUNCTION gendoc.html_views(aviews jsonb, alocation jsonb)
 RETURNS text
 LANGUAGE plpgsql
 IMMUTABLE
AS $function$
/**
 * Create views html section
 *
 * @param {jsonb} atables views series
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
  l_result := l_result || '<section id="views"><h2>'||(alocation->>'views')||'</h2>';
  l_result := l_result || (select string_agg(gendoc.html_view(t, alocation), '' order by t->>'view_name') from jsonb_array_elements(aviews) t);
  l_result := l_result || '</section>';
  --
  return l_result;
end;
$function$;

ALTER FUNCTION gendoc.html_views(aviews jsonb, alocation jsonb) OWNER TO gendoc;
COMMENT ON FUNCTION gendoc.html_views(aviews jsonb, alocation jsonb) IS '';
