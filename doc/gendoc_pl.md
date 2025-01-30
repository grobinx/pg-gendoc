# Schemat "gendoc" - Wersja 2.0.0<small>&nbsp;	2025-01-30 20:39:17</small>

## Spis treści

1. [Funkcje i procedury](#Funkcje-i-procedury)
	1. [`get_collect_info`](#get_collect_info) Collect info
	2. [`get_package_version`](#get_package_version) get package version
	3. [`get_routine_doc`](#get_routine_doc) parse one routine doc
	4. [`get_routines`](#get_routines) collect usable information
	5. [`get_schema`](#get_schema) Create jsonb with all usable information about schema
	6. [`get_tables`](#get_tables) collect information about tables
	7. [`get_translation`](#get_translation) The function includes language translations
	8. [`get_views`](#get_views) collect information about views
	9. [`html`](#html) generate html document
	10. [`html_create_toc`](#html_create_toc) toc for all objects

Level 1
	11. [`html_doc_data_param`](#html_doc_data_param) create information about arguments
	12. [`html_doc_data_prop`](#html_doc_data_prop) create information about properties
	13. [`html_doc_data_uni`](#html_doc_data_uni) create uniwersal for all obejcts information
	14. [`html_routine`](#html_routine) Create one routine html section
	15. [`html_routines`](#html_routines) Create routines html section
	16. [`html_schema`](#html_schema) Create schema html section
	17. [`html_series_toc`](#html_series_toc) Create table of content from jsonb array as HTML code

Level 2
	18. [`html_table`](#html_table) Create one table html section
	19. [`html_tables`](#html_tables) Create tables html section
	20. [`html_view`](#html_view) Create one view html section
	21. [`html_views`](#html_views) Create views html section
	22. [`is_private_routine`](#is_private_routine) Check is routine is set as private. If not set as private, returns false.
	23. [`is_public_routine`](#is_public_routine) Check is routine is set as public. If not set as public, function returns true
	24. [`is_test_routine`](#is_test_routine) Check is routine is set as test.
	25. [`jsdoc_parse`](#jsdoc_parse) Function parse jsdoc and returns jsonb structure<br />
Function remove comment characters from string.
	26. [`markdown`](#markdown) generate md document
	27. [`md_create_toc`](#md_create_toc) Create table of content for all series
Level 1
	28. [`md_doc_data_param`](#md_doc_data_param) Creates a collection of information from doc_data about parameters
	29. [`md_doc_data_prop`](#md_doc_data_prop) Creates a collection of information from doc_data about properties
	30. [`md_doc_data_uni`](#md_doc_data_uni) Creates a collection of information from doc_data
	31. [`md_routine`](#md_routine) Create one routine markdown section
	32. [`md_routines`](#md_routines) Create routines markdown section
	33. [`md_schema`](#md_schema) Create schema markdown section
	34. [`md_series_toc`](#md_series_toc) Create table of content from jsonb array as MarkDown code

Level 2
	35. [`md_table`](#md_table) Create one table markdown section
	36. [`md_tables`](#md_tables) Create tables markdown section
	37. [`md_view`](#md_view) Create one view markdown section
	38. [`md_views`](#md_views) Create views markdown section
	39. [`version`](#version) Version of this package
	40. [`wiki`](#wiki)
	41. [`wiki_create_toc`](#wiki_create_toc) Create table of content for all series
Level 1
	42. [`wiki_series_toc`](#wiki_series_toc) Create table of content from jsonb array as Wiki markup code

Level 2
	43. [`wiki_tables`](#wiki_tables) Create tables wiki section


## Funkcje i procedury

### get_collect_info <small>(function)</small>

<code>get_collect_info(aschema, aoptions<sup>opc</sup>)</code> → <code>record</code>

Collects complete information about objects and returns it in the form of a record

#### Argumenty

|Lp|Nazwa|Typ danych|Wartość domyślna|Tryb|Opis|
|---:|----|----|----|----|----|
|1|aschema|name||in|schema name|
|2|aoptions|jsonb|NULL::json|in|options to generate documentation|

#### Właściwości

|Nazwa|Typ danych|Wartość domyślna|Opis|
|----|----|----|----|
|aoptions.objects|string[]||objects that are to appear in the documentation (routines, tables, views)|

>
> **Autor** Andrzej Kałuża
>
> **Wersja** 1.0
>
> **Dostępna od** 2.0
>
> **Utworzono** 2025-01-26

#### Zobacz też

get_routines 

get_tables 

get_views 

get_schema 

#### Podsumowanie

Collect info

#### Zwraca

schema, version, routines, tables, views

> **Typ danych** `TABLE(schema jsonb, version character varying, routines jsonb, tables jsonb, views jsonb)`

---

### get_package_version <small>(function)</small>

<code>get_package_version(aschema)</code> → <code>text</code>

Get schema/package version by calling schema.version() function

#### Argumenty

|Lp|Nazwa|Typ danych|Wartość domyślna|Tryb|Opis|
|---:|----|----|----|----|----|
|1|aschema|name||in||

>
> **Autor** Andrzej Kałuża
>
> **Dostępna od** 1.0
>
> **Utworzono** 2025-01-24

#### Podsumowanie

get package version

#### Zwraca

major.minor.release or null

> **Typ danych** `text`

---

### get_routine_doc <small>(function)</small>

<code>get_routine_doc(aschema, aroutine)</code> → <code>jsonb</code>

Function parse jsdoc data from body by identity name.

#### Argumenty

|Lp|Nazwa|Typ danych|Wartość domyślna|Tryb|Opis|
|---:|----|----|----|----|----|
|1|aschema|name||in|schema name|
|2|aroutine|text||in|routine identity name|

>
> **Autor** Andrzej Kałuża
>
> **Wersja** 1.0
>
> **Dostępna od** 2.0
>
> **Utworzono** 2025-01-25

#### Podsumowanie

parse one routine doc

#### Zwraca



> **Typ danych** `jsonb`

---

### get_routines <small>(function)</small>

<code>get_routines(aschema, aoptions)</code> → <code>jsonb</code>

Create jsonb with all usable information about routines on schema

#### Argumenty

|Lp|Nazwa|Typ danych|Wartość domyślna|Tryb|Opis|
|---:|----|----|----|----|----|
|1|aschema|name||in|schema name|
|2|aoptions|jsonb||in|options|

#### Właściwości

|Nazwa|Typ danych|Wartość domyślna|Opis|
|----|----|----|----|
|aoptions.routines.include|varchar[]||include routines or null if all|
|aoptions.routines.exclude|varchar[]||exclude routines or null if all|
|aoptions.package|varchar[]||package names or null if all and if aoptions.parse.routine_body set to true|
|aoptions.module|varchar[]||module names or null if all and if aoptions.parse.routine_body set to true|
|aoptions.parse.routine_body|boolean|true|parse body for search documentation if plpgsql, otherwise the comment will be processed|

>
> **Autor** Andrzej Kałuża
>
> **Wersja** 1.0
>
> **Dostępna od** 2.0
>
> **Utworzono** 2025-01-25

#### Podsumowanie

collect usable information

#### Zwraca



> **Typ danych** `jsonb`

---

### get_schema <small>(function)</small>

<code>get_schema(aschema, aoptions)</code> → <code>jsonb</code>

Create jsonb with all usable information about schema

#### Argumenty

|Lp|Nazwa|Typ danych|Wartość domyślna|Tryb|Opis|
|---:|----|----|----|----|----|
|1|aschema|name||in|schema name|
|2|aoptions|jsonb||in|options|

#### Właściwości

|Nazwa|Typ danych|Wartość domyślna|Opis|
|----|----|----|----|
|aoptions.parse.schema_comment|boolean|false|whether the schema comment should be processed|

>
> **Autor** Andrzej Kałuża
>
> **Wersja** 1.0
>
> **Dostępna od** 2.0
>
> **Utworzono** 2025-01-25

#### Zwraca



> **Typ danych** `jsonb`

---

### get_tables <small>(function)</small>

<code>get_tables(aschema, aoptions)</code> → <code>jsonb</code>

Create jsonb with all usable information about tables on schema

#### Argumenty

|Lp|Nazwa|Typ danych|Wartość domyślna|Tryb|Opis|
|---:|----|----|----|----|----|
|1|aschema|name||in|schema name|
|2|aoptions|jsonb||in|options|

#### Właściwości

|Nazwa|Typ danych|Wartość domyślna|Opis|
|----|----|----|----|
|aoptions.tables.include|varchar[]||include tables or null if all|
|aoptions.tables.exclude|varchar[]||exclude tables or null if all|
|aoptions.package|varchar[]||package names or null if all|
|aoptions.module|varchar[]||module names or null if all|
|aoptions.parse.table_comment|boolean|true|parse doc table comment|
|aoptions.parse.table_column_comment|boolean|false|parse doc table column comment|

>
> **Autor** Andrzej Kałuża
>
> **Wersja** 1.0
>
> **Dostępna od** 2.0
>
> **Utworzono** 2025-01-24

#### Podsumowanie

collect information about tables

#### Zwraca



> **Typ danych** `jsonb`

---

### get_translation <small>(function)</small>

<code>get_translation(alocation)</code> → <code>jsonb</code>

The function includes language translations

#### Argumenty

|Lp|Nazwa|Typ danych|Wartość domyślna|Tryb|Opis|
|---:|----|----|----|----|----|
|1|alocation|character varying||in|location shortcut (eg pl, en, ch)|

>
> **Autor** Andrzej Kałuża
>
> **Wersja** 1.0
>
> **Dostępna od** 2.0
>
> **Utworzono** 2025-01-26

#### Zwraca

translation

> **Typ danych** `jsonb`

---

### get_views <small>(function)</small>

<code>get_views(aschema, aoptions)</code> → <code>jsonb</code>

Create jsonb with all usable information about views on schema

#### Argumenty

|Lp|Nazwa|Typ danych|Wartość domyślna|Tryb|Opis|
|---:|----|----|----|----|----|
|1|aschema|name||in|schema name|
|2|aoptions|jsonb||in|options|

#### Właściwości

|Nazwa|Typ danych|Wartość domyślna|Opis|
|----|----|----|----|
|aoptions.views.include|varchar[]||include views or null if all|
|aoptions.views.exclude|varchar[]||exclude views or null if all|
|aoptions.package|varchar[]||package names or null if all|
|aoptions.module|varchar[]||module names or null if all|
|aoptions.parse.view_comment|boolean|true|parse doc table comment|
|aoptions.parse.view_column_comment|boolean|false|parse doc table column comment|

>
> **Autor** Andrzej Kałuża
>
> **Wersja** 1.0
>
> **Dostępna od** 2.0
>
> **Utworzono** 2025-01-25

#### Podsumowanie

collect information about views

#### Zwraca



> **Typ danych** `jsonb`

---

### html <small>(function)</small>

<code>html(aschema, aoptions<sup>opc</sup>)</code> → <code>text</code>

Creates html document with all objects information

#### Argumenty

|Lp|Nazwa|Typ danych|Wartość domyślna|Tryb|Opis|
|---:|----|----|----|----|----|
|1|aschema|name||in|schema name|
|2|aoptions|jsonb|NULL::jsonb|in|generate settings|

>
> **Autor** Andrzej Kałuża
>
> **Wersja** 1.0
>
> **Dostępna od** 2.0
>
> **Utworzono** 2025-01-20

#### Podsumowanie

generate html document

#### Zwraca



> **Typ danych** `text`

---

### html_create_toc <small>(function)</small>

<code>html_create_toc(aroutines, atables, aviews, alocation)</code> → <code>text</code>

Create table of content for all series

#### Argumenty

|Lp|Nazwa|Typ danych|Wartość domyślna|Tryb|Opis|
|---:|----|----|----|----|----|
|1|aroutines|jsonb||in|routines series|
|2|atables|jsonb||in|tables series|
|3|aviews|jsonb||in|views series|
|4|alocation|jsonb||in|tarnslation strings|

>
> **Autor** Andrzej Kałuża
>
> **Wersja** 1.0
>
> **Dostępna od** 2.0
>
> **Utworzono** 2025-01-26

#### Podsumowanie

toc for all objects

Level 1

#### Zwraca



> **Typ danych** `text`

---

### html_doc_data_param <small>(function)</small>

<code>html_doc_data_param(adoc_data, aarguments, alocation)</code> → <code>text</code>

Creates a collection of information from doc_data about arguments

#### Argumenty

|Lp|Nazwa|Typ danych|Wartość domyślna|Tryb|Opis|
|---:|----|----|----|----|----|
|1|adoc_data|jsonb||in|doc data|
|2|aarguments|jsonb||in|routine arguments|
|3|alocation|jsonb||in|tarnslation strings|

>
> **Autor** Andrzej Kałuża
>
> **Wersja** 1.0
>
> **Dostępna od** 2.0
>
> **Utworzono** 2025-01-28

#### Podsumowanie

create information about arguments

#### Zwraca



> **Typ danych** `text`

---

### html_doc_data_prop <small>(function)</small>

<code>html_doc_data_prop(adoc_data, alocation)</code> → <code>text</code>

Creates a collection of information from doc_data about properties

#### Argumenty

|Lp|Nazwa|Typ danych|Wartość domyślna|Tryb|Opis|
|---:|----|----|----|----|----|
|1|adoc_data|jsonb||in|tabl|
|2|alocation|jsonb||in|tarnslation strings|

>
> **Autor** Andrzej Kałuża
>
> **Wersja** 1.0
>
> **Dostępna od** 2.0
>
> **Utworzono** 2025-01-28

#### Podsumowanie

create information about properties

#### Zwraca



> **Typ danych** `text`

---

### html_doc_data_uni <small>(function)</small>

<code>html_doc_data_uni(adoc_data, alocation)</code> → <code>text</code>

Creates a collection of uniwersal information from doc_data

#### Argumenty

|Lp|Nazwa|Typ danych|Wartość domyślna|Tryb|Opis|
|---:|----|----|----|----|----|
|1|adoc_data|jsonb||in|tabl|
|2|alocation|jsonb||in|tarnslation strings|

>
> **Autor** Andrzej Kałuża
>
> **Wersja** 1.0
>
> **Dostępna od** 2.0
>
> **Utworzono** 2025-01-27

#### Podsumowanie

create uniwersal for all obejcts information

#### Zwraca



> **Typ danych** `text`

---

### html_routine <small>(function)</small>

<code>html_routine(aroutine, alocation)</code> → <code>text</code>

Create one routine html section

#### Argumenty

|Lp|Nazwa|Typ danych|Wartość domyślna|Tryb|Opis|
|---:|----|----|----|----|----|
|1|aroutine|jsonb||in||
|2|alocation|jsonb||in|tarnslation strings|
||atable|jsonb|||tabl|

>
> **Autor** Andrzej Kałuża
>
> **Wersja** 1.0
>
> **Dostępna od** 2.0
>
> **Utworzono** 2025-01-27

#### Zwraca



> **Typ danych** `text`

---

### html_routines <small>(function)</small>

<code>html_routines(aroutines, alocation)</code> → <code>text</code>

Create routines html section

#### Argumenty

|Lp|Nazwa|Typ danych|Wartość domyślna|Tryb|Opis|
|---:|----|----|----|----|----|
|1|aroutines|jsonb||in|routine series|
|2|alocation|jsonb||in|tarnslation strings|

>
> **Autor** Andrzej Kałuża
>
> **Wersja** 1.0
>
> **Dostępna od** 2.0
>
> **Utworzono** 2025-01-28

#### Zwraca



> **Typ danych** `text`

---

### html_schema <small>(function)</small>

<code>html_schema(aschema, alocation)</code> → <code>text</code>

Create schema html section

#### Argumenty

|Lp|Nazwa|Typ danych|Wartość domyślna|Tryb|Opis|
|---:|----|----|----|----|----|
|1|aschema|jsonb||in||
|2|alocation|jsonb||in|tarnslation strings|
||atable|jsonb|||tabl|

>
> **Autor** Andrzej Kałuża
>
> **Wersja** 1.0
>
> **Dostępna od** 2.0
>
> **Utworzono** 2025-01-30

#### Zwraca



> **Typ danych** `text`

---

### html_series_toc <small>(function)</small>

<code>html_series_toc(aitems, aname)</code> → <code>text</code>

Create table of content from jsonb array as HTML code



Level 2

#### Argumenty

|Lp|Nazwa|Typ danych|Wartość domyślna|Tryb|Opis|
|---:|----|----|----|----|----|
|1|aitems|jsonb||in|array with elements|
|2|aname|character varying||in|item name to show|

>
> **Autor** Andrzej Kałuża
>
> **Wersja** 1.0
>
> **Dostępna od** 2.0
>
> **Utworzono** 2025-01-26

#### Zwraca



> **Typ danych** `text`

---

### html_table <small>(function)</small>

<code>html_table(atable, alocation)</code> → <code>text</code>

Create one table html section

#### Argumenty

|Lp|Nazwa|Typ danych|Wartość domyślna|Tryb|Opis|
|---:|----|----|----|----|----|
|1|atable|jsonb||in|tabl|
|2|alocation|jsonb||in|tarnslation strings|

>
> **Autor** Andrzej Kałuża
>
> **Wersja** 1.0
>
> **Dostępna od** 2.0
>
> **Utworzono** 2025-01-27

#### Zwraca



> **Typ danych** `text`

---

### html_tables <small>(function)</small>

<code>html_tables(atables, alocation)</code> → <code>text</code>

Create tables html section

#### Argumenty

|Lp|Nazwa|Typ danych|Wartość domyślna|Tryb|Opis|
|---:|----|----|----|----|----|
|1|atables|jsonb||in|tables series|
|2|alocation|jsonb||in|tarnslation strings|

>
> **Autor** Andrzej Kałuża
>
> **Wersja** 1.0
>
> **Dostępna od** 2.0
>
> **Utworzono** 2025-01-26

#### Zwraca



> **Typ danych** `text`

---

### html_view <small>(function)</small>

<code>html_view(aview, alocation)</code> → <code>text</code>

Create one view html section

#### Argumenty

|Lp|Nazwa|Typ danych|Wartość domyślna|Tryb|Opis|
|---:|----|----|----|----|----|
|1|aview|jsonb||in|view|
|2|alocation|jsonb||in|tarnslation strings|

>
> **Autor** Andrzej Kałuża
>
> **Wersja** 1.0
>
> **Dostępna od** 2.0
>
> **Utworzono** 2025-01-97

#### Zwraca



> **Typ danych** `text`

---

### html_views <small>(function)</small>

<code>html_views(aviews, alocation)</code> → <code>text</code>

Create views html section

#### Argumenty

|Lp|Nazwa|Typ danych|Wartość domyślna|Tryb|Opis|
|---:|----|----|----|----|----|
|1|aviews|jsonb||in||
|2|alocation|jsonb||in|tarnslation strings|
||atables|jsonb|||views series|

>
> **Autor** Andrzej Kałuża
>
> **Wersja** 1.0
>
> **Dostępna od** 2.0
>
> **Utworzono** 2025-01-29

#### Zwraca



> **Typ danych** `text`

---

### is_private_routine <small>(function)</small>

<code>is_private_routine(aschema, aroutine)</code> → <code>boolean</code>

Check is routine is set as private. If not set as private, returns false.

#### Argumenty

|Lp|Nazwa|Typ danych|Wartość domyślna|Tryb|Opis|
|---:|----|----|----|----|----|
|1|aschema|name||in|schema name|
|2|aroutine|text||in|routine identity name|

>
> **Autor** Andrzej Kałuża
>
> **Wersja** 1.0
>
> **Dostępna od** 2.0
>
> **Utworzono** 2025-01-25

#### Zwraca



> **Typ danych** `boolean`

---

### is_public_routine <small>(function)</small>

<code>is_public_routine(aschema, aroutine)</code> → <code>boolean</code>

Check is routine is set as public. If not set as public, function returns true

#### Argumenty

|Lp|Nazwa|Typ danych|Wartość domyślna|Tryb|Opis|
|---:|----|----|----|----|----|
|1|aschema|name||in|schema name|
|2|aroutine|text||in|routine identity name|

>
> **Autor** Andrzej Kałuża
>
> **Wersja** 1.0
>
> **Dostępna od** 2.0
>
> **Utworzono** 2025-01-25

#### Zwraca



> **Typ danych** `boolean`

---

### is_test_routine <small>(function)</small>

<code>is_test_routine(aschema, aroutine)</code> → <code>boolean</code>

Check is routine is set as test.

#### Argumenty

|Lp|Nazwa|Typ danych|Wartość domyślna|Tryb|Opis|
|---:|----|----|----|----|----|
|1|aschema|name||in|schema name|
|2|aroutine|text||in|routine identity name|

>
> **Autor** Andrzej Kałuża
>
> **Wersja** 1.0
>
> **Dostępna od** 2.0
>
> **Utworzono** 2025-01-6

#### Zwraca



> **Typ danych** `boolean`

---

### jsdoc_parse <small>(function)</small>

<code>jsdoc_parse(str)</code> → <code>jsonb</code>

Function parse jsdoc and returns jsonb structure<br />

Function remove comment characters from string.

#### Argumenty

|Lp|Nazwa|Typ danych|Wartość domyślna|Tryb|Opis|
|---:|----|----|----|----|----|
|1|str|character varying||in|string to parse|

>
> **Autor** cmtdoc parser (https://github.com/grobinx/cmtdoc-parser)
>
> **Wersja** 1.1.12
>
> **Utworzono** Wed Jan 29 2025 17:25:24 GMT+0100 (czas środkowoeuropejski standardowy)

#### Przykład

````sql
select p.proname, jsdoc_parse(p.doc) as doc, p.arguments, p.description
  from (select p.proname, substring(p.prosrc from '\/\*\*.*\*\/') as doc, 
               coalesce(pg_get_function_arguments(p.oid), '') arguments,
               d.description
          from pg_proc p
               join pg_namespace n on n.oid = p.pronamespace
               left join pg_description d on d.classoid = 'pg_proc'::regclass and d.objoid = p.oid and d.objsubid = 0
         where n.nspname = :scema_name
           and p.prokind in ('p', 'f')) p
 where p.doc is not null
````

#### Zwraca



> **Typ danych** `jsonb`

---

### markdown <small>(function)</small>

<code>markdown(aschema, aoptions<sup>opc</sup>)</code> → <code>text</code>

Creates markdown document with all objects information

#### Argumenty

|Lp|Nazwa|Typ danych|Wartość domyślna|Tryb|Opis|
|---:|----|----|----|----|----|
|1|aschema|name||in|schema name|
|2|aoptions|jsonb|NULL::jsonb|in|generate settings|

>
> **Autor** Andrzej Kałuża
>
> **Wersja** 1.0
>
> **Dostępna od** 2.0
>
> **Utworzono** 2025-01-20

#### Podsumowanie

generate md document

#### Zwraca



> **Typ danych** `text`

---

### md_create_toc <small>(function)</small>

<code>md_create_toc(aroutines, atables, aviews, alocation)</code> → <code>text</code>

Create table of content for all series

Level 1

#### Argumenty

|Lp|Nazwa|Typ danych|Wartość domyślna|Tryb|Opis|
|---:|----|----|----|----|----|
|1|aroutines|jsonb||in|routines series|
|2|atables|jsonb||in|tables series|
|3|aviews|jsonb||in|views series|
|4|alocation|jsonb||in|tarnslation strings|

>
> **Autor** Andrzej Kałuża
>
> **Wersja** 1.0
>
> **Dostępna od** 2.0
>
> **Utworzono** 2025-01-26

#### Zwraca



> **Typ danych** `text`

---

### md_doc_data_param <small>(function)</small>

<code>md_doc_data_param(adoc_data, aarguments, alocation)</code> → <code>text</code>

Creates a collection of information from doc_data about parameters

#### Argumenty

|Lp|Nazwa|Typ danych|Wartość domyślna|Tryb|Opis|
|---:|----|----|----|----|----|
|1|adoc_data|jsonb||in|doc data|
|2|aarguments|jsonb||in|routine arguments|
|3|alocation|jsonb||in|tarnslation strings|

>
> **Autor** Andrzej Kałuża
>
> **Wersja** 1.0
>
> **Dostępna od** 2.0
>
> **Utworzono** 2025-01-29

#### Zwraca



> **Typ danych** `text`

---

### md_doc_data_prop <small>(function)</small>

<code>md_doc_data_prop(adoc_data, alocation)</code> → <code>text</code>

Creates a collection of information from doc_data about properties

#### Argumenty

|Lp|Nazwa|Typ danych|Wartość domyślna|Tryb|Opis|
|---:|----|----|----|----|----|
|1|adoc_data|jsonb||in|tabl|
|2|alocation|jsonb||in|tarnslation strings|

>
> **Autor** Andrzej Kałuża
>
> **Wersja** 1.0
>
> **Dostępna od** 2.0
>
> **Utworzono** 2025-01-28

#### Zwraca



> **Typ danych** `text`

---

### md_doc_data_uni <small>(function)</small>

<code>md_doc_data_uni(adoc_data, alocation)</code> → <code>text</code>

Creates a collection of information from doc_data

#### Argumenty

|Lp|Nazwa|Typ danych|Wartość domyślna|Tryb|Opis|
|---:|----|----|----|----|----|
|1|adoc_data|jsonb||in|tabl|
|2|alocation|jsonb||in|tarnslation strings|

>
> **Autor** Andrzej Kałuża
>
> **Wersja** 1.0
>
> **Dostępna od** 2.0
>
> **Utworzono** 2025-01-29

#### Zwraca



> **Typ danych** `text`

---

### md_routine <small>(function)</small>

<code>md_routine(aroutine, alocation)</code> → <code>text</code>

Create one routine markdown section

#### Argumenty

|Lp|Nazwa|Typ danych|Wartość domyślna|Tryb|Opis|
|---:|----|----|----|----|----|
|1|aroutine|jsonb||in||
|2|alocation|jsonb||in|tarnslation strings|
||atable|jsonb|||tabl|

>
> **Autor** Andrzej Kałuża
>
> **Wersja** 1.0
>
> **Dostępna od** 2.0
>
> **Utworzono** 2025-01-29

#### Zwraca



> **Typ danych** `text`

---

### md_routines <small>(function)</small>

<code>md_routines(aroutines, alocation)</code> → <code>text</code>

Create routines markdown section

#### Argumenty

|Lp|Nazwa|Typ danych|Wartość domyślna|Tryb|Opis|
|---:|----|----|----|----|----|
|1|aroutines|jsonb||in|routine series|
|2|alocation|jsonb||in|tarnslation strings|

>
> **Autor** Andrzej Kałuża
>
> **Wersja** 1.0
>
> **Dostępna od** 2.0
>
> **Utworzono** 2025-01-29

#### Zwraca



> **Typ danych** `text`

---

### md_schema <small>(function)</small>

<code>md_schema(aschema, alocation)</code> → <code>text</code>

Create schema markdown section

#### Argumenty

|Lp|Nazwa|Typ danych|Wartość domyślna|Tryb|Opis|
|---:|----|----|----|----|----|
|1|aschema|jsonb||in||
|2|alocation|jsonb||in|tarnslation strings|
||atable|jsonb|||tabl|

>
> **Autor** Andrzej Kałuża
>
> **Wersja** 1.0
>
> **Dostępna od** 2.0
>
> **Utworzono** 2025-01-30

#### Zwraca



> **Typ danych** `text`

---

### md_series_toc <small>(function)</small>

<code>md_series_toc(aitems, aname)</code> → <code>text</code>

Create table of content from jsonb array as MarkDown code



Level 2

#### Argumenty

|Lp|Nazwa|Typ danych|Wartość domyślna|Tryb|Opis|
|---:|----|----|----|----|----|
|1|aitems|jsonb||in|array with elements|
|2|aname|character varying||in|item name to show|

>
> **Autor** Andrzej Kałuża
>
> **Wersja** 1.0
>
> **Dostępna od** 2.0
>
> **Utworzono** 2025-01-26

#### Zwraca



> **Typ danych** `text`

---

### md_table <small>(function)</small>

<code>md_table(atable, alocation)</code> → <code>text</code>

Create one table markdown section

#### Argumenty

|Lp|Nazwa|Typ danych|Wartość domyślna|Tryb|Opis|
|---:|----|----|----|----|----|
|1|atable|jsonb||in|tabl|
|2|alocation|jsonb||in|tarnslation strings|

>
> **Autor** Andrzej Kałuża
>
> **Wersja** 1.0
>
> **Dostępna od** 2.0
>
> **Utworzono** 2025-01-29

#### Zwraca



> **Typ danych** `text`

---

### md_tables <small>(function)</small>

<code>md_tables(atables, alocation)</code> → <code>text</code>

Create tables markdown section

#### Argumenty

|Lp|Nazwa|Typ danych|Wartość domyślna|Tryb|Opis|
|---:|----|----|----|----|----|
|1|atables|jsonb||in|tables series|
|2|alocation|jsonb||in|tarnslation strings|

>
> **Autor** Andrzej Kałuża
>
> **Wersja** 1.0
>
> **Dostępna od** 2.0
>
> **Utworzono** 2025-01-26

#### Zwraca



> **Typ danych** `text`

---

### md_view <small>(function)</small>

<code>md_view(aview, alocation)</code> → <code>text</code>

Create one view markdown section

#### Argumenty

|Lp|Nazwa|Typ danych|Wartość domyślna|Tryb|Opis|
|---:|----|----|----|----|----|
|1|aview|jsonb||in||
|2|alocation|jsonb||in|tarnslation strings|
||aviewe|jsonb|||view|

>
> **Autor** Andrzej Kałuża
>
> **Wersja** 1.0
>
> **Dostępna od** 2.0
>
> **Utworzono** 2025-01-29

#### Zwraca



> **Typ danych** `text`

---

### md_views <small>(function)</small>

<code>md_views(aviews, alocation)</code> → <code>text</code>

Create views markdown section

#### Argumenty

|Lp|Nazwa|Typ danych|Wartość domyślna|Tryb|Opis|
|---:|----|----|----|----|----|
|1|aviews|jsonb||in|views series|
|2|alocation|jsonb||in|tarnslation strings|

>
> **Autor** Andrzej Kałuża
>
> **Wersja** 1.0
>
> **Dostępna od** 2.0
>
> **Utworzono** 2025-01-29

#### Zwraca



> **Typ danych** `text`

---

### version <small>(function)</small>

<code>version()</code> → <code>character varying</code>

Version of this package

>
> **Autor** Andrzej Kałuża
>
> **Dostępna od** 1.0
>
> **Utworzono** 2025-01-24

#### Zwraca

major.minor.release

> **Typ danych** `character varying`

---

### wiki <small>(function)</small>

<code>wiki(aschema, aoptions<sup>opc</sup>)</code> → <code>text</code>

#### Argumenty

|Lp|Nazwa|Typ danych|Wartość domyślna|Tryb|Opis|
|---:|----|----|----|----|----|
|1|aschema|name||in||
|2|aoptions|jsonb|NULL::jsonb|in||


#### Zwraca

> **Typ danych** `text`

---

### wiki_create_toc <small>(function)</small>

<code>wiki_create_toc(aroutines, atables, aviews, alocation)</code> → <code>text</code>

Create table of content for all series

Level 1

#### Argumenty

|Lp|Nazwa|Typ danych|Wartość domyślna|Tryb|Opis|
|---:|----|----|----|----|----|
|1|aroutines|jsonb||in|routines series|
|2|atables|jsonb||in|tables series|
|3|aviews|jsonb||in|views series|
|4|alocation|jsonb||in|tarnslation strings|

>
> **Autor** Andrzej Kałuża
>
> **Wersja** 1.0
>
> **Dostępna od** 2.0
>
> **Utworzono** 2025-01-26

#### Zwraca



> **Typ danych** `text`

---

### wiki_series_toc <small>(function)</small>

<code>wiki_series_toc(aitems, aname)</code> → <code>text</code>

Create table of content from jsonb array as Wiki markup code



Level 2

#### Argumenty

|Lp|Nazwa|Typ danych|Wartość domyślna|Tryb|Opis|
|---:|----|----|----|----|----|
|1|aitems|jsonb||in|array with elements|
|2|aname|character varying||in|item name to show|

>
> **Autor** Andrzej Kałuża
>
> **Wersja** 1.0
>
> **Dostępna od** 2.0
>
> **Utworzono** 2025-01-26

#### Zwraca



> **Typ danych** `text`

---

### wiki_tables <small>(function)</small>

<code>wiki_tables(atables, alocation)</code> → <code>text</code>

Create tables wiki section

#### Argumenty

|Lp|Nazwa|Typ danych|Wartość domyślna|Tryb|Opis|
|---:|----|----|----|----|----|
|1|atables|jsonb||in|tables series|
|2|alocation|jsonb||in|tarnslation strings|

>
> **Autor** Andrzej Kałuża
>
> **Wersja** 1.0
>
> **Dostępna od** 2.0
>
> **Utworzono** 2025-01-76

#### Zwraca



> **Typ danych** `text`

----
<small>GENDOC 2.0.0 - Andrzej Kałuża</small>