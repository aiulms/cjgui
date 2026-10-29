"""Check complete original metric lines under independently interleaved stderr."""
import re
import sys
from pathlib import Path

raw = Path(sys.argv[1]).read_text()
pattern = (r'CJGUI_OWNER_TURN_COST v=1 ordinal=(\d+) turn=(\d+) session=0 '
           r'begin_ns=(\d+) end_ns=(\d+) credited_idle_ns=10000 idle_known=1 '
           r'begin_tid=101 end_tid=101')
rows = [re.fullmatch(pattern, line) for line in raw.splitlines()]
rows = [row for row in rows if row is not None]
assert len(rows) == 96, ('strict original row count', len(rows), 96)
assert [int(row[1]) for row in rows] == list(range(96))
assert all(int(row[2]) == int(row[1]) + 1 and
           int(row[4]) - int(row[3]) == 50000 for row in rows)
assert raw.count('CJGUI_APPLICATION_STOP fixture=concurrent_stderr') == 1
assert 'CJGUI_OWNER_TURN_COST_EXPORT_END v=1 rows=96\n' in raw
print('complete_metric_lines_under_interleaved_stderr PASS rows=96')
