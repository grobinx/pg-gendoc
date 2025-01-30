--
-- PostgreSQL database dump
--

-- Dumped from database version 15.10 (Debian 15.10-0+deb12u1)
-- Dumped by pg_dump version 17.0

-- Started on 2025-01-30 22:49:41

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- TOC entry 12 (class 2615 OID 16842)
-- Name: gendoc; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA gendoc;


--
-- TOC entry 389 (class 1255 OID 27516)
-- Name: get_collect_info(name, jsonb); Type: FUNCTION; Schema: gendoc; Owner: -
--

CREATE FUNCTION gendoc.get_collect_info(aschema name, aoptions jsonb DEFAULT NULL::json) RETURNS TABLE(schema jsonb, version character varying, routines jsonb, tables jsonb, views jsonb)
    LANGUAGE plpgsql
    AS $$
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
$$;


--
-- TOC entry 3550 (class 0 OID 0)
-- Dependencies: 389
-- Name: FUNCTION get_collect_info(aschema name, aoptions jsonb); Type: COMMENT; Schema: gendoc; Owner: -
--

COMMENT ON FUNCTION gendoc.get_collect_info(aschema name, aoptions jsonb) IS 'Collects complete information about objects and returns it in the form of a record';


--
-- TOC entry 308 (class 1255 OID 16843)
-- Name: get_package_version(name); Type: FUNCTION; Schema: gendoc; Owner: -
--

CREATE FUNCTION gendoc.get_package_version(aschema name) RETURNS text
    LANGUAGE plpgsql
    AS $$
/**
 * Get schema/package version by calling schema.version() function
 *
 * @summary get package version
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
$$;


--
-- TOC entry 367 (class 1255 OID 27494)
-- Name: get_routine_doc(name, text); Type: FUNCTION; Schema: gendoc; Owner: -
--

CREATE FUNCTION gendoc.get_routine_doc(aschema name, aroutine text) RETURNS jsonb
    LANGUAGE plpgsql
    AS $$
/**
 * Function parse jsdoc data from body by identity name.
 *
 * @summary parse one routine doc
 *
 * @param {name} aschema schema name
 * @param {text} aroutine routine identity name
 * @returns {jsonb}
 *
 * @author Andrzej Kałuża
 * @created 2025-01-25
 * @version 1.0
 * @since 2.0
 */
begin
  return gendoc.jsdoc_parse(substring(pg_get_functiondef(p.oid) from '\/\*\*.*?\*\/'))
    from pg_catalog.pg_proc p
         join pg_catalog.pg_namespace n on n.oid = p.pronamespace
   where n.nspname = aschema
     and p.proname||'('||coalesce(pg_get_function_identity_arguments(p.oid), '')||')' = aroutine;
end;
$$;


--
-- TOC entry 411 (class 1255 OID 27547)
-- Name: get_routines(name, jsonb); Type: FUNCTION; Schema: gendoc; Owner: -
--

CREATE FUNCTION gendoc.get_routines(aschema name, aoptions jsonb) RETURNS jsonb
    LANGUAGE plpgsql
    AS $_$
/**
 * Create jsonb with all usable information about routines on schema
 *
 * @summary collect usable information
 * 
 * @param {name} aschema schema name
 * @param {jsonb} aoptions options
 * @returns {jsonb}
 *
 * @property {varchar[]} aoptions.routines.include include routines or null if all
 * @property {varchar[]} aoptions.routines.exclude exclude routines or null if all
 * @property {varchar[]} aoptions.package package names or null if all and if aoptions.parse.routine_body set to true
 * @property {varchar[]} aoptions.module module names or null if all and if aoptions.parse.routine_body set to true
 * @property {boolean} [aoptions.parse.routine_body=true] parse body for search documentation if plpgsql, otherwise the comment will be processed
 * 
 * @author Andrzej Kałuża
 * @created 2025-01-25
 * @version 1.0
 * @since 2.0
 */
declare
  l_include varchar[] := array_agg(x) from jsonb_array_elements_text(aoptions->'routines'->'include') x;
  l_exclude varchar[] := array_agg(x) from jsonb_array_elements_text(aoptions->'routines'->'exclude') x;
  l_package varchar[] := array_agg(x) from jsonb_array_elements_text(aoptions->'package') x;
  l_module varchar[] := array_agg(x) from jsonb_array_elements_text(aoptions->'module') x;
  l_parse_body boolean := coalesce((aoptions->'parse'->'routine_body')::boolean, true);
begin
  return jsonb_agg(
           jsonb_build_object(
             'schema_name', p.nspname, 'routine_name', p.proname,
             'kind', case p.prokind when 'f'::char then 'function' when 'p'::char then 'procedure' end,
             'returns', pg_get_function_result(p.oid), 'returns_type', pg_catalog.format_type(p.prorettype, null),
             'arguments', coalesce(a.arguments, '[]'),
             'description', p.description, 'doc_data', p.doc_data,
             'identity_name', p.proname||'('||coalesce(pg_get_function_identity_arguments(p.oid), '')||')',
             'language', p.lanname
           )
           order by p.nspname, p.proname
         )
    from (select p.oid, n.nspname, p.proname, p.prokind, p.prorettype, d.description, l.lanname,
                 case 
                   when l_parse_body then 
                     case when l.lanname = 'plpgsql' then gendoc.jsdoc_parse(substring(p.prosrc from '\/\*\*.*\*\/'))
                          else gendoc.jsdoc_parse(d.description)
                     end
                 end doc_data
            from pg_proc p
                 join pg_namespace n on n.oid = p.pronamespace
                 join pg_language l on l.oid = p.prolang
                 left join pg_description d on d.classoid = 'pg_proc'::regclass and d.objoid = p.oid and d.objsubid = 0
           where p.prokind in ('f', 'p') 
             and n.nspname = aschema
             and (l_include is null or p.proname = any (l_include))
             and (l_exclude is null or p.proname <> all (l_exclude))) p
         join lateral (
           select jsonb_agg(
                    jsonb_build_object(
                      'argument_no', r.argument_no, 'argument_name', r.argument_name, 'data_type', r.data_type, 'mode', r.mode, 'default_value', r.default_value
                    )
                  ) arguments
             from (select n as argument_no, f.proargnames[n] as argument_name, pg_catalog.format_type(f.proargtypes[n -1], -1) as data_type,
                          case f.proargmodes[n] when 'o' then 'out' when 'b' then 'in/out' else 'in' end as mode,
                          trim((regexp_split_to_array(pg_get_expr(f.proargdefaults, 0), '[\t,](?=(?:[^\'']|\''[^\'']*\'')*$)'))[case when f.pronargs -n > f.pronargdefaults then null else f.pronargdefaults -(f.pronargs -n +1) +1 end]) default_value
                     from (select f.oid, pg_catalog.generate_series(1, f.pronargs::int) n, f.*
                             from pg_catalog.pg_proc f
                            where f.oid = p.oid) f) r) a on true
   where (l_package is null or p.doc_data->>'package' is null or p.doc_data->>'package' = any (l_package))
     and (l_module is null or p.doc_data->>'module' is null or p.doc_data->>'module' = any (l_module));
end;
$_$;


--
-- TOC entry 380 (class 1255 OID 27546)
-- Name: get_schema(name, jsonb); Type: FUNCTION; Schema: gendoc; Owner: -
--

CREATE FUNCTION gendoc.get_schema(aschema name, aoptions jsonb) RETURNS jsonb
    LANGUAGE plpgsql
    AS $$
/**
 * Create jsonb with all usable information about schema
 * 
 * @param {name} aschema schema name
 * @param {jsonb} aoptions options
 * @returns {jsonb}
 *
 * @property {boolean} [aoptions.parse.schema_comment=false] whether the schema comment should be processed
 * 
 * @author Andrzej Kałuża
 * @created 2025-01-25
 * @version 1.0
 * @since 2.0
 */
begin
  return jsonb_build_object(
           'schema_name', ns.nspname, 
           'description', des.description,
           'doc_data', case when coalesce((aoptions->'parse'->>'schema_comment')::boolean, false) then gendoc.jsdoc_parse(des.description) end
         )
    from pg_description des
         join pg_namespace ns on des.objoid = ns.oid
   where classoid = 'pg_namespace'::regclass
     and ns.nspname = aschema;
end;
$$;


--
-- TOC entry 3551 (class 0 OID 0)
-- Dependencies: 380
-- Name: FUNCTION get_schema(aschema name, aoptions jsonb); Type: COMMENT; Schema: gendoc; Owner: -
--

COMMENT ON FUNCTION gendoc.get_schema(aschema name, aoptions jsonb) IS 'Create jsonb with all usable information about schema';


--
-- TOC entry 397 (class 1255 OID 27552)
-- Name: get_tables(name, jsonb); Type: FUNCTION; Schema: gendoc; Owner: -
--

CREATE FUNCTION gendoc.get_tables(aschema name, aoptions jsonb) RETURNS jsonb
    LANGUAGE plpgsql
    AS $$
/**
 * Create jsonb with all usable information about tables on schema
 *
 * @summary collect information about tables
 * 
 * @param {name} aschema schema name
 * @param {jsonb} aoptions options
 * @returns {jsonb}
 *
 * @property {varchar[]} aoptions.tables.include include tables or null if all
 * @property {varchar[]} aoptions.tables.exclude exclude tables or null if all
 * @property {varchar[]} aoptions.package package names or null if all 
 * @property {varchar[]} aoptions.module module names or null if all 
 * @property {boolean} [aoptions.parse.table_comment=true] parse doc table comment
 * @property {boolean} [aoptions.parse.table_column_comment=false] parse doc table column comment
 * 
 * @author Andrzej Kałuża
 * @created 2025-01-24
 * @version 1.0
 * @since 2.0
 */
declare
  l_include varchar[] := array_agg(x) from jsonb_array_elements_text(aoptions->'tables'->'include') x;
  l_exclude varchar[] := array_agg(x) from jsonb_array_elements_text(aoptions->'tables'->'exclude') x;
  l_package varchar[] := array_agg(x) from jsonb_array_elements_text(aoptions->'package') x;
  l_module varchar[] := array_agg(x) from jsonb_array_elements_text(aoptions->'module') x;
  l_table_comment boolean := coalesce((aoptions->'parse'->'table_comment')::boolean, true);
  l_column_comment boolean := coalesce((aoptions->'parse'->'table_column_comment')::boolean, false);
