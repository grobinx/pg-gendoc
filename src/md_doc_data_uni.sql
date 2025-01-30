--DROP FUNCTION gendoc.md_doc_data_uni(adoc_data jsonb, alocation jsonb);

CREATE OR REPLACE FUNCTION gendoc.md_doc_data_uni(adoc_data jsonb, alocation jsonb)
 RETURNS text
 LANGUAGE plpgsql
 IMMUTABLE
AS $function$
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
$function$;

ALTER FUNCTION gendoc.md_doc_data_uni(adoc_data jsonb, alocation jsonb) OWNER TO gendoc;
COMMENT ON FUNCTION gendoc.md_doc_data_uni(adoc_data jsonb, alocation jsonb) IS '';
