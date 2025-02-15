--DROP FUNCTION gendoc.md_create_toc(aroutines jsonb, atables jsonb, aviews jsonb, alocation jsonb);

CREATE OR REPLACE FUNCTION gendoc.md_create_toc(aroutines jsonb, atables jsonb, aviews jsonb, alocation jsonb)
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
  l_result := l_result || e'\n\n## '||(alocation->>'toc')||e'\n\n';
  if aroutines is not null then
    l_result := l_result || '1. ['||(alocation->>'routines')||'](#'||replace(alocation->>'routines', ' ', '-')||')'||e'\n';
    l_result := l_result || gendoc.md_series_toc(aroutines, 'routine_name')||e'\n';
  end if;
  if atables is not null then
    l_result := l_result || '2. ['||(alocation->>'tables')||'](#'||(alocation->>'tables')||')'||e'\n';
    l_result := l_result || gendoc.md_series_toc(atables, 'table_name')||e'\n';
  end if;
  if aviews is not null then
    l_result := l_result || '3. ['||(alocation->>'views')||'](#'||(alocation->>'views')||')'||e'\n';
    l_result := l_result || gendoc.md_series_toc(aviews, 'view_name')||e'\n';
  end if;
  --
  return l_result;
end;
$function$;

ALTER FUNCTION gendoc.md_create_toc(aroutines jsonb, atables jsonb, aviews jsonb, alocation jsonb) OWNER TO gendoc;
COMMENT ON FUNCTION gendoc.md_create_toc(aroutines jsonb, atables jsonb, aviews jsonb, alocation jsonb) IS 'Create table of content for all series';