begin
  return jsonb_agg(
           jsonb_build_object(
             'schema_name', c.nspname, 'table_name', c.relname, 'description', c.description, 
             'kind', case c.relkind when 'f'::char then 'foreign' when 'r'::char then 'ordinary' when 'p'::char then 'partitioned' end,
             'columns', cls.columns, 'doc_data', doc_data
           )
           order by c.nspname, c.relname) as tables
    from (select c.oid, n.nspname, c.relname, c.relkind, d.description,
                 case when l_table_comment then gendoc.jsdoc_parse(d.description) end doc_data
            from pg_class c
                 join pg_namespace n on n.oid = c.relnamespace
                 left join pg_description d on d.classoid = 'pg_class'::regclass and d.objoid = c.oid and d.objsubid = 0
           where c.relkind in ('r'::char, 'f'::char, 'p'::char)
             and n.nspname = aschema
             and (l_include is null or c.relname = any (l_include))
             and (l_exclude is null or c.relname <> all (l_exclude))) c
         join lateral 
              (select jsonb_agg(
                        jsonb_build_object(
                          'column_no', column_no, 'column_name', column_name, 'data_type', data_type, 'nullable', nullable, 
                          'default_value', default_value, 'storage_type', storage_type, 
                          'description', description, 'foreign_key', foreign_key, 'primary_key', primary_key,
                          'doc_data', case when l_column_comment then gendoc.jsdoc_parse(description) end
                        )
                        order by column_no
                      ) as columns
                 from (select att.attname as column_name, att.attnum as column_no, 
                              case when ty.typtype = 'd'::"char" and tn.nspname <> 'public' then tn.nspname||'.' else '' end||
                                case when (SELECT true FROM pg_class seq, pg_depend d WHERE seq.relkind = 'S' and d.objid=seq.oid AND d.deptype='a' and d.refobjid = att.attrelid and d.refobjsubid = att.attnum limit 1) then
                                    case att.atttypid when 23 then 'serial' when 20 then 'bigserial' else pg_catalog.format_type(ty.oid, att.atttypmod) end
                                  else pg_catalog.format_type(ty.oid, att.atttypmod)
                                end
                                as data_type,
                              att.attnotnull nullable, pg_get_expr(def.adbin, def.adrelid) as default_value,
                              case att.attstorage when 'x' then 'EXTENDED' when 'p' then 'PLAIN' when 'e' then 'EXTERNAL' when 'm' then 'MAIN' else '???' end as storage_type, 
                              des.description,
                              exists (select from pg_constraint where conrelid = att.attrelid and contype='f' and att.attnum = any(conkey)) as foreign_key,
                              exists (select from pg_constraint where conrelid = att.attrelid and contype='p' and att.attnum = any(conkey)) as primary_key
                         from pg_attribute att
                              join pg_type ty on ty.oid = atttypid
                              join pg_namespace tn on tn.oid = ty.typnamespace
                              join pg_class cl on cl.oid = att.attrelid
                              join pg_namespace na on na.oid = cl.relnamespace
                              left outer join pg_attrdef def on adrelid = att.attrelid and adnum = att.attnum
                              left outer join pg_description des on des.classoid = 'pg_class'::regclass and des.objoid = att.attrelid and des.objsubid = att.attnum
                        where att.attnum > 0
                          and cl.oid = c.oid) cols) cls on true
   where (l_package is null or c.doc_data->>'package' is null or c.doc_data->>'package' = any (l_package))
     and (l_module is null or c.doc_data->>'module' is null or c.doc_data->>'module' = any (l_module));
end;
$$;


--
-- TOC entry 396 (class 1255 OID 27526)
-- Name: get_translation(character varying); Type: FUNCTION; Schema: gendoc; Owner: -
--

CREATE FUNCTION gendoc.get_translation(alocation character varying) RETURNS jsonb
    LANGUAGE plpgsql
    AS $_$
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
$_$;


--
-- TOC entry 3552 (class 0 OID 0)
-- Dependencies: 396
-- Name: FUNCTION get_translation(alocation character varying); Type: COMMENT; Schema: gendoc; Owner: -
--

COMMENT ON FUNCTION gendoc.get_translation(alocation character varying) IS 'The function includes language translations';


--
-- TOC entry 413 (class 1255 OID 27594)
-- Name: get_views(name, jsonb); Type: FUNCTION; Schema: gendoc; Owner: -
--

CREATE FUNCTION gendoc.get_views(aschema name, aoptions jsonb) RETURNS jsonb
    LANGUAGE plpgsql
    AS $$
/**
 * Create jsonb with all usable information about views on schema
 *
 * @summary collect information about views
 * 
 * @param {name} aschema schema name
 * @param {jsonb} aoptions options
 * @returns {jsonb}
 *
 * @property {varchar[]} aoptions.views.include include views or null if all
 * @property {varchar[]} aoptions.views.exclude exclude views or null if all
 * @property {varchar[]} aoptions.package package names or null if all 
 * @property {varchar[]} aoptions.module module names or null if all 
 * @property {boolean} [aoptions.parse.view_comment=true] parse doc table comment
 * @property {boolean} [aoptions.parse.view_column_comment=false] parse doc table column comment
 * 
 * @author Andrzej Kałuża
 * @created 2025-01-25
 * @version 1.0
 * @since 2.0
 */
declare
  l_include varchar[] := array_agg(x) from jsonb_array_elements_text(aoptions->'views'->'include') x;
  l_exclude varchar[] := array_agg(x) from jsonb_array_elements_text(aoptions->'views'->'exclude') x;
  l_package varchar[] := array_agg(x) from jsonb_array_elements_text(aoptions->'package') x;
  l_module varchar[] := array_agg(x) from jsonb_array_elements_text(aoptions->'module') x;
  l_view_comment boolean := coalesce((aoptions->'parse'->'view_comment')::boolean, true);
  l_column_comment boolean := coalesce((aoptions->'parse'->'view_column_comment')::boolean, false);
begin
  return jsonb_agg(
           jsonb_build_object(
             'schema_name', c.nspname, 'view_name', c.relname, 'description', c.description, 
             'kind', case c.relkind when 'v'::char then 'view' when 'm'::char then 'materialized' end,
             'columns', cls.columns, 'doc_data', c.doc_data
           )
           order by c.nspname, c.relname
         ) as tables
    from (select c.oid, n.nspname, c.relname, d.description, c.relkind,
                 case when l_view_comment then gendoc.jsdoc_parse(d.description) end doc_data
            from pg_class c
                 left join pg_namespace n on n.oid = c.relnamespace
                 left join pg_description d on d.classoid = 'pg_class'::regclass and d.objoid = c.oid and d.objsubid = 0
           where c.relkind in ('v'::char, 'm'::char)
             and n.nspname = aschema
             and (l_include is null or c.relname = any (l_include))
             and (l_exclude is null or c.relname <> all (l_exclude))) c
         join lateral 
              (select jsonb_agg(
                        jsonb_build_object(
                          'column_no', column_no, 'column_name', column_name, 'data_type', data_type, 'storage_type', storage_type, 
                          'description', description, 'doc_data', case when l_column_comment then gendoc.jsdoc_parse(description) end
                        )
                        order by column_no
                      ) as columns
                 from (select att.attname as column_name, att.attnum as column_no, 
                              case when ty.typtype = 'd'::"char" and tn.nspname <> 'public' then tn.nspname||'.' else '' end||
                                pg_catalog.format_type(ty.oid, att.atttypmod) as data_type,
                              case att.attstorage when 'x' then 'EXTENDED' when 'p' then 'PLAIN' when 'e' then 'EXTERNAL' when 'm' then 'MAIN' else '???' end as storage_type, 
                              des.description
                         from pg_attribute att
                              join pg_type ty on ty.oid = atttypid
                              join pg_namespace tn on tn.oid = ty.typnamespace
                              join pg_class cl on cl.oid = att.attrelid
                              join pg_namespace na on na.oid = cl.relnamespace
                              left outer join pg_attrdef def on adrelid = att.attrelid and adnum = att.attnum
                              left outer join pg_description des on des.classoid = 'pg_class'::regclass and des.objoid = att.attrelid and des.objsubid = att.attnum
                        where att.attnum > 0
                          and cl.oid = c.oid) cols) cls on true
   where (l_package is null or c.doc_data->>'package' is null or c.doc_data->>'package' = any (l_package))
     and (l_module is null or c.doc_data->>'module' is null or c.doc_data->>'module' = any (l_module));
end;
$$;


--
-- TOC entry 401 (class 1255 OID 27517)
-- Name: html(name, jsonb); Type: FUNCTION; Schema: gendoc; Owner: -
--

CREATE FUNCTION gendoc.html(aschema name, aoptions jsonb DEFAULT NULL::jsonb) RETURNS text
    LANGUAGE plpgsql
    AS $$
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
$$;


--
-- TOC entry 323 (class 1255 OID 27523)
-- Name: html_create_toc(jsonb, jsonb, jsonb, jsonb); Type: FUNCTION; Schema: gendoc; Owner: -
--

CREATE FUNCTION gendoc.html_create_toc(aroutines jsonb, atables jsonb, aviews jsonb, alocation jsonb) RETURNS text
    LANGUAGE plpgsql IMMUTABLE
    AS $$
/**
 * Create table of content for all series
 *
 * Level 1
 *
 * @summary toc for all objects
 * 
 * @param {jsonb} aroutines routines series
 * @param {jsonb} atables tables series
 * @param {jsonb} aviews views series
 * @param {jsonb} alocation tarnslation strings
 * @returns {text}
 * 
 * @author Andrzej Kałuża
 * @created 2025-01-26
 * @version 1.0
 * @since 2.0
 */
declare
  l_result text := '';
begin
  l_result := l_result || '<section id="toc"><h2>'||(alocation->>'toc')||'</h2>';
  l_result := l_result || '<ol>';
  if aroutines is not null then
    l_result := l_result || '<li><a href="#routines" />'||(alocation->>'routines')||'</a>';
    l_result := l_result || gendoc.html_series_toc(aroutines, 'routine_name');
    l_result := l_result || '</li>';
  end if;
  if atables is not null then
    l_result := l_result || '<li><a href="#tables" />'||(alocation->>'tables')||'</a>';
    l_result := l_result || gendoc.html_series_toc(atables, 'table_name');
    l_result := l_result || '</li>';
  end if;
  if aviews is not null then
    l_result := l_result || '<li><a href="#views" />'||(alocation->>'views')||'</a>';
    l_result := l_result || gendoc.html_series_toc(aviews, 'view_name');
    l_result := l_result || '</li>';
  end if;
  l_result := l_result || '</ol>';
  l_result := l_result || '</section>';
  --
  return l_result;
end;
$$;


--
-- TOC entry 307 (class 1255 OID 27606)
-- Name: html_doc_data_param(jsonb, jsonb, jsonb); Type: FUNCTION; Schema: gendoc; Owner: -
--

CREATE FUNCTION gendoc.html_doc_data_param(adoc_data jsonb, aarguments jsonb, alocation jsonb) RETURNS text
    LANGUAGE plpgsql IMMUTABLE
    AS $$
/**
 * Creates a collection of information from doc_data about arguments
 *
 * @summary create information about arguments
 *
 * @param {jsonb} adoc_data doc data
 * @param {jsonb} aarguments routine arguments
 * @param {jsonb} alocation tarnslation strings
 * @returns {text}
 * 
 * @author Andrzej Kałuża
 * @created 2025-01-28
 * @version 1.0
 * @since 2.0
 */
declare
  l_result text := '';
begin
  if adoc_data->'param' is not null or jsonb_array_length(aarguments) > 0 then    
    l_result := l_result || '<h4>'||(alocation->>'arguments')||'</h4>';
    l_result := l_result || '<table>';
    l_result := l_result || '<thead>';
    l_result := l_result || 
      '<tr><th>'||(alocation->>'argument_no_th')||'</th><th>'||(alocation->>'argument_name_th')||'</th>'||
      '<th>'||(alocation->>'data_type_th')||'</th>'||'<th>'||(alocation->>'default_value_th')||'</th>'||
      '<th>'||(alocation->>'mode_th')||'</th><th>'||(alocation->>'description_th')||'</th>'||
      '</tr>';
    l_result := l_result || '</thead>';
    --
    l_result := l_result || '<tbody>';
    l_result := l_result ||
      string_agg(
         '<tr><td>'||coalesce(ra->>'argument_no', '')||'</td><td>'||coalesce(ra->>'argument_name', rp->>'name')||'</td>'||
         '<td>'||coalesce(ra->>'data_type', rp->>'type')||'</td><td>'||coalesce(ra->>'default_value', rp->>'default', '')||'</td>'||
         '<td>'||coalesce(ra->>'mode', '')||'</td><td>'||coalesce(rp->>'description', '')||'</td></tr>',
       '' order by (ra->>'argument_no')::numeric, coalesce(ra->>'argument_name', rp->>'name'))
      from jsonb_array_elements(aarguments) ra 
           full join jsonb_array_elements(adoc_data->'param') rp on rp->>'name' = ra->>'argument_name';
    l_result := l_result || '</tbody>';
    --
    l_result := l_result || '</table>';
  end if;
  --
  return l_result;
end;
$$;


