--DROP FUNCTION gendoc.md_series_toc(aitems jsonb, aname character varying);

CREATE OR REPLACE FUNCTION gendoc.md_series_toc(aitems jsonb, aname character varying)
 RETURNS text
 LANGUAGE plpgsql
 IMMUTABLE
AS $function$
/**
 * Create table of content from jsonb array as MarkDown code
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
  return string_agg(line, e'\n')
    from (select '    '||(row_number() over (order by j->>aname))||'. [`'||(j->>aname)||'`](#'||(j->>aname)||')'||
                 coalesce(' '||trim(coalesce((j->'doc_data'->>'summary'), (j->'doc_data'->>'root'), (j->>'description'))), '') line
            from jsonb_array_elements(aitems) j
           order by j->>aname) l;
end;
$function$;

ALTER FUNCTION gendoc.md_series_toc(aitems jsonb, aname character varying) OWNER TO gendoc;
COMMENT ON FUNCTION gendoc.md_series_toc(aitems jsonb, aname character varying) IS 'Create table of content from jsonb array as MarkDown code';
