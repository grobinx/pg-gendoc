--DROP FUNCTION gendoc.wiki_series_toc(aitems jsonb, aname character varying);

CREATE OR REPLACE FUNCTION gendoc.wiki_series_toc(aitems jsonb, aname character varying)
 RETURNS text
 LANGUAGE plpgsql
 IMMUTABLE
AS $function$
/**
 * Create table of content from jsonb array as Wiki markup code
 *
 * Level 2
 * 
 * @param {jsonb} aitems array with elements
 * @param {varchar} aname item name to show
 * @returns {text}
 * 
 * @author Andrzej Kałuża
 * @created 2025-01-26
 * @version 1.0
 * @since 2.0
 */
begin
  return string_agg(
           '## [[#'||(j->>aname)||'|'||(j->>aname)||']]'||
           coalesce(' '||coalesce((j->'doc_data'->>'summary'), (j->>'description')), ''), 
         e'\n' order by j->>aname)
    from jsonb_array_elements(aitems) j;
end;
$function$;

ALTER FUNCTION gendoc.wiki_series_toc(aitems jsonb, aname character varying) OWNER TO gendoc;
COMMENT ON FUNCTION gendoc.wiki_series_toc(aitems jsonb, aname character varying) IS 'Create table of content from jsonb array as Wiki markup code';