--
-- TOC entry 394 (class 1255 OID 27592)
-- Name: html_doc_data_prop(jsonb, jsonb); Type: FUNCTION; Schema: gendoc; Owner: -
--

CREATE FUNCTION gendoc.html_doc_data_prop(adoc_data jsonb, alocation jsonb) RETURNS text
    LANGUAGE plpgsql IMMUTABLE
    AS $$
/**
 * Creates a collection of information from doc_data about properties
 *
 * @summary create information about properties
 *
 * @param {jsonb} adoc_data tabl
 * @param {jsonb} alocation tarnslation strings
 * @returns {text}
 * 
 * @author Andrzej Kałuża
 * @created 2025-01-28
 * @version 1.0
 * @since 2.0
 */
declare
  l_result text := '';
begin
  if adoc_data->'property' is not null then
    l_result := l_result || '<h4>'||(alocation->>'propeties')||'</h4>';
    l_result := l_result || '<table>';
    l_result := l_result || '<thead>';
    l_result := l_result || 
      '<tr><th>'||(alocation->>'name_th')||'</th><th>'||(alocation->>'data_type_th')||'</th>'||
      '<th>'||(alocation->>'default_value_th')||'</th><th>'||(alocation->>'description_th')||'</th>'||
      '</tr>';
    l_result := l_result || '</thead>';
    --
    l_result := l_result || '<tbody>';
    l_result := l_result || 
      string_agg(
        '<tr><td>'||coalesce(v->>'name', '')||'</td><td>'||coalesce(v->>'type', '')||'</td>'||
        '<td>'||coalesce(v->>'default', '')||'</td><td>'||coalesce(v->>'description', '')||'</td></tr>',
      '')
      from jsonb_array_elements(adoc_data->'property') v;
    l_result := l_result || '</tbody>';
    --
    l_result := l_result || '</table>';
  end if;
  --
  return l_result;
end;
$$;


--
-- TOC entry 400 (class 1255 OID 27591)
-- Name: html_doc_data_uni(jsonb, jsonb); Type: FUNCTION; Schema: gendoc; Owner: -
--

CREATE FUNCTION gendoc.html_doc_data_uni(adoc_data jsonb, alocation jsonb) RETURNS text
    LANGUAGE plpgsql IMMUTABLE
    AS $_$
/**
 * Creates a collection of uniwersal information from doc_data
 *
 * @summary create uniwersal for all obejcts information
 *
 * @param {jsonb} adoc_data tabl
 * @param {jsonb} alocation tarnslation strings
 * @returns {text}
 * 
 * @author Andrzej Kałuża
 * @created 2025-01-27
 * @version 1.0
 * @since 2.0
 */
declare
  l_result text := '';
begin
  if adoc_data is not null then
    l_result := l_result || '<dl>';
    if adoc_data->'author' is not null then
      l_result := l_result || '<dt>'||(alocation->>'author')||'</dt>';
      l_result := l_result || '<dd>';
      l_result := l_result || '<ul>';
      l_result := l_result || 
        string_agg(
          '<li>'||
            coalesce(c->>'author', '')||
            coalesce(' &lt;'||(c->>'email')||'&gt;', '')||
            coalesce(' ('||(c->>'page')||')', '')||
            coalesce(' - '||(c->>'description'), '')||
          '</li>', 
        '') from jsonb_array_elements(adoc_data->'author') c;
      l_result := l_result || '</ul>';
      l_result := l_result || '</dd>';
    end if;
    if adoc_data->'version' is not null then
      l_result := l_result || '<dt>'||(alocation->>'version')||'</dt><dd>'||(adoc_data->>'version')||'</dd>';
    end if;
    if adoc_data->'since' is not null then
      l_result := l_result || '<dt>'||(alocation->>'since')||'</dt><dd>'||(adoc_data->>'since')||'</dd>';
    end if;
    if adoc_data->'created' is not null then
      l_result := l_result || '<dt>'||(alocation->>'created')||'</dt><dd>'||(adoc_data->>'created')||'</dd>';
    end if;
    if adoc_data->'package' is not null then
      l_result := l_result || '<dt>'||(alocation->>'package')||'</dt><dd>'||(adoc_data->>'package')||'</dd>';
    end if;
    if adoc_data->'module' is not null then
      l_result := l_result || '<dt>'||(alocation->>'module')||'</dt><dd>'||(adoc_data->>'module')||'</dd>';
    end if;
    if adoc_data->'public' is not null then
      l_result := l_result || '<dt>'||(alocation->>'public')||'</dt><dd>'||(adoc_data->>'public')||'</dd>';
    end if;
    if adoc_data->'private' is not null then
      l_result := l_result || '<dt>'||(alocation->>'private')||'</dt><dd>'||(adoc_data->>'private')||'</dd>';
    end if;
    if adoc_data->'readonly' is not null then
      l_result := l_result || '<dt>'||(alocation->>'readonly')||'</dt><dd>'||(adoc_data->>'readonly')||'</dd>';
    end if;
    if adoc_data->'alias' is not null then
      l_result := l_result || '<dt>'||(alocation->>'alias')||'</dt><dd>'||(adoc_data->>'alias')||'</dd>';
    end if;
    if adoc_data->'deprecated' is not null then
      l_result := l_result || '<dt>'||(alocation->>'deprecated')||'</dt><dd>'||(adoc_data->>'deprecated')||'</dd>';
    end if;
    if adoc_data->'function' is not null then
      l_result := l_result || '<dt>'||(alocation->>'function')||'</dt><dd>'||(adoc_data->>'function')||'</dd>';
    end if;
    if adoc_data->'variation' is not null then
      l_result := l_result || '<dt>'||(alocation->>'variation')||'</dt><dd>'||(adoc_data->>'variation')||'</dd>';
    end if;
    if adoc_data->'test' is not null then
      l_result := l_result || '<dt>'||(alocation->>'test')||'</dt><dd>'||(adoc_data->>'test')||'</dd>';
    end if;
    if adoc_data->'requires' is not null then
      l_result := l_result || 
        '<dt>'||(alocation->>'requires')||'</dt>'||
        '<dd>'||
          (select '<ul>'||string_agg('<li>'||x||'</li>', '')||'</ul>' from jsonb_array_elements_text(adoc_data->'requires') x)||
        '</dd>';
    end if;
    if adoc_data->'see' is not null then
      l_result := l_result || 
        '<dt>'||(alocation->>'see')||'</dt>'||
        '<dd>'||
          (select '<ul>'||string_agg('<li>'||(x->>'path')||coalesce(' '||(x->>'description'), '')||'</li>', '')||'</ul>' from jsonb_array_elements(adoc_data->'see') x)||
        '</dd>';
    end if;
    if adoc_data->'tutorial' is not null then
      l_result := l_result || 
        '<dt>'||(alocation->>'tutorial')||'</dt>'||
        '<dd>'||
          (select '<ul>'||string_agg('<li>'||x||'</li>', '')||'</ul>' from jsonb_array_elements_text(adoc_data->'tutorial') x)||
        '</dd>';
    end if;
    --
    l_result := l_result || '</dl>';
    --
    if adoc_data->'isue' is not null then
      l_result := l_result || 
        '<h4>'||(alocation->>'isue')||'</h4>'||
        '<p>'||
          (select string_agg(x, '<br />') from jsonb_array_elements_text(adoc_data->>'isue') x)||
        '</p>';
    end if;
    --
    if adoc_data->'todo' is not null then
      l_result := l_result || 
        '<h4>'||(alocation->>'todo')||'</h4>'||
        '<p>'||
          (select string_agg(x, '<br />') from jsonb_array_elements_text(adoc_data->'todo') x)||
        '</p>';
    end if;
    --
    if adoc_data->'example' is not null then
      l_result := l_result || 
        '<h4>'||(alocation->>'example')||'</h4>'||
          (select string_agg('<code><pre>'||trim(e'[ \r\n]+$' from x)||'</pre></code>', '') from jsonb_array_elements_text(adoc_data->'example') x);
    end if;
    --
    if adoc_data->'change' is not null then
      l_result := l_result || 
        '<h4>'||(alocation->>'changes')||'</h4>'||
        '<ul>'||
        (select string_agg(
                  '<li>'||
                    coalesce((x->>'date'), '')||
                    coalesce(' '||(x->>'author'), '')||
                    coalesce(' - '||(x->>'description'), '')||
                  '</li>', '')
           from jsonb_array_elements(adoc_data->'change') x)||
        '</ul>';
    end if;
    --
    if adoc_data->'summary' is not null then
      l_result := l_result || '<h4>'||(alocation->>'summary')||'</h4><p>'||(adoc_data->>'summary')||'</p>';
    end if;
  end if;
  --
  return l_result;
end;
$_$;


--
-- TOC entry 398 (class 1255 OID 27599)
-- Name: html_routine(jsonb, jsonb); Type: FUNCTION; Schema: gendoc; Owner: -
--

CREATE FUNCTION gendoc.html_routine(aroutine jsonb, alocation jsonb) RETURNS text
    LANGUAGE plpgsql IMMUTABLE
    AS $$
/**
 * Create one routine html section
 *
 * @param {jsonb} atable tabl
 * @param {jsonb} alocation tarnslation strings
 * @returns {text}
 * 
 * @author Andrzej Kałuża
 * @created 2025-01-27
 * @version 1.0
 * @since 2.0
 */
declare
  l_result text := '';
  l_authors text := '';
  l_doc_data jsonb := aroutine->'doc_data';
begin
  l_result := l_result || '<section>';
  l_result := l_result || '<a name="'||(aroutine->>'routine_name')||'"></a>';
  l_result := l_result || '<h3>'||(aroutine->>'routine_name')||' <small>('||(aroutine->>'kind')||')</small></h3>';
  l_result := l_result || 
    '<code>'||(aroutine->>'routine_name')||'('||
      coalesce((select string_agg(x->>'argument_name'||case when jsonb_typeof(x->'default_value') != 'null' then '<sup>'||(alocation->>'opt_sup')||'</sup>' else '' end, ', ')
         from jsonb_array_elements(aroutine->'arguments') x), '')||
      ') <span>→ '||(aroutine->>'returns_type')||
    '</code>';
  --
  if l_doc_data->>'root' is not null then
    l_result := l_result || '<p>'||replace(l_doc_data->>'root', e'\n', '<br />')||'</p>';
  elsif aroutine->>'description' is not null then
    l_result := l_result || '<p>'||replace(aroutine->>'description', e'\n', '<br />')||'</p>';
  end if;
  --
  --raise debug '% %', (aroutine->>'routine_name'), length(l_result);
  l_result := l_result || gendoc.html_doc_data_param(l_doc_data, aroutine->'arguments', alocation);
  l_result := l_result || gendoc.html_doc_data_prop(l_doc_data, alocation);
  l_result := l_result || gendoc.html_doc_data_uni(l_doc_data, alocation);
  --
  if l_doc_data->'column' then
    l_result := l_result || '<h4>'||(alocation->>'columns')||'</h4>';
    l_result := l_result || '<table>';
    l_result := l_result || 
      '<thead><tr>'||
        '<th>'||(alocation->>'name_th')||'</th><th>'||(alocation->>'data_type_th', '')||'</th>'||
        '<th>'||(alocation->>'description_th', '')||'</th>'||
      '</tr></thead>';
    l_result := l_result || '<tbody>';
    l_result := l_result || 
      string_agg(
        '<tr>'||
          '<td>'||coalesce(c->>'name', '')||'</td><td>'||coalesce(c->>'type', '')||'</td>'||
          '<td>'||coalesce(c->>'description', '')||'</td>'||
        '</tr>',
      '') cols from jsonb_array_elements(l_doc_data->'column') c;
    l_result := l_result || '</tbody></table>';
  end if;
  --
  if aroutine->>'returns' != 'void' then
    l_result := l_result || '<h4>'||(alocation->>'returns')||'</h4>';
    if l_doc_data->'returns'->>'description' is not null then
      l_result := l_result || '<p>'||replace(l_doc_data->'returns'->>'description', e'\n', '<br />')||'</p>';
    end if;
    l_result := l_result || '<dl><dt>'||(alocation->>'data_type')||'</dt><dd><code>'||coalesce(aroutine->>'returns', l_doc_data->'returns'->>'type')||'</code></dd></dl>';
  end if;
  --
  l_result := l_result || '</section>';
  --
  return l_result;
