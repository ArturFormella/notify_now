MODULES = notify_now

EXTENSION = notify_now
DATA = notify_now--1.0.sql
PGFILEDESC = "notify_now - extension for postgresql"

REGRESS = notify_now

PG_CONFIG = pg_config
PGXS := $(shell $(PG_CONFIG) --pgxs)
include $(PGXS)
