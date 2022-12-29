CREATE EXTENSION notify_now SCHEMA PUBLIC;
SELECT public.notify_now(null, null);
SELECT public.notify_now('w', array[678,865]);
SELECT public.notify_now('r', '2346');
SELECT public.notify_now('r', 2346);
WITH x AS (
    SELECT
      'name' || pos as name, (row_number() over()*100) as num
    FROM generate_series(1,5) as x(pos)
  ), w as (
    SELECT public.notify_now('w', array[678,865])
  ), r as (
    SELECT public.notify_now('r', 2346)
  ), z as (
    SELECT public.notify_now('z', ((SELECT sum(x.num) FROM x)))
  ), s as (
    SELECT public.notify_now('s', x) FROM x
  ), y as (
    SELECT public.notify_now('y', ((SELECT jsonb_agg(row_to_json(x)) FROM x)))
  ), obj as (
    SELECT public.notify_now('obj', ((SELECT jsonb_object_agg(x.name, x.num) FROM x)))
  ), ag1 as (
    SELECT public.notify_now_agg('aggr1', row_to_json(x)) FROM x 
  ), ag2 as (
    SELECT public.notify_now_agg('aggr2', x.name) FROM x
  ), ag3 as (
    SELECT public.notify_now_agg('aggr3', x.num) FROM x
  ), ag4 as (
    SELECT public.notify_now_agg('aggr4', x) FROM x 
  )
  SELECT * FROM 
  r, w, s, z, y, obj, ag1, ag2, ag3, ag4;

CREATE OR REPLACE PROCEDURE public.example4() LANGUAGE 'plpgsql'
AS $BODY$
declare zm text;
begin
  CALL public.notify_now_proc('my_message_title', 'my message 1');
  zm:=(((SELECT json_agg(x) FROM generate_series(6,10) as x(pos))));
  CALL public.notify_now_proc('important_message', zm);
  CALL public.notify_now_proc('other_message', 'Wed Dec 28 14:54:23.252127 2022 PST'::date::text);
  PERFORM pg_sleep(1);
end;
$BODY$;
CALL public.example4();