end;
$$;


--
-- TOC entry 314 (class 1255 OID 27598)
-- Name: html_routines(jsonb, jsonb); Type: FUNCTION; Schema: gendoc; Owner: -
--

CREATE FUNCTION gendoc.html_routines(aroutines jsonb, alocation jsonb) RETURNS text
    LANGUAGE plpgsql IMMUTABLE
    AS $$
/**
 * Create routines html section
 *
 * @param {jsonb} aroutines routine series
 * @param {jsonb} alocation tarnslation strings
 * @returns {text}
 * 
 * @author Andrzej Kałuża
 * @created 2025-01-28
 * @version 1.0
 * @since 2.0
 */
declare
  l_result text := '';
begin
  l_result := l_result || '<section id="routines"><h2>'||(alocation->>'routines')||'</h2>';
  l_result := l_result || (select string_agg(gendoc.html_routine(t, alocation), '' order by t->>'routine_name') from jsonb_array_elements(aroutines) t);
  l_result := l_result || '</section>';
  --
  return l_result;
end;
$$;


--
-- TOC entry 412 (class 1255 OID 27638)
-- Name: html_schema(jsonb, jsonb); Type: FUNCTION; Schema: gendoc; Owner: -
--

CREATE FUNCTION gendoc.html_schema(aschema jsonb, alocation jsonb) RETURNS text
    LANGUAGE plpgsql IMMUTABLE
    AS $$
/**
 * Create schema html section
 *
 * @param {jsonb} atable tabl
 * @param {jsonb} alocation tarnslation strings
 * @returns {text}
 * 
 * @author Andrzej Kałuża
 * @created 2025-01-30
 * @version 1.0
 * @since 2.0
 */
declare
  l_result text := '';
  l_authors text := '';
  l_doc_data jsonb := aschema->'doc_data';
begin
  l_result := l_result || '<section id="schema"><h2>'||(alocation->>'schema')||'</h2>';
  l_result := l_result || '<a name="'||(aschema->>'schema_name')||'"></a>';
  --
  if l_doc_data->>'root' is not null then
    l_result := l_result || (l_doc_data->>'root');
  elsif aschema->>'description' is not null then
    l_result := l_result || (aschema->>'description');
  end if;
  --
  --raise debug '% %', (aroutine->>'routine_name'), length(l_result);
  l_result := l_result || gendoc.html_doc_data_prop(l_doc_data, alocation);
  l_result := l_result || gendoc.html_doc_data_uni(l_doc_data, alocation);
  --
  l_result := l_result || '</section>';
  --
  return l_result;
end;
$$;


--
-- TOC entry 403 (class 1255 OID 27518)
-- Name: html_series_toc(jsonb, character varying); Type: FUNCTION; Schema: gendoc; Owner: -
--

CREATE FUNCTION gendoc.html_series_toc(aitems jsonb, aname character varying) RETURNS text
    LANGUAGE plpgsql IMMUTABLE
    AS $$
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
$$;


--
-- TOC entry 3553 (class 0 OID 0)
-- Dependencies: 403
-- Name: FUNCTION html_series_toc(aitems jsonb, aname character varying); Type: COMMENT; Schema: gendoc; Owner: -
--

COMMENT ON FUNCTION gendoc.html_series_toc(aitems jsonb, aname character varying) IS 'Create table of content from jsonb array as HTML code';


--
-- TOC entry 306 (class 1255 OID 27565)
-- Name: html_table(jsonb, jsonb); Type: FUNCTION; Schema: gendoc; Owner: -
--

CREATE FUNCTION gendoc.html_table(atable jsonb, alocation jsonb) RETURNS text
    LANGUAGE plpgsql IMMUTABLE
    AS $$
/**
 * Create one table html section
 *
 * @param {jsonb} atable tabl
 * @param {jsonb} alocation tarnslation strings
 * @returns {text}
 * 
 * @author Andrzej Kałuża
 * @created 2025-01-27
 * @version 1.0
 * @since 2.0
 */
declare
  l_result text := '';
  l_authors text := '';
  l_doc_data jsonb := atable->'doc_data';
begin
  l_result := l_result || '<section>';
  l_result := l_result || '<a name="'||(atable->>'table_name')||'"></a>';
  l_result := l_result || '<h3>'||(atable->>'table_name')||' <small>('||(atable->>'kind')||')</small></h3>';
  --
  if l_doc_data->>'root' is not null then
    l_result := l_result || '<p>'||replace(l_doc_data->>'root', e'\n', '<br />')||'</p>';
  elsif atable->>'description' is not null then
    l_result := l_result || '<p>'||replace(atable->>'description', e'\n', '<br />')||'</p>';
  end if;
  --
  l_result := l_result || '<h4>'||(alocation->>'table_columns')||'</h4>';
  l_result := l_result || '<table>';
  l_result := l_result || 
    '<thead><tr>'||
      '<th>'||(alocation->>'column_no_th')||'</th><th>'||(alocation->>'column_name_th')||'</th><th>'||(alocation->>'data_type_th')||'</th>'||
      '<th>'||(alocation->>'default_value_th')||'</th><th>'||(alocation->>'nullable_th')||'</th>'||
      '<th>'||(alocation->>'primary_key_th')||'</th><th>'||(alocation->>'foreign_key_th')||'</th>'||
      '<th>'||(alocation->>'description_th')||'</th>'||
    '</tr></thead>';
  l_result := l_result || '<tbody>';
  l_result := l_result || 
    string_agg(
      '<tr>'||
        '<td>'||(c->>'column_no')||'</td><td>'||(c->>'column_name')||'</td><td>'||(c->>'data_type')||
        '</td><td>'||coalesce(c->>'default_value', '')||'</td><td>'||(c->>'nullable')||
        '</td><td>'||(c->>'primary_key')||'</td><td>'||(c->>'foreign_key')||
        '</td><td>'||coalesce((c->>'description'), '')||'</td>'||
      '</tr>',
    '' order by (c->>'column_no')::numeric) cols from jsonb_array_elements(atable->'columns') c;
  l_result := l_result || '</tbody></table>';
  --
  l_result := l_result || gendoc.html_doc_data_uni(l_doc_data, alocation);
  --
  l_result := l_result || '</section>';
  --
  return l_result;
end;
$$;


--
-- TOC entry 326 (class 1255 OID 27531)
-- Name: html_tables(jsonb, jsonb); Type: FUNCTION; Schema: gendoc; Owner: -
--

CREATE FUNCTION gendoc.html_tables(atables jsonb, alocation jsonb) RETURNS text
    LANGUAGE plpgsql IMMUTABLE
    AS $$
/**
 * Create tables html section
 *
 * @param {jsonb} atables tables series
 * @param {jsonb} alocation tarnslation strings
 * @returns {text}
 * 
 * @author Andrzej Kałuża
 * @created 2025-01-26
 * @version 1.0
 * @since 2.0
 */
declare
  l_result text := '';
begin
  l_result := l_result || '<section id="tables"><h2>'||(alocation->>'tables')||'</h2>';
  l_result := l_result || (select string_agg(gendoc.html_table(t, alocation), '' order by t->>'table_name') from jsonb_array_elements(atables) t);
  l_result := l_result || '</section>';
  --
  return l_result;
end;
$$;


--
-- TOC entry 3554 (class 0 OID 0)
-- Dependencies: 326
-- Name: FUNCTION html_tables(atables jsonb, alocation jsonb); Type: COMMENT; Schema: gendoc; Owner: -
--

COMMENT ON FUNCTION gendoc.html_tables(atables jsonb, alocation jsonb) IS 'Create tables html section';


--
-- TOC entry 402 (class 1255 OID 27628)
-- Name: html_view(jsonb, jsonb); Type: FUNCTION; Schema: gendoc; Owner: -
--

CREATE FUNCTION gendoc.html_view(aview jsonb, alocation jsonb) RETURNS text
    LANGUAGE plpgsql IMMUTABLE
    AS $$
/**
 * Create one view html section
 *
 * @param {jsonb} aview view
 * @param {jsonb} alocation tarnslation strings
 * @returns {text}
 * 
 * @author Andrzej Kałuża
 * @created 2025-01-97
 * @version 1.0
 * @since 2.0
 */
declare
  l_result text := '';
  l_authors text := '';
  l_doc_data jsonb := aview->'doc_data';
begin
  l_result := l_result || '<section>';
  l_result := l_result || '<a name="'||(aview->>'view_name')||'"></a>';
  l_result := l_result || '<h3>'||(aview->>'view_name')||' <small>('||(aview->>'kind')||')</small></h3>';
  --
  if l_doc_data->>'root' is not null then
    l_result := l_result || '<p>'||replace(l_doc_data->>'root', e'\n', '<br />')||'</p>';
  elsif aview->>'description' is not null then
    l_result := l_result || '<p>'||replace(aview->>'description', e'\n', '<br />')||'</p>';
  end if;
  --
  l_result := l_result || '<h4>'||(alocation->>'view_columns')||'</h4>';
  l_result := l_result || '<table>';
  l_result := l_result || 
    '<thead><tr>'||
      '<th>'||(alocation->>'column_no_th')||'</th><th>'||(alocation->>'column_name_th')||'</th><th>'||(alocation->>'data_type_th')||'</th>'||
      '<th>'||(alocation->>'description_th')||'</th>'||
    '</tr></thead>';
  l_result := l_result || '<tbody>';
  --raise debug '% %', (aview->>'view_name'), length(l_result);
  l_result := l_result || 
    string_agg(
      '<tr>'||
        '<td>'||(c->>'column_no')||'</td><td>'||(c->>'column_name')||'</td><td>'||(c->>'data_type')||
        '</td><td>'||coalesce((c->>'description'), '')||'</td>'||
      '</tr>',
    '' order by (c->>'column_no')::numeric) cols from jsonb_array_elements(aview->'columns') c;
  l_result := l_result || '</tbody></table>';
  --
  l_result := l_result || gendoc.html_doc_data_uni(l_doc_data, alocation);
  --
  l_result := l_result || '</section>';
  --
  return l_result;
end;
$$;


--
-- TOC entry 399 (class 1255 OID 27627)
-- Name: html_views(jsonb, jsonb); Type: FUNCTION; Schema: gendoc; Owner: -
--

CREATE FUNCTION gendoc.html_views(aviews jsonb, alocation jsonb) RETURNS text
    LANGUAGE plpgsql IMMUTABLE
    AS $$
/**
 * Create views html section
 *
 * @param {jsonb} atables views series
 * @param {jsonb} alocation tarnslation strings
 * @returns {text}
 * 
 * @author Andrzej Kałuża
 * @created 2025-01-29
 * @version 1.0
 * @since 2.0
 */
declare
  l_result text := '';
begin
  l_result := l_result || '<section id="views"><h2>'||(alocation->>'views')||'</h2>';
  l_result := l_result || (select string_agg(gendoc.html_view(t, alocation), '' order by t->>'view_name') from jsonb_array_elements(aviews) t);
  l_result := l_result || '</section>';
  --
  return l_result;
end;
$$;


--
-- TOC entry 366 (class 1255 OID 27493)
-- Name: is_private_routine(name, text); Type: FUNCTION; Schema: gendoc; Owner: -
--

CREATE FUNCTION gendoc.is_private_routine(aschema name, aroutine text) RETURNS boolean
    LANGUAGE plpgsql
    AS $$
