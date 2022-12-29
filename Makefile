MODULES = notify_now

EXTENSION = notify_now
DATA = notify_now--1.0.sql
PGFILEDESC = "notify_now - extension for postgresql"

TESTS        = $(wildcard sql/*.sql)
REGRESS      = $(patsubst sql/%.sql,%,$(TESTS))

PG_CONFIG = pg_config
PGXS := $(shell $(PG_CONFIG) --pgxs)
include $(PGXS)

# EXTVERSION=1.0.2 make dist
dist:
	git archive --format=zip -o ../$(EXTENSION)-$(EXTVERSION).zip HEAD
