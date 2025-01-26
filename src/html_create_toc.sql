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
 * @param {jsonb} aroutines routines series
 * @param {jsonb} atables tables series
 * @param {jsonb} aviews views series
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
  l_result := l_result || '<ol>';
  if aroutines is not null then
    l_result := l_result || '<li><a href="#routines" />'||(alocation->>'routines');
    l_result := l_result || gendoc.html_series_toc(aroutines, 'routine_name');
    l_result := l_result || '</li>';
  end if;
  if atables is not null then
    l_result := l_result || '<li><a href="#tables" />'||(alocation->>'tables');
    l_result := l_result || gendoc.html_series_toc(atables, 'table_name');
    l_result := l_result || '</li>';
  end if;
  if aviews is not null then
    l_result := l_result || '<li><a href="#views" />'||(alocation->>'views');
    l_result := l_result || gendoc.html_series_toc(aviews, 'view_name');
    l_result := l_result || '</li>';
  end if;
  l_result := l_result || '</ol>';
  --
  return l_result;
end;
$function$;

ALTER FUNCTION gendoc.html_create_toc(aroutines jsonb, atables jsonb, aviews jsonb, alocation jsonb) OWNER TO gendoc;
COMMENT ON FUNCTION gendoc.html_create_toc(aroutines jsonb, atables jsonb, aviews jsonb, alocation jsonb) IS 'Create table of content for all series';
