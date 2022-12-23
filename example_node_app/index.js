var pg = require ('pg');

var client = new pg.Client({
    host: '/var/run/postgresql',
    port: 5432,
    user: 'postgres',
    password: '',
    database: 'postgres'
  });
client.connect();

// Abstraction layer
const queryWithNotify = async (client, onMessage, query, args = null) => {
  try {
    // LISTEN for messages using libpq API but don't have to run LISTEN to inform Postgres.
    client.on('notification', onMessage);
    return await client.query(query, args);
  } finally {
    // remove listener from libpq. Don't havee to run UNLISTEN.
    client.removeListener("notification", onMessage);
  }
};

const prepare = async () => {
  await client.query(`CREATE EXTENSION IF NOT EXISTS notify_now`);
};


/*
  Baic example - return any part of CTE. Not only the main result.
*/
const example1 = async () => {
  console.log('-------------------------------EXAMPLE 1----------------------------------------');
  const start = Date.now();

  const eventReceiver = (data) => {
    const stop = Date.now();
    console.log(`example1 - channel: ${data.channel},\t${data.payload}\ttime: ${(stop - start)}`);
  };

  const res  = await queryWithNotify(client, eventReceiver, `
  WITH x AS (
    SELECT
      'name' || pos as name, ((random()*100)::int) as num
    FROM generate_series(1,5) as x(pos)
  ), z as (
    SELECT 1 FROM notify_now('counter1', ((SELECT json_agg(row_to_json(x)) FROM x))::text)
  ), y as (
    SELECT * FROM notify_now('counter2', ((SELECT json_agg(row_to_json(x)) FROM x))::text)
  )
  SELECT * FROM z, y
  `);
  
  console.log('main result:', res.rows);
};


/*
  Returns main result, query plan and additional messages.
  pg_sleep simulate heavy computations.
*/

const example2 = async () => {
  console.log('-------------------------------EXAMPLE 2----------------------------------------');
  const start = Date.now();

  const eventReceiver = (data) => {
    const stop = Date.now();
    console.log(`example2 - channel: ${data.channel},\tlength: ${data.payload.length} Bytes\ttime: ${(stop - start)}`);
  };

  const res = await queryWithNotify(client, eventReceiver, `
  EXPLAIN ANALYZE
  SELECT * FROM
    generate_series(80,85) as s(num), 
    notify_now('channel' || num, repeat('#', num*num*num) ), 
    pg_sleep(num/num);`);

  console.log('main result:', res.rows.map( r => r['QUERY PLAN']).join('\n'));
};

/*
  Return multiple datasets from PROCEDURE.
  pg_sleep simulate heavy computations.
*/

const example3 = async () => {
  console.log('-------------------------------EXAMPLE 3----------------------------------------');

  await client.query(`CREATE OR REPLACE PROCEDURE public.example()
    LANGUAGE plpgsql
    AS $$
    begin
        PERFORM 1 FROM notify_now('counter1', ((SELECT json_agg(x) FROM generate_series(1,5) as x(pos)))::text);
        PERFORM pg_sleep(1);
        PERFORM 1 FROM notify_now('counter2', ((SELECT json_agg(x) FROM generate_series(6,10) as x(pos)))::text);
        PERFORM pg_sleep(1);
        PERFORM 1 FROM notify_now('counter3', ((SELECT json_agg(x) FROM generate_series(11,15) as x(pos)))::text);
        PERFORM pg_sleep(1);
    end;$$`);

  const eventReceiver = (data) => {
    const stop = Date.now();
    console.log(`example3 - channel: ${data.channel},\t${data.payload}`);
  };
  const res = await queryWithNotify(client, eventReceiver, `call public.example()`);

  console.log(res.rows);

};


(async function run() {

  await prepare();

  await example1();
  await example2();
  await example3();

  client.end();
})();
