--DROP FUNCTION gendoc.get_collect_info(aschema name, aoptions jsonb);

CREATE OR REPLACE FUNCTION gendoc.get_collect_info(aschema name, aoptions jsonb DEFAULT NULL::json)
 RETURNS TABLE(schema jsonb, version character varying, routines jsonb, tables jsonb, views jsonb)
 LANGUAGE plpgsql
AS $function$
/**
 * Collects complete information about objects and returns it in the form of a record
 *
 * @summary Collect info
 *
 * @param {name} aschema schema name
 * @param {jsonb} aoptions options to generate documentation
 * @returns {record} schema, version, routines, tables, views
 * 
 * @property {string[]} aoptions.objects objects that are to appear in the documentation (routines, tables, views)
 *
 * @author Andrzej Kałuża
 * @created 2025-01-26
 * @version 1.0
 * @since 2.0
 * 
 * @see get_routines
 * @see get_tables
 * @see get_views
 * @see get_schema
 */
declare
  l_o_objects text[] := (select array_agg(x::text) from jsonb_array_elements_text(aoptions -> 'objects') x);
  l_o_routines jsonb := aoptions -> 'routines';
  l_o_tables jsonb := aoptions -> 'tables';
  l_o_views jsonb := aoptions -> 'views';
begin
  version := gendoc.get_package_version(aschema);
  --
  if 'routines' = any (l_o_objects) or coalesce(array_length(l_o_objects, 1), 0) = 0 then
    routines := gendoc.get_routines(aschema, aoptions);
  end if;
  --
  if 'tables' = any (l_o_objects) or coalesce(array_length(l_o_objects, 1), 0) = 0 then
    tables := gendoc.get_tables(aschema, aoptions);
  end if;
  --
  if 'views' = any (l_o_objects) or coalesce(array_length(l_o_objects, 1), 0) = 0 then
    views := gendoc.get_views(aschema, aoptions);
  end if;
  --
  schema := gendoc.get_schema(aschema, aoptions);
  --
  return next;
end;
$function$;

ALTER FUNCTION gendoc.get_collect_info(aschema name, aoptions jsonb) OWNER TO gendoc;
COMMENT ON FUNCTION gendoc.get_collect_info(aschema name, aoptions jsonb) IS 'Collects complete information about objects and returns it in the form of a record';
