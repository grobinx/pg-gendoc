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
      "toc": "Table of content",
      "table_columns": "Table columns",
      "column_no_th": "No",
      "column_name_th": "Name",
      "data_type_th": "Data type",
      "default_value_th": "Default value",
      "nullable_th": "Null",
      "primary_key_th": "PK",
      "foreign_key_th": "FK",
      "description_th": "Description",
      "author": "Author",
      "version": "Version",
      "since": "Since",
      "created": "Created",
      "package": "Package",
      "module": "Module",
      "private": "Private",
      "public": "Public",
      "readonly": "Read only",
      "alias": "Alias",
      "deprecated": "Deprecated",
      "function": "Function",
      "variation": "Variation",
      "test": "Test",
      "summary": "Summary",
      "propeties": "Properties",
      "name_th": "Name",
      "requires": "Requires",
      "see": "See",
      "todo": "To do",
      "tutorial": "Tutorial",
      "isue": "Known problem",
      "columns": "Columns",
      "arguments": "Arguments",
      "mode_th": "Mode",
      "argument_no_th": "No",
      "argument_name_th": "Name",
      "returns": "Returns",
      "data_type": "Data type",
      "opt_sup": "opt",
      "schema": "Schema",
      "changes": "Changes",
      "example": "Example",
      "view_columns": "View columns"
    },
    "pl": {
      "routines": "Funkcje i procedury",
      "tables": "Tabele",
      "views": "Widoki",
      "toc": "Spis treści",
      "table_columns": "Kolumny tabeli",
      "column_no_th": "Lp",
      "column_name_th": "Nazwa",
      "data_type_th": "Typ danych",
      "default_value_th": "Wartość domyślna",
      "nullable_th": "Null",
      "primary_key_th": "PK",
      "foreign_key_th": "FK",
      "description_th": "Opis",
      "author": "Autor",
      "version": "Wersja",
      "since": "Dostępna od",
      "created": "Utworzono",
      "package": "Pakiet",
      "module": "Moduł",
      "private": "Prywatne",
      "public": "Publiczne",
      "readonly": "Tylko do odczytu",
      "alias": "Alias",
      "deprecated": "Wycofana",
      "function": "Funkcja",
      "variation": "Wariant",
      "test": "Test",
      "summary": "Podsumowanie",
      "propeties": "Właściwości",
      "name_th": "Nazwa",
      "requires": "Wymagane",
      "see": "Zobacz też",
      "todo": "Do zrobienia",
      "tutorial": "Poradnik",
      "isue": "Znane problemy",
      "columns": "Kolumny",
      "arguments": "Argumenty",
      "mode_th": "Tryb",
      "argument_no_th": "Lp",
      "argument_name_th": "Nazwa",
      "returns": "Zwraca",
      "data_type": "Typ danych",
      "opt_sup": "opc",
      "schema": "Schemat",
      "changes": "Zmiany",
      "example": "Przykład",
      "view_columns": "Kolumny widoku"
    }
  }$$)::jsonb;
  --
  return coalesce(l_translations->alocation, l_translations->'en');
end;
$function$;

ALTER FUNCTION gendoc.get_translation(alocation character varying) OWNER TO gendoc;
COMMENT ON FUNCTION gendoc.get_translation(alocation character varying) IS 'The function includes language translations';
