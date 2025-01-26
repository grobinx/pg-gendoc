--DROP FUNCTION gendoc.get_package_version(aschema name);

CREATE OR REPLACE FUNCTION gendoc.get_package_version(aschema name)
 RETURNS text
 LANGUAGE plpgsql
AS $function$
/**
 * Get schema/package version by calling schema.version() function
 *
 * @author Andrzej Kałuża
 * @created 2025-01-24
 * @return {varchar} major.minor.release or null
 * @since 1.0
 */
declare
   result text;
begin
  execute 'select '||quote_ident(aschema)||'.version()' into result;
  return result;
exception
  when others then
    return null;
end;
$function$;

ALTER FUNCTION gendoc.get_package_version(aschema name) OWNER TO gendoc;
COMMENT ON FUNCTION gendoc.get_package_version(aschema name) IS 'Get schema/package version by calling schema.version() function';