/**
 * Check is routine is set as private. If not set as private, returns false.
 *
 * @param {name} aschema schema name
 * @param {text} aroutine routine identity name
 * @returns {boolean}
 *
 * @author Andrzej Kałuża
 * @created 2025-01-25
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
  return coalesce((l_doc->'private')::boolean or l_doc->>'access' = 'private', not ((l_doc->'public')::boolean or l_doc->>'access' = 'public'));
end;
$$;


--
-- TOC entry 3555 (class 0 OID 0)
-- Dependencies: 366
-- Name: FUNCTION is_private_routine(aschema name, aroutine text); Type: COMMENT; Schema: gendoc; Owner: -
--

COMMENT ON FUNCTION gendoc.is_private_routine(aschema name, aroutine text) IS 'Check is routine is set as private. If not set as private, returns false.';


--
-- TOC entry 387 (class 1255 OID 27492)
-- Name: is_public_routine(name, text); Type: FUNCTION; Schema: gendoc; Owner: -
--

CREATE FUNCTION gendoc.is_public_routine(aschema name, aroutine text) RETURNS boolean
    LANGUAGE plpgsql
    AS $$
/**
 * Check is routine is set as public. If not set as public, function returns true
 *
 * @param {name} aschema schema name
 * @param {text} aroutine routine identity name
 * @returns {boolean}
 *
 * @author Andrzej Kałuża
 * @created 2025-01-25
 * @version 1.0
 * @since 2.0
 */
declare
  l_doc jsonb;
begin
  l_doc := gendoc.get_routine_doc(aschema, aroutine);
  --
  if l_doc is null then
    return true;
  end if;
  --
  return coalesce((l_doc->'public')::boolean, not (l_doc->'private')::boolean, l_doc->>'access' = 'public', l_doc->>'access' != 'private');
end;
$$;


--
-- TOC entry 3556 (class 0 OID 0)
-- Dependencies: 387
-- Name: FUNCTION is_public_routine(aschema name, aroutine text); Type: COMMENT; Schema: gendoc; Owner: -
--

COMMENT ON FUNCTION gendoc.is_public_routine(aschema name, aroutine text) IS 'Check is routine is set as public. If not set as public, function returns true';


--
-- TOC entry 388 (class 1255 OID 27495)
-- Name: is_test_routine(name, text); Type: FUNCTION; Schema: gendoc; Owner: -
--

CREATE FUNCTION gendoc.is_test_routine(aschema name, aroutine text) RETURNS boolean
    LANGUAGE plpgsql
    AS $$
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
$$;


--
-- TOC entry 3557 (class 0 OID 0)
-- Dependencies: 388
-- Name: FUNCTION is_test_routine(aschema name, aroutine text); Type: COMMENT; Schema: gendoc; Owner: -
--

COMMENT ON FUNCTION gendoc.is_test_routine(aschema name, aroutine text) IS 'Check is routine is set as test.';


--
-- TOC entry 364 (class 1255 OID 27421)
-- Name: jsdoc_parse(character varying); Type: FUNCTION; Schema: gendoc; Owner: -
--

CREATE FUNCTION gendoc.jsdoc_parse(str character varying) RETURNS jsonb
    LANGUAGE plpgsql STABLE
    AS $_$
/**
 * Function parse jsdoc and returns jsonb structure<br />
 * Function remove comment characters from string.
 * 
 * @summary parse jsdoc
 * 
 * @author cmtdoc parser (https://github.com/grobinx/cmtdoc-parser)
 * @created Wed Jan 29 2025 17:25:24 GMT+0100 (czas środkowoeuropejski standardowy)
 * @version 1.1.12
 * 
 * @param {varchar|text} str string to parse
 * @returns {jsonb}
 * @example
 * select p.proname, jsdoc_parse(p.doc) as doc, p.arguments, p.description
 *   from (select p.proname, substring(p.prosrc from '\/\*\*.*\*\/') as doc, 
 *                coalesce(pg_get_function_arguments(p.oid), '') arguments,
 *                d.description
 *           from pg_proc p
 *                join pg_namespace n on n.oid = p.pronamespace
 *                left join pg_description d on d.classoid = 'pg_proc'::regclass and d.objoid = p.oid and d.objsubid = 0
 *          where n.nspname = :scema_name
 *            and p.prokind in ('p', 'f')) p
 *  where p.doc is not null
 */
declare
  l_figures text[];
