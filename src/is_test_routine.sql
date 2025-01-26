--DROP FUNCTION gendoc.is_test_routine(aschema name, aroutine text);

CREATE OR REPLACE FUNCTION gendoc.is_test_routine(aschema name, aroutine text)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
/**
 * Check is routine is set as test.
 *
 * @param {name} aschema schema name
 * @param {text} aroutine routine identity name
 * @returns {boolean}
 *
 * @author Andrzej Kałuża
 * @created 2025-01-6
 * @version 1.0
 * @since 2.0
 */
declare
  l_doc jsonb;
begin
  l_doc := gendoc.get_routine_doc(aschema, aroutine);
  --
  if l_doc is null then
    return false;
  end if;
  --
  return coalesce((l_doc->'test')::boolean, false);
end;
$function$;

ALTER FUNCTION gendoc.is_test_routine(aschema name, aroutine text) OWNER TO gendoc;
COMMENT ON FUNCTION gendoc.is_test_routine(aschema name, aroutine text) IS 'Check is routine is set as test.';