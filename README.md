# GENDOC

GENDOC is a set of functions written in PLpgSQL to create technical documentation of database objects of a selected schema, package, module.

The document can be created in HTML or MarkDown format.

GENDOC allows you to process object comments and function and procedure documentation comments similarly to jsDoc.

See [Comment Doc Parser](/grobinx/cmtdoc-parser)

## Instalation

Use the PostgreSQL `psql` tool to load a file with a complete set of functions.

```cmd
psql -h hostname -d databasename -U username -f dist/gendoc.sql
```

Scritp create schema gendoc. The logged in user will become the owner of the objects.

Remember that the owner of GENDOC objects must have permissions to the sources of the objects for which documentation will be generated.

## Using

There are two main functions for creating documentation:

* `markdown()` - to generate documentation in the markdown standard
* `html()` - to generate documentation in the html standard

See [Technical documentation](doc/)

### Arguments

Both of the above-mentioned functions have two parameters, a schema name and options

First is a schema name like `public`.

Second is options. Below is an explanation of the available options.

```json
{
    "location": "en" or "pl", // (for now),
    "objects": ["routines", "tables", "views"], // one of or combination, if no property then all
    "package": ["name"], // if the documentation includes the @package tag with name
    "module": ["name"], // if the documentation includes the @module tag with name
    "routines": ["routine_name"], // you can limit the set of routines to specific names
    "tables": ["table_name"], // you can limit the set of tables to specific names
    "views": ["view_name"], // you can limit the set of views to specific names
    // specifies which comments will be processed into jsdoc
    "parse": {
        "schema_comment": false, // process schema comment, default false
        "routine_body": true, // search for technical comment in head of routines if function is plpgsql, otherwise rutine comment, default true
        "table_comment": true, // process table comment, default true
        "table_column_comment": false, // process table column comment, default false
        "view_comment": true, // process table comment, default true
        "view_column_comment": false, // process table column comment, default false
    }
}
```

I distinguished three sets of promises, three levels:

1. schema - is like namespace, contains all objects of some system or application
2. package - contains objects grouped into a package, for example core and web
3. module - contains functionally grouped objects, e.g. (web) orders, complaints

### Examples

```sql
select gendoc.html('cron', '{ "location": "en", "package" : ["core"] }')
```

```sql
select gendoc.markdown('gendoc', '{ "location": "pl" }')
```

Copy result and past to a file.
