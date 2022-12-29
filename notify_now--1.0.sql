CREATE OR REPLACE FUNCTION notify_now(text, text)
    RETURNS void
    AS 'MODULE_PATHNAME', 'notify_now'
    LANGUAGE C VOLATILE CALLED ON NULL INPUT;

CREATE OR REPLACE PROCEDURE notify_now_proc(channel_name IN text, payload IN anyelement)
    LANGUAGE plpgsql AS $$
    BEGIN
        PERFORM notify_now(channel_name, CAST(payload AS text));
    END;$$;

CREATE OR REPLACE PROCEDURE notify_now_proc(channel_name IN text, payload IN record)
    LANGUAGE plpgsql AS $$
    BEGIN
        PERFORM notify_now(channel_name, CAST(row_to_json(payload) AS text));
    END;$$;

CREATE OR REPLACE FUNCTION notify_now(text, anynonarray)
    RETURNS void
    AS 'SELECT notify_now($1, CAST($2 AS text));'
    LANGUAGE SQL VOLATILE CALLED ON NULL INPUT;

CREATE OR REPLACE FUNCTION notify_now(text, anyarray)
    RETURNS void
    AS 'SELECT notify_now($1, CAST(array_to_json($2) AS text));'
    LANGUAGE SQL VOLATILE CALLED ON NULL INPUT;

/* Hack to ommit: "ERROR: SQL functions cannot have arguments of type record. SQL state: 42P13' */
CREATE OR REPLACE FUNCTION notify_now(text, record)
    RETURNS void
    AS $$ BEGIN PERFORM notify_now($1, CAST(row_to_json($2) AS text)); END $$
    LANGUAGE plpgsql VOLATILE CALLED ON NULL INPUT;


CREATE TYPE public.notify_now_struc AS (
  channel text,
  payload text
);

CREATE OR REPLACE FUNCTION notify_each_row (state notify_now_struc, channel text, payload anyelement)
RETURNS notify_now_struc LANGUAGE sql VOLATILE
as $$
    SELECT row(
      coalesce(state.channel, channel),
      coalesce((state.payload || ',' || to_json(payload)), to_json(payload)::text))::public.notify_now_struc;
$$;

CREATE OR REPLACE FUNCTION notify_each_row (state notify_now_struc, channel text, payload record)
RETURNS notify_now_struc LANGUAGE plpgsql VOLATILE
as $$ BEGIN
     RETURN row(coalesce(state.channel, channel),coalesce((state.payload || ',' || row_to_json(payload)), row_to_json(payload)::text))::public.notify_now_struc;
END $$;

CREATE OR REPLACE FUNCTION notify_final (state public.notify_now_struc)
RETURNS void LANGUAGE sql VOLATILE
as $$
    SELECT notify_now(state.channel, '[' || state.payload || ']');
$$;

CREATE AGGREGATE notify_now_agg (text, anyelement) (
    sfunc = notify_each_row,
    finalfunc = notify_final,
    INITCOND = '(,)',
    stype = notify_now_struc
);
CREATE AGGREGATE notify_now_agg (text, record) (
    sfunc = notify_each_row,
    finalfunc = notify_final,
    INITCOND = '(,)',
    stype = notify_now_struc
);
