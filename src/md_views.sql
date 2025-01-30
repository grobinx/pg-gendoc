--DROP FUNCTION gendoc.md_views(aviews jsonb, alocation jsonb);

CREATE OR REPLACE FUNCTION gendoc.md_views(aviews jsonb, alocation jsonb)
 RETURNS text
 LANGUAGE plpgsql
 IMMUTABLE
AS $function$
/**
 * Create views markdown section
 *
 * @param {jsonb} aviews views series
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
  l_result := l_result || e'\n\n## '||(alocation->>'views');
  l_result := l_result || (select string_agg(gendoc.md_view(t, alocation), e'\n\n---' order by t->>'view_name') from jsonb_array_elements(aviews) t);
  --
  return l_result;
end;
$function$;

ALTER FUNCTION gendoc.md_views(aviews jsonb, alocation jsonb) OWNER TO gendoc;
COMMENT ON FUNCTION gendoc.md_views(aviews jsonb, alocation jsonb) IS '';
