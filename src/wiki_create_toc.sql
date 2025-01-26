--DROP FUNCTION gendoc.wiki_create_toc(aroutines jsonb, atables jsonb, aviews jsonb, alocation jsonb);

CREATE OR REPLACE FUNCTION gendoc.wiki_create_toc(aroutines jsonb, atables jsonb, aviews jsonb, alocation jsonb)
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
  if aroutines is not null then
    l_result := l_result || '# [[#routines|'||(alocation->>'routines')||e']]\n';
    l_result := l_result || gendoc.wiki_series_toc(aroutines, 'routine_name')||e'\n';
  end if;
  if atables is not null then
    l_result := l_result || '# [[#tables|'||(alocation->>'tables')||e']]\n';
    l_result := l_result || gendoc.wiki_series_toc(atables, 'table_name')||e'\n';
  end if;
  if aviews is not null then
    l_result := l_result || '# [[#views|'||(alocation->>'views')||e']]\n';
    l_result := l_result || gendoc.wiki_series_toc(aviews, 'view_name')||e'\n';
  end if;
  --
  return l_result;
end;
$function$;

ALTER FUNCTION gendoc.wiki_create_toc(aroutines jsonb, atables jsonb, aviews jsonb, alocation jsonb) OWNER TO gendoc;
COMMENT ON FUNCTION gendoc.wiki_create_toc(aroutines jsonb, atables jsonb, aviews jsonb, alocation jsonb) IS 'Create table of content for all series';
