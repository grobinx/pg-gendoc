--DROP FUNCTION gendoc.get_translation(alocation character varying);

CREATE OR REPLACE FUNCTION gendoc.get_translation(alocation character varying)
 RETURNS jsonb
 LANGUAGE plpgsql
AS $function$
/**
 * The function includes language translations
 * 
 * @param {varchar} alocation location shortcut (eg pl, en, ch)
 * @returns {jsonb} translation
 * 
 * @author Andrzej Kałuża
 * @created 2025-01-26
 * @version 1.0
 * @since 2.0
 */
declare
  l_translations jsonb;
begin
  l_translations := ($${
    "en": {
      "routines": "Routines",
      "tables": "Tables",
      "views": "Views",
      "toc": "Table of content"
    },
    "pl": {
      "routines": "Funkcje i procedury",
      "tables": "Tabele",
      "views": "Widoki",
      "toc": "Spis treści"
    }
  }$$)::jsonb;
  --
  return coalesce(l_translations->alocation, l_translations->'en');
end;
$function$;

ALTER FUNCTION gendoc.get_translation(alocation character varying) OWNER TO gendoc;
COMMENT ON FUNCTION gendoc.get_translation(alocation character varying) IS 'The function includes language translations';
