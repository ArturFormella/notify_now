# notify_now

This simple extension allows you to return multiple responses from a single query using the built-in PostgreSQL NOTIFY API.
There are no additional dependencies.

Responses are sent to the application immediately after the function is executed in Postgres, so it does not wait for the query or transaction to complete. This allows you to create many interesting functionalities:

- start using SQL like GraphQL

- query status monitoring

- returning part of the result for quick presentation to the end user

- returning responses with execution plan

- better debugging of a transaction that will be rolled back

Each query can return any number of responses using this method.
The PostgreSQL NOTIFY API has many implementations in different languages

Example
----------
    CREATE OR REPLACE PROCEDURE public.example4() LANGUAGE plpgsql AS $$
    begin
      PERFORM 1 FROM notify_now('my_message_title', 'my message 1');
      PERFORM pg_sleep(1);
      PERFORM 1 FROM notify_now('important_message', ((SELECT json_agg(x) FROM generate_series(6,10) as x(pos)))::text);
      PERFORM pg_sleep(1);
      PERFORM 1 FROM notify_now('other_message', now()::text);
      PERFORM pg_sleep(1);
    end;$$;
    
    CALL public.example4();

Returns:

    Asynchronous notification "my_message_title" with payload "my message 1" - immidiately
    Asynchronous notification "important_message" with payload "[6, 7, 8, 9, 10]" - after 1 sec
    Asynchronous notification "other_message" with payload "2022-12-24 01:04:10.624662+01" - after 2 sec

Notice - `psql` console is not asynchronous. Use other lib for tests. pg_sleep simulates heavy computations.

API
----------
Sending:

    notify_now('channel_name', 'message_content');

Notice - you don't have to query `LISTEN channel_name` to receive messages.

Receiving (NodeJS application)

    client.on('notification', (data) => {
      console.log(data.channel, data.payload);
    });

Receiving (Java application)

    PGNotificationListener listener = (int processId, String channelName, String payload) 
        -> System.out.println("notification = " + payload);
    connection.addNotificationListener(listener);


Limits
----------

`channel_name` <=64 chars

`message_content` <=2000000000 chars (because of NodeJs connector implementation, can be removed)



Application architecture with and without notify_now()
----------

Typically, a controller contains multiple database queries that depend on each other.
Data is fetched, then additional objects are fetched and everything is combined in the application.
Example:
- find products with the right filters
- fetch the total quantity (count(1))
- fetch the first page of results sorting by price
- download categories with quantities of found products
- download all additional information needed to properly display products, categories and more

Disadvantages of the traditional approach:
- Sending data to the application only to send it back in WHERE in the next query.
- `WHERE id IN(...)` Hell
- frequently used anti-patterns: `foreach(products) {query()}`, `products.map( p => query(p))`
- JOINS in the application. Not well optimized.
- application developer needs to understand structures to create full objects
- multiple execution of the same operations (product filtering)
- data consistency problems
- high complexity due to the use of multiple technologies
- Object-Relational-Mismatch problems

## Solution with notify_now()

Pseudocode:
```
WITH matched_products AS (
  SELECT products WHERE all filters match
),
notify_now('all_count', SELECT count(1) FROM matched_products), 
notify_now('first_page', SELECT * FROM matched_products JOIN descriptions ON(...) LIMIT 30 ORDER BY price),
categories_counted AS (
  SELECT category_id, count(1) FROM matched_products GROUP BY category_id
),
notify_now('categories_with_counter', SELECT * FROM categories_counted cc JOIN categories c ON (c.category_id = cc.category_id),
SELECT 'true'
```
As you can see the following messages become "API of the query":
- all_count
- first_page
- categories_with_counter

A division of responsibility between database and application developers can be introduced.

![image](https://user-images.githubusercontent.com/11973278/209994337-1834a2c8-ddc0-42f6-abec-027b4c5122da.png)



NodeJS Example
----------
[Example](https://github.com/ArturFormella/notify_now/tree/main/example_node_app) contains a complete implementation of NOTIFY event handling in the application. After starting, we see how the messages flow.
This is the perfect place to use RxJS or another library for event handling.
Build an run:

    npm install
    node ./index.js

![Node Example Result](https://user-images.githubusercontent.com/11973278/209416287-aa1d12ee-bbb2-457f-98f6-242e61a38349.gif)

Installing from PGXN
----------

    sudo pgxn install notify_now


Installing from source
----------

This package installs like any Postgres extension. First say:

    make && sudo make install

You will need to have `pg_config` in your path,
Then in the database of your choice say:

    CREATE EXTENSION notify_now;
 
Troubles
----------

Missing libs?

    sudo apt-get install build-essential libreadline-dev zlib1g-dev flex bison libxml2-dev libxslt-dev libssl-dev libxml2-utils xsltproc ccache

Custom PostgreSQL source folder?

    make VPATH=/home/user/postgres/src/include

Problem with clang?

    make with_llvm=no && sudo make with_llvm=no install

