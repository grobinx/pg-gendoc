--DROP FUNCTION gendoc.html_create_toc(aroutines jsonb, atables jsonb, aviews jsonb, alocation jsonb);

CREATE OR REPLACE FUNCTION gendoc.html_create_toc(aroutines jsonb, atables jsonb, aviews jsonb, alocation jsonb)
 RETURNS text
 LANGUAGE plpgsql
 IMMUTABLE
AS $function$
/**
 * Create table of content for all series
 *
 * Level 1
 *
 * @summary toc for all objects
 * 
 * @param {jsonb} aroutines routines series
 * @param {jsonb} atables tables series
 * @param {jsonb} aviews views series
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
  l_result := l_result || '<section id="toc"><h2>'||(alocation->>'toc')||'</h2>';
  l_result := l_result || '<ol>';
  if aroutines is not null then
    l_result := l_result || '<li><a href="#routines" />'||(alocation->>'routines')||'</a>';
    l_result := l_result || gendoc.html_series_toc(aroutines, 'routine_name');
    l_result := l_result || '</li>';
  end if;
  if atables is not null then
    l_result := l_result || '<li><a href="#tables" />'||(alocation->>'tables')||'</a>';
    l_result := l_result || gendoc.html_series_toc(atables, 'table_name');
    l_result := l_result || '</li>';
  end if;
  if aviews is not null then
    l_result := l_result || '<li><a href="#views" />'||(alocation->>'views')||'</a>';
    l_result := l_result || gendoc.html_series_toc(aviews, 'view_name');
    l_result := l_result || '</li>';
  end if;
  l_result := l_result || '</ol>';
  l_result := l_result || '</section>';
  --
  return l_result;
end;
$function$;

ALTER FUNCTION gendoc.html_create_toc(aroutines jsonb, atables jsonb, aviews jsonb, alocation jsonb) OWNER TO gendoc;
COMMENT ON FUNCTION gendoc.html_create_toc(aroutines jsonb, atables jsonb, aviews jsonb, alocation jsonb) IS '';
