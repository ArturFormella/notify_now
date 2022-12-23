/*-------------------------------------------------------------------------
 *
 * notify_now.c
 *     extenstion for PostgreSQL
 *
 * IDENTIFICATION
 *		notify_now/notify_now.c
 *
 *-------------------------------------------------------------------------
 */

#include "postgres.h"
#include "utils/json.h"
#include "utils/builtins.h"
#include <limits.h>
#include "access/parallel.h"
#include "catalog/pg_database.h"
#include "libpq/libpq.h"
#include "libpq/pqformat.h"
#include "miscadmin.h"

#define NOTIFY_NOW_PAYLOAD_MAX_LENGTH 2000000000

PG_MODULE_MAGIC;

PG_FUNCTION_INFO_V1(notify_now);

Datum
notify_now(PG_FUNCTION_ARGS)
{
	size_t		channel_len;
	size_t		payload_len;
	const char *channel;
	const char *payload;
  StringInfoData buf;

	if (PG_ARGISNULL(0))
		channel = "";
	else
		channel = text_to_cstring(PG_GETARG_TEXT_P(0));

	if (PG_ARGISNULL(1))
		payload = "";
	else
		payload = text_to_cstring(PG_GETARG_TEXT_P(1));

	channel_len = strlen(channel);
	payload_len = strlen(payload);
 
	if (channel_len == 0)
		ereport(ERROR,
				(errcode(ERRCODE_INVALID_PARAMETER_VALUE),
				 errmsg("channel name cannot be empty")));

	if (channel_len >= NAMEDATALEN)
		ereport(ERROR,
				(errcode(ERRCODE_INVALID_PARAMETER_VALUE),
				 errmsg("channel name too long")));

	if (IsParallelWorker())
		elog(ERROR, "cannot send notifications from a parallel worker");
  
	if (payload_len >= NOTIFY_NOW_PAYLOAD_MAX_LENGTH)
		ereport(ERROR,
				(errcode(ERRCODE_INVALID_PARAMETER_VALUE),
				 errmsg("payload string too long")));

  pq_beginmessage(&buf, 'A'); // NOTIFY
  pq_sendint32(&buf, MyProcPid);
  pq_sendstring(&buf, channel);
  pq_sendstring(&buf, payload);
  pq_endmessage(&buf);
  pq_flush(); // send as soon as possible
	PG_RETURN_VOID();
}
