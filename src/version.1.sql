--DROP FUNCTION gendoc.version();
CREATE OR REPLACE FUNCTION gendoc.version()
 RETURNS varchar
 LANGUAGE plpgsql
AS $function$
/**
 * Version of this package
 *
 * @return {varchar} 'major.minor.release'
 * @since 1.0
 */
begin
  return '2.0.0';
end;
$function$;
--
ALTER FUNCTION gendoc.version() OWNER TO gendoc;
COMMENT ON FUNCTION gendoc.version() IS '';
