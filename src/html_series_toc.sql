--DROP FUNCTION gendoc.html_series_toc(aitems jsonb, aname character varying);

CREATE OR REPLACE FUNCTION gendoc.html_series_toc(aitems jsonb, aname character varying)
 RETURNS text
 LANGUAGE plpgsql
 IMMUTABLE
AS $function$
/**
 * Create table of content from jsonb array as HTML code
 *
 * Level 2
 *
 * @summary toc level 2
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
  return '<ol>'||string_agg(
           '<li><a href="#'||(j->>aname)||'"><code>'||(j->>aname)||'</code></a>'||
           coalesce('<span>'||coalesce((j->'doc_data'->>'summary'), (j->'doc_data'->>'root'), (j->>'description'))||'</span>', '')||'</li>', 
         '' order by j->>aname)||'</ol>'
    from jsonb_array_elements(aitems) j;
end;
$function$;

ALTER FUNCTION gendoc.html_series_toc(aitems jsonb, aname character varying) OWNER TO gendoc;
COMMENT ON FUNCTION gendoc.html_series_toc(aitems jsonb, aname character varying) IS 'Create table of content from jsonb array as HTML code';