begin
  if position('/**' in str) then
    str := string_agg(substring(line from '^\s*\*\s(.*)'), e'\n')
      from (select unnest(string_to_array(str, e'\n')) line) d
     where trim(line) not in ('/**', '*/');
  end if;
  --
  l_figures := array_agg(distinct f) from (select unnest(regexp_matches(str, '@(\w+)', 'g')) f) u;
  --
  return jsonb_object_agg(r.figure, r.object)
    from (    -- This is root description
    select 'root' as figure, to_jsonb(trim(e' \t\n\r' from r[1])) as object
      from regexp_matches(str, '^([^@]+)') r
    union all
    -- @param|arg|argument [{type}] name|[name=value] [description]
    select 'param' as figure, jsonb_agg(row_to_json(r)::jsonb) as object
      from (select trim(e' \t\n\r' from r[3]) as "type", trim(e' \t\n\r' from coalesce(trim(e' \t\n\r' from r[7]), trim(e' \t\n\r' from r[11]))) as "name", trim(e' \t\n\r' from r[9]) as "default", trim(e' \t\n\r' from r[13]) as "description", string_to_array(trim(e' \t\n\r' from trim(e' \t\n\r' from r[3])), '|') as "types"
              from regexp_matches(str, '@(param|arg|argument)(\s*{([^{]*)?})?((\s*\[(([^\[\=]+)\s*(\=\s*([^\[]*)?)?)?\])|(\s+([^\s@)<{}]+)))(\s*([^@]*)?)?', 'g') r) r
     where array['param', 'arg', 'argument'] && l_figures
    having jsonb_agg(row_to_json(r)::jsonb) is not null
    union all
    -- @property|prop [{type}] name|[name=value] [description]
    select 'property' as figure, jsonb_agg(row_to_json(r)::jsonb) as object
      from (select trim(e' \t\n\r' from r[3]) as "type", trim(e' \t\n\r' from coalesce(trim(e' \t\n\r' from r[7]), trim(e' \t\n\r' from r[11]))) as "name", trim(e' \t\n\r' from r[9]) as "default", trim(e' \t\n\r' from r[13]) as "description", string_to_array(trim(e' \t\n\r' from trim(e' \t\n\r' from r[3])), '|') as "types", string_to_array(trim(e' \t\n\r' from trim(e' \t\n\r' from coalesce(r[7], r[11]))), '.') as "names"
              from regexp_matches(str, '@(property|prop)[[:>:]](\s*{([^{]*)?})?((\s*\[(([^\[\=]+)\s*(\=\s*([^\[]*)?)?)?\])|(\s+([^\s@)<{}]+)))(\s*([^@]*)?)?', 'g') r) r
     where array['property', 'prop'] && l_figures
    having jsonb_agg(row_to_json(r)::jsonb) is not null
    union all
    -- @ignore
    select 'ignore' as figure, to_jsonb(true) as object
      from regexp_matches(str, '@(ignore)[[:>:]]\s*(\n|$)') r
     where 'ignore' = any (l_figures)
    union all
    -- @override
    select 'override' as figure, to_jsonb(true) as object
      from regexp_matches(str, '@(override)[[:>:]]\s*(\n|$)') r
     where 'override' = any (l_figures)
    union all
    -- @public
    select 'public' as figure, to_jsonb(true) as object
      from regexp_matches(str, '@(public)[[:>:]]\s*(\n|$)') r
     where 'public' = any (l_figures)
    union all
    -- @readonly
    select 'readonly' as figure, to_jsonb(true) as object
      from regexp_matches(str, '@(readonly)[[:>:]]\s*(\n|$)') r
     where 'readonly' = any (l_figures)
    union all
    -- @alias path [description]
    select 'alias' as figure, row_to_json(r)::jsonb as object
      from (select trim(e' \t\n\r' from r[3]) as "path", trim(e' \t\n\r' from r[5]) as "description"
              from regexp_matches(str, '@(alias)(\s+([^\s@)<{}]+))(\s*([^@]*)?)?') r) r
     where 'alias' = any (l_figures)
    union all
    -- @author author [<email@address>] [(http-page)] [- description]
    select 'author' as figure, jsonb_agg(row_to_json(r)::jsonb) as object
      from (select trim(e' \t\n\r' from r[3]) as "author", trim(e' \t\n\r' from r[5]) as "email", trim(e' \t\n\r' from r[7]) as "page", trim(e' \t\n\r' from r[10]) as "description"
              from regexp_matches(str, '@(author)(\s+([^@\-<{\(]+))(\s*<([^<]*)>)?(\s*\(([^\(]*)\))?(\s*\-(\s*([^@]*)?)?)?', 'g') r) r
     where 'author' = any (l_figures)
    having jsonb_agg(row_to_json(r)::jsonb) is not null
    union all
    -- @borrows thas_namepath as this_namepath [description]
    select 'borrows' as figure, row_to_json(r)::jsonb as object
      from (select trim(e' \t\n\r' from r[3]) as "that", trim(e' \t\n\r' from r[5]) as "this", trim(e' \t\n\r' from r[7]) as "description"
              from regexp_matches(str, '@(borrows)(\s+([^\s@)<{}]+))\s*as\s*(\s+([^\s@)<{}]+))(\s*([^@]*)?)?') r) r
     where 'borrows' = any (l_figures)
    union all
    -- @constatnt|const {type} [name]
    select 'constant' as figure, row_to_json(r)::jsonb as object
      from (select trim(e' \t\n\r' from r[3]) as "type", trim(e' \t\n\r' from r[5]) as "name"
              from regexp_matches(str, '@(constant|const)(\s*{([^{]*)?})(\s+([^\s@)<{}]+))?') r) r
     where array['constatnt', 'const'] && l_figures
    union all
    -- @copyright some copyright text
    select 'copyright' as figure, to_jsonb(trim(e' \t\n\r' from r[3])) as object
      from regexp_matches(str, '@(copyright)(\s*([^@]*)?)') r
     where 'copyright' = any (l_figures)
    union all
    -- @deprecated some text
    select 'deprecated' as figure, to_jsonb(trim(e' \t\n\r' from r[3])) as object
      from regexp_matches(str, '@(deprecated)(\s*([^@]*)?)') r
     where 'deprecated' = any (l_figures)
    union all
    -- @deprecated
    select 'deprecated' as figure, to_jsonb(true) as object
      from regexp_matches(str, '@(deprecated)[[:>:]]\s*(\n|$)') r
     where 'deprecated' = any (l_figures)
    union all
    -- @description|desc|classdesc some description
    select 'description' as figure, to_jsonb(array_agg(r[3])) as object
      from regexp_matches(str, '@(description|desc|classdesc)[[:>:]](\s*([^@]*)?)', 'g') r
     where array['description', 'desc', 'classdesc'] && l_figures
    having array_agg(r[3]) is not null
    union all
    -- @enum {type} [name]
    select 'enum' as figure, row_to_json(r)::jsonb as object
      from (select trim(e' \t\n\r' from r[3]) as "type", trim(e' \t\n\r' from r[5]) as "name"
              from regexp_matches(str, '@(enum)(\s*{([^{]*)?})(\s+([^\s@)<{}]+))?') r) r
     where 'enum' = any (l_figures)
    union all
    -- @enum
    select 'enum' as figure, to_jsonb(true) as object
      from regexp_matches(str, '@(enum)[[:>:]]\s*(\n|$)') r
     where 'enum' = any (l_figures)
    union all
    -- @example multiline example, code, comments, etc
    select 'example' as figure, to_jsonb(array_agg(r[2])) as object
      from regexp_matches(str, '@(example)(\s*([^@]*)?)', 'g') r
     where 'example' = any (l_figures)
    having array_agg(r[2]) is not null
    union all
    -- @function|func|method name
    select 'function' as figure, to_jsonb(trim(e' \t\n\r' from r[3])) as object
      from regexp_matches(str, '@(function|func|method)[[:>:]](\s+([^\s@)<{}]+))') r
     where array['function', 'func', 'method'] && l_figures
    union all
    -- @function|func|method
    select 'function' as figure, to_jsonb(true) as object
      from regexp_matches(str, '@(function|func|method)[[:>:]]\s*(\n|$)') r
     where array['function', 'func', 'method'] && l_figures
    union all
    -- @created date
    select 'created' as figure, to_jsonb(trim(e' \t\n\r' from r[3])) as object
      from regexp_matches(str, '@(created)(\s*([^@]*)?)') r
     where 'created' = any (l_figures)
    union all
    -- @license identifier|standalone multiline text
    select 'license' as figure, to_jsonb(trim(e' \t\n\r' from r[3])) as object
      from regexp_matches(str, '@(license)(\s*([^@]*)?)') r
     where 'license' = any (l_figures)
    union all
    -- @member|var|variable {type} [name]
    select 'variable' as figure, row_to_json(r)::jsonb as object
      from (select trim(e' \t\n\r' from r[3]) as "type", trim(e' \t\n\r' from r[5]) as "name"
              from regexp_matches(str, '@(var|variable|member)[[:>:]](\s*{([^{]*)?})(\s+([^\s@)<{}]+))?') r) r
     where array['member', 'var', 'variable'] && l_figures
    union all
    -- @module
    select 'module' as figure, to_jsonb(true) as object
      from regexp_matches(str, '@(module)[[:>:]]\s*(\n|$)') r
     where 'module' = any (l_figures)
    union all
    -- @package name
    select 'package' as figure, to_jsonb(trim(e' \t\n\r' from r[3])) as object
      from regexp_matches(str, '@(package)(\s+([^\s@)<{}]+))') r
     where 'package' = any (l_figures)
    union all
    -- @private
    select 'private' as figure, to_jsonb(true) as object
      from regexp_matches(str, '@(private)[[:>:]]\s*(\n|$)') r
     where 'private' = any (l_figures)
    union all
    -- @requires module_name
    select 'requires' as figure, to_jsonb(array_agg(r[3])) as object
      from regexp_matches(str, '@(requires)(\s+([^\s@)<{}]+))', 'g') r
     where 'requires' = any (l_figures)
    having array_agg(r[3]) is not null
    union all
    -- @return|returns {type} [description]
    select 'returns' as figure, row_to_json(r)::jsonb as object
      from (select trim(e' \t\n\r' from r[3]) as "type", trim(e' \t\n\r' from r[5]) as "description", string_to_array(trim(e' \t\n\r' from trim(e' \t\n\r' from r[3])), '|') as "types"
              from regexp_matches(str, '@(returns|return)[[:>:]](\s*{([^{]*)?})(\s*([^@]*)?)?') r) r
     where array['return', 'returns'] && l_figures
    union all
    -- @see {@link namepath}|namepath [description]
    select 'see' as figure, jsonb_agg(row_to_json(r)::jsonb) as object
      from (select trim(e' \t\n\r' from coalesce(trim(e' \t\n\r' from r[4]), trim(e' \t\n\r' from r[6]))) as "path", trim(e' \t\n\r' from r[8]) as "description"
              from regexp_matches(str, '@(see)((\s*{([^{]*)?})|(\s+([^\s@)<{}]+)))(\s*([^@]*)?)?', 'g') r) r
     where 'see' = any (l_figures)
    having jsonb_agg(row_to_json(r)::jsonb) is not null
    union all
    -- @since version
    select 'since' as figure, to_jsonb(trim(e' \t\n\r' from r[3])) as object
      from regexp_matches(str, '@(since)(\s*([^@]*)?)') r
     where 'since' = any (l_figures)
    union all
    -- @summary description
    select 'summary' as figure, to_jsonb(trim(e' \t\n\r' from r[3])) as object
      from regexp_matches(str, '@(summary)(\s*([^@]*)?)') r
     where 'summary' = any (l_figures)
    union all
    -- @throws|exception {type} [description]
    select 'throws' as figure, jsonb_agg(row_to_json(r)::jsonb) as object
      from (select trim(e' \t\n\r' from r[3]) as "type", trim(e' \t\n\r' from r[5]) as "description"
              from regexp_matches(str, '@(throws|exception)(\s*{([^{]*)?})?(\s*([^@]*)?)?', 'g') r) r
     where array['throws', 'exception'] && l_figures
    having jsonb_agg(row_to_json(r)::jsonb) is not null
    union all
    -- @todo text describing thing to do.
    select 'todo' as figure, to_jsonb(array_agg(r[3])) as object
      from regexp_matches(str, '@(todo)(\s*([^@]*)?)', 'g') r
     where 'todo' = any (l_figures)
    having array_agg(r[3]) is not null
    union all
    -- @tutorial {@link path}|name
    select 'tutorial' as figure, to_jsonb(array_agg(r[4])) as object
      from regexp_matches(str, '@(tutorial)((\s*{([^{]*)?})|(\s+([^\s@)<{}]+)))', 'g') r
     where 'tutorial' = any (l_figures)
    having array_agg(r[4]) is not null
    union all
    -- @variation number
    select 'variation' as figure, to_jsonb(trim(e' \t\n\r' from r[3])) as object
      from regexp_matches(str, '@(variation)[[:>:]](\s+([^\s@)<{}]+))') r
     where 'variation' = any (l_figures)
    union all
    -- @version version
    select 'version' as figure, to_jsonb(trim(e' \t\n\r' from r[3])) as object
      from regexp_matches(str, '@(version)[[:>:]](\s*([^@]*)?)') r
     where 'version' = any (l_figures)
    union all
    -- @yield|yields|next [{type}] [description]
    select 'yield' as figure, row_to_json(r)::jsonb as object
      from (select trim(e' \t\n\r' from r[3]) as "type", trim(e' \t\n\r' from r[5]) as "description"
              from regexp_matches(str, '@(yield|yields|next)[[:>:]](\s*{([^{]*)?})?(\s*([^@]*)?)?') r) r
     where array['yield', 'yields', 'next'] && l_figures
    union all
    -- @change|changed|changelog|modified [date|version] [<author>] [description]
    select 'change' as figure, jsonb_agg(row_to_json(r)::jsonb) as object
      from (select trim(e' \t\n\r' from r[3]) as "date", trim(e' \t\n\r' from r[5]) as "author", trim(e' \t\n\r' from r[7]) as "description"
              from regexp_matches(str, '@(change|changed|changelog|modified)[[:>:]](\s+([^\s@)<{}]+))?(\s*<([^<]*)>)?(\s*([^@]*)?)?', 'g') r) r
     where array['change', 'changed', 'changelog', 'modified'] && l_figures
    having jsonb_agg(row_to_json(r)::jsonb) is not null
    union all
    -- @isue some description
    select 'isue' as figure, to_jsonb(array_agg(r[3])) as object
      from regexp_matches(str, '@(isue)(\s*([^@]*)?)', 'g') r
     where 'isue' = any (l_figures)
    having array_agg(r[3]) is not null
    union all
    -- @test
    select 'test' as figure, to_jsonb(true) as object
      from regexp_matches(str, '@(test)[[:>:]]\s*(\n|$)') r
     where 'test' = any (l_figures)
    union all
    -- @column {type} name [description]
    select 'column' as figure, jsonb_agg(row_to_json(r)::jsonb) as object
      from (select trim(e' \t\n\r' from r[3]) as "type", trim(e' \t\n\r' from r[5]) as "name", trim(e' \t\n\r' from r[7]) as "description"
              from regexp_matches(str, '@(column)(\s*{([^{]*)?})?(\s+([^\s@)<{}]+))(\s*([^@]*)?)?', 'g') r) r
     where 'column' = any (l_figures)
    having jsonb_agg(row_to_json(r)::jsonb) is not null
    union all
    -- @table {type} name [description]
    select 'table' as figure, jsonb_agg(row_to_json(r)::jsonb) as object
      from (select trim(e' \t\n\r' from r[3]) as "type", trim(e' \t\n\r' from r[5]) as "name", trim(e' \t\n\r' from r[7]) as "description"
              from regexp_matches(str, '@(table)(\s*{([^{]*)?})?(\s+([^\s@)<{}]+))(\s*([^@]*)?)?', 'g') r) r
     where 'table' = any (l_figures)
    having jsonb_agg(row_to_json(r)::jsonb) is not null
    union all
    -- @view {type} name [description]
    select 'view' as figure, jsonb_agg(row_to_json(r)::jsonb) as object
      from (select trim(e' \t\n\r' from r[3]) as "type", trim(e' \t\n\r' from r[5]) as "name", trim(e' \t\n\r' from r[7]) as "description"
              from regexp_matches(str, '@(view)(\s*{([^{]*)?})?(\s+([^\s@)<{}]+))(\s*([^@]*)?)?', 'g') r) r
     where 'view' = any (l_figures)
    having jsonb_agg(row_to_json(r)::jsonb) is not null
    union all
    -- @sequence|generator name [description]
    select 'sequence' as figure, jsonb_agg(row_to_json(r)::jsonb) as object
      from (select trim(e' \t\n\r' from r[3]) as "name", trim(e' \t\n\r' from r[5]) as "description"
              from regexp_matches(str, '@(sequence|generator)(\s+([^\s@)<{}]+))(\s*([^@]*)?)?', 'g') r) r
     where array['sequence', 'generator'] && l_figures
    having jsonb_agg(row_to_json(r)::jsonb) is not null) r;
end;
$_$;


--
-- TOC entry 370 (class 1255 OID 27528)
-- Name: markdown(name, jsonb); Type: FUNCTION; Schema: gendoc; Owner: -
--

CREATE FUNCTION gendoc.markdown(aschema name, aoptions jsonb DEFAULT NULL::jsonb) RETURNS text
    LANGUAGE plpgsql
    AS $$
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
$$;


--
-- TOC entry 414 (class 1255 OID 27527)
-- Name: md_create_toc(jsonb, jsonb, jsonb, jsonb); Type: FUNCTION; Schema: gendoc; Owner: -
--

CREATE FUNCTION gendoc.md_create_toc(aroutines jsonb, atables jsonb, aviews jsonb, alocation jsonb) RETURNS text
    LANGUAGE plpgsql IMMUTABLE
    AS $$
/**
 * Create table of content for all series
 *
 * Level 1
 *
 * @summary toc for all objects
 * 
 * @param {jsonb} aroutines routines series
 * @param {jsonb} atables tables series
 * @param {jsonb} aviews views series
 * @param {jsonb} alocation tarnslation strings
 * @returns {text}
 * 
 * @author Andrzej Kałuża
 * @created 2025-01-26
 * @version 1.0
 * @since 2.0
 */
declare
  l_result text := '';
begin
  l_result := l_result || e'\n\n## '||(alocation->>'toc')||e'\n\n';
  if aroutines is not null then
    l_result := l_result || '1. ['||(alocation->>'routines')||'](#'||replace(alocation->>'routines', ' ', '-')||')'||e'\n';
    l_result := l_result || gendoc.md_series_toc(aroutines, 'routine_name')||e'\n';
  end if;
  if atables is not null then
    l_result := l_result || '2. ['||(alocation->>'tables')||'](#'||(alocation->>'tables')||')'||e'\n';
    l_result := l_result || gendoc.md_series_toc(atables, 'table_name')||e'\n';
  end if;
  if aviews is not null then
    l_result := l_result || '3. ['||(alocation->>'views')||'](#'||(alocation->>'views')||')'||e'\n';
    l_result := l_result || gendoc.md_series_toc(aviews, 'view_name')||e'\n';
  end if;
  --
  return l_result;
end;
$$;


