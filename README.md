# notify_now

This simple extension allows you to return multiple responses from a single query using the built-in PostgreSQL NOTIFY API.
There are no additional dependencies.

Responses are sent to the application immediately after the function is executed in postgres, so it does not wait for the query or transaction to complete. This allows you to create many interesting functionalities:
- start using SQL like GraphQL
- query status monitoring
- returning part of the result for quick presentation to the end user
- returning responses with execution plan
- better debugging of a transaction that will be rolled back

Each query can return any number of responses using this method.
The PostgreSQL NOTIFY API has many implementations in different languages


NodeJS Example
----------
It contains a complete implementation of NOTIFY event handling in the application. After starting, we see how the messages flow.
This is the perfect place to use RxJS or another library for event handling.
Build an run:

    make install
    node ./index.js


Installing
----------

This package installs like any Postgres extension. First say:

    make && sudo make install

You will need to have `pg_config` in your path,
Then in the database of your choice say:

    CREATE EXTENSION notify_now;
 
Troubles
----------

Missing libs:

    sudo apt-get install build-essential libreadline-dev zlib1g-dev flex bison libxml2-dev libxslt-dev libssl-dev libxml2-utils xsltproc ccache

Custom PotsgreSQL surce folder

    make VPATH=/home/user/postgres/src/include

Problem with clang:

    make with_llvm=no && sudo make with_llvm=no install

