-- complain if script is sourced in psql, rather than via CREATE EXTENSION
\echo Use "CREATE EXTENSION notify_now" to load this file. \quit

CREATE OR REPLACE FUNCTION notify_now(text, text)
    RETURNS void
    AS 'MODULE_PATHNAME', 'notify_now'
    LANGUAGE C VOLATILE CALLED ON NULL INPUT;