--
-- TOC entry 3558 (class 0 OID 0)
-- Dependencies: 414
-- Name: FUNCTION md_create_toc(aroutines jsonb, atables jsonb, aviews jsonb, alocation jsonb); Type: COMMENT; Schema: gendoc; Owner: -
--

COMMENT ON FUNCTION gendoc.md_create_toc(aroutines jsonb, atables jsonb, aviews jsonb, alocation jsonb) IS 'Create table of content for all series';


--
-- TOC entry 405 (class 1255 OID 27636)
-- Name: md_doc_data_param(jsonb, jsonb, jsonb); Type: FUNCTION; Schema: gendoc; Owner: -
--

CREATE FUNCTION gendoc.md_doc_data_param(adoc_data jsonb, aarguments jsonb, alocation jsonb) RETURNS text
    LANGUAGE plpgsql IMMUTABLE
    AS $$
/**
 * Creates a collection of information from doc_data about parameters
 *
 * @param {jsonb} adoc_data doc data
 * @param {jsonb} aarguments routine arguments
 * @param {jsonb} alocation tarnslation strings
 * @returns {text}
 * 
 * @author Andrzej Kałuża
 * @created 2025-01-29
 * @version 1.0
 * @since 2.0
 */
declare
  l_result text := '';
begin
  if adoc_data->'param' is not null or jsonb_array_length(aarguments) > 0 then    
    l_result := l_result || e'\n\n#### '||(alocation->>'arguments');
    l_result := l_result || e'\n\n'
      '|'||(alocation->>'argument_no_th')||'|'||(alocation->>'argument_name_th')||
      '|'||(alocation->>'data_type_th')||'|'||(alocation->>'default_value_th')||
      '|'||(alocation->>'mode_th')||'|'||(alocation->>'description_th')||'|'||
      e'\n|---:|----|----|----|----|----|';
    --
    l_result := l_result ||
      string_agg(e'\n'
         '|'||coalesce(ra->>'argument_no', '')||'|'||coalesce(ra->>'argument_name', rp->>'name')||
         '|'||coalesce(ra->>'data_type', rp->>'type')||'|'||coalesce(ra->>'default_value', rp->>'default', '')||
         '|'||coalesce(ra->>'mode', '')||'|'||coalesce(rp->>'description', '')||'|',
       '' order by (ra->>'argument_no')::numeric, coalesce(ra->>'argument_name', rp->>'name'))
      from jsonb_array_elements(aarguments) ra 
           full join jsonb_array_elements(adoc_data->'param') rp on rp->>'name' = ra->>'argument_name';
  end if;
  --
  return l_result;
end;
$$;


--
-- TOC entry 406 (class 1255 OID 27637)
-- Name: md_doc_data_prop(jsonb, jsonb); Type: FUNCTION; Schema: gendoc; Owner: -
--

CREATE FUNCTION gendoc.md_doc_data_prop(adoc_data jsonb, alocation jsonb) RETURNS text
    LANGUAGE plpgsql IMMUTABLE
    AS $$
/**
 * Creates a collection of information from doc_data about properties
 *
 * @param {jsonb} adoc_data tabl
 * @param {jsonb} alocation tarnslation strings
 * @returns {text}
 * 
 * @author Andrzej Kałuża
 * @created 2025-01-28
 * @version 1.0
 * @since 2.0
 */
declare
  l_result text := '';
begin
  if adoc_data->'property' is not null then
    l_result := l_result || e'\n\n#### '||(alocation->>'propeties');
    l_result := l_result || e'\n\n'
      '|'||(alocation->>'name_th')||'|'||(alocation->>'data_type_th')||
      '|'||(alocation->>'default_value_th')||'|'||(alocation->>'description_th')||'|'||
      e'\n|----|----|----|----|';
    --
    l_result := l_result || 
      string_agg(e'\n'||
        '|'||coalesce(v->>'name', '')||'|'||coalesce(v->>'type', '')||
        '|'||coalesce(v->>'default', '')||'|'||coalesce(v->>'description', '')||'|',
      '')
      from jsonb_array_elements(adoc_data->'property') v;
  end if;
  --
  return l_result;
end;
$$;


--
-- TOC entry 407 (class 1255 OID 27632)
-- Name: md_doc_data_uni(jsonb, jsonb); Type: FUNCTION; Schema: gendoc; Owner: -
--

CREATE FUNCTION gendoc.md_doc_data_uni(adoc_data jsonb, alocation jsonb) RETURNS text
    LANGUAGE plpgsql IMMUTABLE
    AS $_$
/**
 * Creates a collection of information from doc_data
 *
 * @param {jsonb} adoc_data tabl
 * @param {jsonb} alocation tarnslation strings
 * @returns {text}
 * 
 * @author Andrzej Kałuża
 * @created 2025-01-29
 * @version 1.0
 * @since 2.0
 */
declare
  l_result text := '';
begin
  if adoc_data is not null then
    l_result := l_result || e'\n';
    if adoc_data->'author' is not null then
      l_result := l_result || 
        string_agg(
          e'\n>\n> **'||(alocation->>'author')||'** '||
          coalesce(c->>'author', '')||
          coalesce(' &lt;'||(c->>'email')||'&gt;', '')||
          coalesce(' ('||(c->>'page')||')', '')||
          coalesce(' - '||(c->>'description'), ''), 
        '') from jsonb_array_elements(adoc_data->'author') c;
    end if;
    if adoc_data->'version' is not null then
      l_result := l_result || e'\n>\n> **'||(alocation->>'version')||'** '||(adoc_data->>'version');
    end if;
    if adoc_data->'since' is not null then
      l_result := l_result || e'\n>\n> **'||(alocation->>'since')||'** '||(adoc_data->>'since');
    end if;
    if adoc_data->'created' is not null then
      l_result := l_result || e'\n>\n> **'||(alocation->>'created')||'** '||(adoc_data->>'created');
    end if;
    if adoc_data->'package' is not null then
      l_result := l_result || e'\n>\n> **'||(alocation->>'package')||'** '||(adoc_data->>'package');
    end if;
    if adoc_data->'module' is not null then
      l_result := l_result || e'\n>\n> **'||(alocation->>'module')||'** '||(adoc_data->>'module');
    end if;
    if adoc_data->'public' is not null then
      l_result := l_result || e'\n>\n> **'||(alocation->>'public')||'** '||(adoc_data->>'public');
    end if;
    if adoc_data->'private' is not null then
      l_result := l_result || e'\n>\n> **'||(alocation->>'private')||'** '||(adoc_data->>'private');
    end if;
    if adoc_data->'readonly' is not null then
      l_result := l_result || e'\n>\n> **'||(alocation->>'readonly')||'** '||(adoc_data->>'readonly');
    end if;
    if adoc_data->'alias' is not null then
      l_result := l_result || e'\n>\n> **'||(alocation->>'alias')||'** '||(adoc_data->>'alias');
    end if;
    if adoc_data->'deprecated' is not null then
      l_result := l_result || e'\n>\n> **'||(alocation->>'deprecated')||'** '||(adoc_data->>'deprecated');
    end if;
    if adoc_data->'function' is not null then
      l_result := l_result || e'\n>\n> **'||(alocation->>'function')||'** '||(adoc_data->>'function');
    end if;
    if adoc_data->'variation' is not null then
      l_result := l_result || e'\n>\n> **'||(alocation->>'variation')||'** '||(adoc_data->>'variation');
    end if;
    if adoc_data->'test' is not null then
      l_result := l_result || e'\n>\n> **'||(alocation->>'test')||'** '||(adoc_data->>'test');
    end if;
    if adoc_data->'requires' is not null then
      l_result := l_result || 
        e'\n\n#### '||(alocation->>'requires')||
          (select string_agg(e'\n\n'||x, '') from jsonb_array_elements_text(adoc_data->'requires') x);
    end if;
    if adoc_data->'see' is not null then
      l_result := l_result || 
        e'\n\n#### '||(alocation->>'see')||
          (select string_agg(e'\n\n'||(x->>'path')||coalesce(' '||(x->>'description'), ''), '') from jsonb_array_elements(adoc_data->'see') x);
    end if;
    if adoc_data->'tutorial' is not null then
      l_result := l_result || 
        e'\n\n#### '||(alocation->>'tutorial')||
          (select string_agg(e'\n\n'||x, '') from jsonb_array_elements_text(adoc_data->'tutorial') x);
    end if;
    --
    if adoc_data->'isue' is not null then
      l_result := l_result || 
        e'\n\n#### '||(alocation->>'isue')||
          (select string_agg(e'\n\n'||x, '') from jsonb_array_elements_text(adoc_data->>'isue') x);
    end if;
    --
    if adoc_data->'todo' is not null then
      l_result := l_result || 
        e'\n\n#### '||(alocation->>'todo')||
          (select string_agg(e'\n\n'||x, '') from jsonb_array_elements_text(adoc_data->'todo') x);
    end if;
    --
    if adoc_data->'example' is not null then
      l_result := l_result || 
        e'\n\n#### '||(alocation->>'example')||
          (select string_agg(e'\n\n````sql\n'||trim(e'[ \r\n]+$' from x)||e'\n````', '') from jsonb_array_elements_text(adoc_data->'example') x);
    end if;
    --
    if adoc_data->'change' is not null then
      l_result := l_result || 
        e'\n\n#### '||(alocation->>'changes')||e'\n'||
        (select string_agg(
                  e'\n>\n> '||
                    coalesce((x->>'date'), '')||
                    coalesce(' '||(x->>'author'), '')||
                    coalesce(' - '||(x->>'description'), '')
                  , '')
           from jsonb_array_elements(adoc_data->'change') x);
    end if;
    --
    if adoc_data->'summary' is not null then
      l_result := l_result || e'\n\n#### '||(alocation->>'summary')||e'\n\n'||(adoc_data->>'summary');
    end if;
  end if;
  --
  return l_result;
end;
$_$;


--
-- TOC entry 371 (class 1255 OID 27635)
-- Name: md_routine(jsonb, jsonb); Type: FUNCTION; Schema: gendoc; Owner: -
--

CREATE FUNCTION gendoc.md_routine(aroutine jsonb, alocation jsonb) RETURNS text
    LANGUAGE plpgsql IMMUTABLE
    AS $$
/**
 * Create one routine markdown section
 *
 * @param {jsonb} atable tabl
 * @param {jsonb} alocation tarnslation strings
 * @returns {text}
 * 
 * @author Andrzej Kałuża
 * @created 2025-01-29
 * @version 1.0
 * @since 2.0
 */
declare
  l_result text := '';
  l_authors text := '';
  l_doc_data jsonb := aroutine->'doc_data';
begin
  l_result := l_result || e'\n\n### '||(aroutine->>'routine_name')||' <small>('||(aroutine->>'kind')||')</small>';
  l_result := l_result || 
    e'\n\n<code>'||(aroutine->>'routine_name')||'('||
      coalesce((select string_agg(x->>'argument_name'||case when jsonb_typeof(x->'default_value') != 'null' then '<sup>'||(alocation->>'opt_sup')||'</sup>' else '' end, ', ')
         from jsonb_array_elements(aroutine->'arguments') x), '')||
      ')</code> → <code>'||(aroutine->>'returns_type')||'</code>';
  --
  if l_doc_data->>'root' is not null then
    l_result := l_result || e'\n\n'||replace(l_doc_data->>'root', e'\n', e'\n\n');
  elsif aroutine->>'description' is not null then
    l_result := l_result || e'\n\n'||replace(aroutine->>'description', e'\n', e'\n\n');
  end if;
  --
  l_result := l_result || gendoc.md_doc_data_param(l_doc_data, aroutine->'arguments', alocation);
  l_result := l_result || gendoc.md_doc_data_prop(l_doc_data, alocation);
  l_result := l_result || gendoc.md_doc_data_uni(l_doc_data, alocation);
  --
  if l_doc_data->'column' then
    l_result := l_result || e'\n\n#### '||(alocation->>'columns');
    l_result := l_result || e'\n\n'
        '|'||(alocation->>'name_th')||'|'||(alocation->>'data_type_th', '')||
        '|'||(alocation->>'description_th', '')||'|'||
        '|---:|----|----|';
    l_result := l_result || 
      string_agg(e'\n'||
          '|'||coalesce(c->>'name', '')||'|'||coalesce(c->>'type', '')||
          '|'||coalesce(c->>'description', '')||'|',
      '') cols from jsonb_array_elements(l_doc_data->'column') c;
  end if;
  --
  if aroutine->>'returns' != 'void' then
    l_result := l_result || e'\n\n#### '||(alocation->>'returns');
    if l_doc_data->'returns'->>'description' is not null then
      l_result := l_result || e'\n\n'||(l_doc_data->'returns'->>'description');
    end if;
    l_result := l_result || e'\n\n> **'||(alocation->>'data_type')||'** `'||coalesce(aroutine->>'returns', l_doc_data->'returns'->>'type')||'`';
  end if;
  --raise debug '% %', (aroutine->>'routine_name'), length(l_result);
  --
  return l_result;
