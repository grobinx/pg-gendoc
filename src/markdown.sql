--DROP FUNCTION gendoc.markdown(aschema name, aoptions jsonb);

CREATE OR REPLACE FUNCTION gendoc.markdown(aschema name, aoptions jsonb DEFAULT NULL::jsonb)
 RETURNS text
 LANGUAGE plpgsql
AS $function$
/**
 * Creates markdown document with all objects information
 *
 * @summary generate md document
 *
 * @param {name} aschema schema name
 * @param {jsonb} aoptions generate settings
 * @returns {text}
 * 
 * @author Andrzej Kałuża
 * @created 2025-01-20
 * @version 1.0
 * @since 2.0
 */
declare
  l_r record;
  l_translation jsonb := gendoc.get_translation(aoptions->>'location');
  l_result varchar := '';
  l_version text := gendoc.get_package_version(aschema);
begin
  select * into l_r
    from gendoc.get_collect_info(aschema, aoptions);
  --
  l_result := l_result || 
    '# '||
      (l_translation->>'schema')||' "'||aschema||'"'||
      coalesce(' - '||(l_translation->>'version')||' '||l_version, '')||
      coalesce(' - '||(l_translation->>'package')||' '||(aoptions->>'package'), '')||
      coalesce(' - '||(l_translation->>'module')||' '||(aoptions->>'module'), '')||
      e'<small>&nbsp;\t'||to_char(now(), 'yyyy-mm-dd hh24:mi:ss')||'</small>';
  --
  l_result := l_result || gendoc.md_create_toc(l_r.routines, l_r.tables, l_r.views, l_translation);
  if jsonb_typeof(l_r.schema->'doc_data') != 'null' or jsonb_typeof(l_r.schema->'description') != 'null' then
    l_result := l_result || gendoc.md_schema(l_r.schema, l_translation);
  end if;
  if l_r.routines is not null then
    l_result := l_result || gendoc.md_routines(l_r.routines, l_translation);
  end if;
  if l_r.tables is not null then
    l_result := l_result || gendoc.md_tables(l_r.tables, l_translation);
  end if;
  if l_r.views is not null then
    l_result := l_result || gendoc.md_views(l_r.views, l_translation);
  end if;
  --raise debug '%', length(l_result);
  l_result := l_result || e'\n\n----\n<small>GENDOC '||gendoc.version()||' - Andrzej Kałuża</small>';
  --
  return l_result;
end;
$function$;

ALTER FUNCTION gendoc.markdown(aschema name, aoptions jsonb) OWNER TO gendoc;
COMMENT ON FUNCTION gendoc.markdown(aschema name, aoptions jsonb) IS '';
