--DROP FUNCTION gendoc.html(aschema name, aoptions jsonb);

CREATE OR REPLACE FUNCTION gendoc.html(aschema name, aoptions jsonb DEFAULT NULL::jsonb)
 RETURNS text
 LANGUAGE plpgsql
AS $function$
/**
 * Creates html document with all objects information
 *
 * @summary generate html document
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
  l_result text := '';
  l_version text := gendoc.get_package_version(aschema);
begin
  select * into l_r
    from gendoc.get_collect_info(aschema, aoptions);
  --
  l_result := l_result || '<html>';
  l_result := l_result || '<head>';
  l_result := l_result || '<link media="all" rel="stylesheet" href="'||aschema||'.css" />';
  l_result := l_result || '</head>';
  --
  l_result := l_result || '<body>';
  l_result := l_result || '<section>';
  l_result := l_result || 
    '<span>'||to_char(now(), 'yyyy-mm-dd hh24:mi:ss')||'</span>'||
    '<h1>'||
      (l_translation->>'schema')||' "'||aschema||'"'||
      coalesce(' - '||(l_translation->>'version')||' '||l_version, '')||
      coalesce(' - '||(l_translation->>'package')||' '||(aoptions->>'package'), '')||
      coalesce(' - '||(l_translation->>'module')||' '||(aoptions->>'module'), '')||
    '</h1>';
  l_result := l_result || gendoc.html_create_toc(l_r.routines, l_r.tables, l_r.views, l_translation);
  if jsonb_typeof(l_r.schema->'doc_data') != 'null' or jsonb_typeof(l_r.schema->'description') != 'null' then
    l_result := l_result || gendoc.html_schema(l_r.schema, l_translation);
  end if;
  if l_r.routines is not null then
    l_result := l_result || gendoc.html_routines(l_r.routines, l_translation);
  end if;
  if l_r.tables is not null then
    l_result := l_result || gendoc.html_tables(l_r.tables, l_translation);
  end if;
  if l_r.views is not null then
    l_result := l_result || gendoc.html_views(l_r.views, l_translation);
  end if;
  l_result := l_result || '</section>';
  l_result := l_result || '<small>GENDOC '||gendoc.version()||' - Andrzej Kałuża</small>';
  l_result := l_result || '</body>';
  --
  l_result := l_result || '</html>';
  return l_result;
end;
$function$;

ALTER FUNCTION gendoc.html(aschema name, aoptions jsonb) OWNER TO gendoc;
COMMENT ON FUNCTION gendoc.html(aschema name, aoptions jsonb) IS '';