end;
$$;


--
-- TOC entry 408 (class 1255 OID 27634)
-- Name: md_routines(jsonb, jsonb); Type: FUNCTION; Schema: gendoc; Owner: -
--

CREATE FUNCTION gendoc.md_routines(aroutines jsonb, alocation jsonb) RETURNS text
    LANGUAGE plpgsql IMMUTABLE
    AS $$
/**
 * Create routines markdown section
 *
 * @param {jsonb} aroutines routine series
 * @param {jsonb} alocation tarnslation strings
 * @returns {text}
 * 
 * @author Andrzej Kałuża
 * @created 2025-01-29
 * @version 1.0
 * @since 2.0
 */
declare
  l_result text := '';
begin
  l_result := l_result || e'\n\n## '||(alocation->>'routines');
  l_result := l_result || (select string_agg(gendoc.md_routine(t, alocation), e'\n\n---' order by t->>'routine_name') from jsonb_array_elements(aroutines) t);
  --
  return l_result;
end;
$$;


--
-- TOC entry 375 (class 1255 OID 27651)
-- Name: md_schema(jsonb, jsonb); Type: FUNCTION; Schema: gendoc; Owner: -
--

CREATE FUNCTION gendoc.md_schema(aschema jsonb, alocation jsonb) RETURNS text
    LANGUAGE plpgsql IMMUTABLE
    AS $$
/**
 * Create schema markdown section
 *
 * @param {jsonb} atable tabl
 * @param {jsonb} alocation tarnslation strings
 * @returns {text}
 * 
 * @author Andrzej Kałuża
 * @created 2025-01-30
 * @version 1.0
 * @since 2.0
 */
declare
  l_result text := '';
  l_authors text := '';
  l_doc_data jsonb := aschema->'doc_data';
begin
  l_result := l_result || e'\n\n## '||(alocation->>'schema');
  --
  if l_doc_data->>'root' is not null then
    l_result := l_result || (l_doc_data->>'root');
  elsif aschema->>'description' is not null then
    l_result := l_result || (aschema->>'description');
  end if;
  --
  --raise debug '% %', (aroutine->>'routine_name'), length(l_result);
  l_result := l_result || gendoc.md_doc_data_prop(l_doc_data, alocation);
  l_result := l_result || gendoc.md_doc_data_uni(l_doc_data, alocation);
  --
  return l_result;
end;
$$;


--
-- TOC entry 390 (class 1255 OID 27519)
-- Name: md_series_toc(jsonb, character varying); Type: FUNCTION; Schema: gendoc; Owner: -
--

CREATE FUNCTION gendoc.md_series_toc(aitems jsonb, aname character varying) RETURNS text
    LANGUAGE plpgsql IMMUTABLE
    AS $$
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
    from (select '    '||(row_number() over (order by j->>aname))||'. [`'||(j->>aname)||'`](#'||(j->>aname)||'-'||(j->>'kind')||')'||
                 coalesce(' '||trim(coalesce((j->'doc_data'->>'summary'), (j->'doc_data'->>'root'), (j->>'description'))), '') line
            from jsonb_array_elements(aitems) j
           order by j->>aname) l;
end;
$$;


--
-- TOC entry 3559 (class 0 OID 0)
-- Dependencies: 390
-- Name: FUNCTION md_series_toc(aitems jsonb, aname character varying); Type: COMMENT; Schema: gendoc; Owner: -
--

COMMENT ON FUNCTION gendoc.md_series_toc(aitems jsonb, aname character varying) IS 'Create table of content from jsonb array as MarkDown code';


--
-- TOC entry 409 (class 1255 OID 27629)
-- Name: md_table(jsonb, jsonb); Type: FUNCTION; Schema: gendoc; Owner: -
--

CREATE FUNCTION gendoc.md_table(atable jsonb, alocation jsonb) RETURNS text
    LANGUAGE plpgsql IMMUTABLE
    AS $$
/**
 * Create one table markdown section
 *
 * @param {jsonb} atable tabl
 * @param {jsonb} alocation tarnslation strings
 * @returns {text}
 * 
 * @author Andrzej Kałuża
 * @created 2025-01-29
 * @version 1.0
 * @since 2.0
 */
declare
  l_result text := '';
  l_authors text := '';
  l_doc_data jsonb := atable->'doc_data';
begin
  l_result := l_result || e'\n\n### '||(atable->>'table_name')||' <small>('||(atable->>'kind')||')</small>';
  --
  if l_doc_data->>'root' is not null then
    l_result := l_result || e'\n\n'||replace(l_doc_data->>'root', e'\n', e'\n\n');
  elsif atable->>'description' is not null then
    l_result := l_result || e'\n\n'||replace(atable->>'description', e'\n', e'\n\n');
  end if;
  --
  l_result := l_result || e'\n\n#### '||(alocation->>'table_columns');
  l_result := l_result || e'\n\n'||
    '|'||(alocation->>'column_no_th')||'|'||(alocation->>'column_name_th')||'|'||(alocation->>'data_type_th')||
    '|'||(alocation->>'default_value_th')||'|'||(alocation->>'nullable_th')||
    '|'||(alocation->>'primary_key_th')||'|'||(alocation->>'foreign_key_th')||
    '|'||(alocation->>'description_th')||'|'||
    e'\n|---:|----|----|----|----|----|----|----|';
  l_result := l_result || 
    string_agg(e'\n'||
      '|'||(c->>'column_no')||'|'||(c->>'column_name')||'|'||(c->>'data_type')||
      '|'||coalesce(c->>'default_value', '')||'|'||(c->>'nullable')||
      '|'||(c->>'primary_key')||'|'||(c->>'foreign_key')||
      '|'||coalesce((c->>'description'), '')||'|',
    '' order by (c->>'column_no')::numeric) cols from jsonb_array_elements(atable->'columns') c;
  --
  l_result := l_result || gendoc.html_doc_data_uni(l_doc_data, alocation);
  --
  return l_result;
end;
$$;


--
-- TOC entry 382 (class 1255 OID 27532)
-- Name: md_tables(jsonb, jsonb); Type: FUNCTION; Schema: gendoc; Owner: -
--

CREATE FUNCTION gendoc.md_tables(atables jsonb, alocation jsonb) RETURNS text
    LANGUAGE plpgsql IMMUTABLE
    AS $$
/**
 * Create tables markdown section
 *
 * @param {jsonb} atables tables series
 * @param {jsonb} alocation tarnslation strings
 * @returns {text}
 * 
 * @author Andrzej Kałuża
 * @created 2025-01-26
 * @version 1.0
 * @since 2.0
 */
declare
  l_result text := '';
begin
  l_result := l_result || e'\n\n## '||(alocation->>'tables');
  l_result := l_result || (select string_agg(gendoc.md_table(t, alocation), e'\n\n---' order by t->>'table_name') from jsonb_array_elements(atables) t);
  --
  return l_result;
end;
$$;


--
-- TOC entry 410 (class 1255 OID 27631)
-- Name: md_view(jsonb, jsonb); Type: FUNCTION; Schema: gendoc; Owner: -
--

CREATE FUNCTION gendoc.md_view(aview jsonb, alocation jsonb) RETURNS text
    LANGUAGE plpgsql IMMUTABLE
    AS $$
/**
 * Create one view markdown section
 *
 * @param {jsonb} aviewe view
 * @param {jsonb} alocation tarnslation strings
 * @returns {text}
 * 
 * @author Andrzej Kałuża
 * @created 2025-01-29
 * @version 1.0
 * @since 2.0
 */
declare
  l_result text := '';
  l_authors text := '';
  l_doc_data jsonb := aview->'doc_data';
begin
  l_result := l_result || e'\n\n### '||(aview->>'view_name')||' <small>('||(aview->>'kind')||')</small>';
  --
  if l_doc_data->>'root' is not null then
    l_result := l_result || e'\n\n'||replace(l_doc_data->>'root', e'\n', e'\n\n');
  elsif aview->>'description' is not null then
    l_result := l_result || e'\n\n'||replace(aview->>'description', e'\n', e'\n\n');
  end if;
  --
  l_result := l_result || e'\n\n#### '||(alocation->>'view_columns');
  l_result := l_result || e'\n\n'||
    '|'||(alocation->>'column_no_th')||'|'||(alocation->>'column_name_th')||'|'||(alocation->>'data_type_th')||
    '|'||(alocation->>'description_th')||'|'||
    e'\n|---:|----|----|----|';
  l_result := l_result || 
    string_agg(e'\n'||
      '|'||(c->>'column_no')||'|'||(c->>'column_name')||'|'||(c->>'data_type')||
      '|'||coalesce((c->>'description'), '')||'|',
    '' order by (c->>'column_no')::numeric) cols from jsonb_array_elements(aview->'columns') c;
  --
  l_result := l_result || gendoc.html_doc_data_uni(l_doc_data, alocation);
  --
  return l_result;
end;
$$;


--
-- TOC entry 404 (class 1255 OID 27630)
-- Name: md_views(jsonb, jsonb); Type: FUNCTION; Schema: gendoc; Owner: -
--

CREATE FUNCTION gendoc.md_views(aviews jsonb, alocation jsonb) RETURNS text
    LANGUAGE plpgsql IMMUTABLE
    AS $$
/**
 * Create views markdown section
 *
 * @param {jsonb} aviews views series
 * @param {jsonb} alocation tarnslation strings
 * @returns {text}
 * 
 * @author Andrzej Kałuża
 * @created 2025-01-29
 * @version 1.0
 * @since 2.0
 */
declare
  l_result text := '';
begin
  l_result := l_result || e'\n\n## '||(alocation->>'views');
  l_result := l_result || (select string_agg(gendoc.md_view(t, alocation), e'\n\n---' order by t->>'view_name') from jsonb_array_elements(aviews) t);
  --
  return l_result;
end;
$$;


--
-- TOC entry 365 (class 1255 OID 27433)
-- Name: version(); Type: FUNCTION; Schema: gendoc; Owner: -
--

CREATE FUNCTION gendoc.version() RETURNS character varying
    LANGUAGE plpgsql IMMUTABLE
    AS $$
/**
 * Version of this package
 *
 * @author Andrzej Kałuża
 * @created 2025-01-24
 * @return {varchar} major.minor.release
 * @since 1.0
 */
begin
  return '2.0.0';
end;
$$;


--
-- TOC entry 3560 (class 0 OID 0)
-- Dependencies: 365
-- Name: FUNCTION version(); Type: COMMENT; Schema: gendoc; Owner: -
--

COMMENT ON FUNCTION gendoc.version() IS 'Version of this package';


-- Completed on 2025-01-30 22:49:45

--
-- PostgreSQL database dump complete
--

