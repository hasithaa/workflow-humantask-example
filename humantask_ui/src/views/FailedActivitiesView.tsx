import { useState } from "react";
import * as api from "../api";
import { useAsync } from "../useAsync";
import { RetryTaskItem } from "../components";
import { matchesFilter, type StatusFilter } from "../types";
import { Empty, ErrorBanner, Spinner, StatusFilterBar } from "../ui";

export default function FailedActivitiesView() {
  const [filter, setFilter] = useState<StatusFilter>("PENDING");
  const { data, error, loading, reload } = useAsync(() => api.listRetryTasks(), []);

  const tasks = (data ?? []).filter((t) => matchesFilter(t.status, filter));

  return (
    <div>
      <h1 className="page-title">Failed Activities</h1>
      <p className="page-sub">
        Activities that failed under a manual-retry policy. Retry them as-is, edit the input and retry, or fail
        them permanently.
      </p>

      <div className="toolbar">
        <StatusFilterBar value={filter} onChange={setFilter} />
        <span className="spacer" />
        <span className="muted small">{tasks.length} activity(ies)</span>
      </div>

      <ErrorBanner error={error} />

      {loading ? (
        <Spinner />
      ) : tasks.length === 0 ? (
        <div className="card">
          <Empty>No {filter.toLowerCase()} failed activities.</Empty>
        </div>
      ) : (
        tasks.map((t) => <RetryTaskItem key={t.taskId} task={t} onChanged={reload} />)
      )}
    </div>
  );
}
