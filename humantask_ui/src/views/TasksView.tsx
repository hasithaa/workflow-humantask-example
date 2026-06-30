import { useState } from "react";
import { Link } from "react-router-dom";
import * as api from "../api";
import { useAsync } from "../useAsync";
import { matchesFilter, shortTaskName, type HumanTaskSummary, type StatusFilter } from "../types";
import { Empty, ErrorBanner, formatTime, Spinner, StatusBadge, StatusFilterBar } from "../ui";

export default function TasksView() {
  const [filter, setFilter] = useState<StatusFilter>("PENDING");
  // onlyMyTasks scopes the list to the logged-in reviewer's roles.
  const { data, error, loading } = useAsync(() => api.listHumanTasks({ onlyMyTasks: true }), []);

  const tasks = (data ?? []).filter((t) => matchesFilter(t.status, filter));

  return (
    <div>
      <h1 className="page-title">Review Tasks</h1>
      <p className="page-sub">Human tasks assigned to your role. Open a task to view its details and act on it.</p>

      <div className="toolbar">
        <StatusFilterBar value={filter} onChange={setFilter} />
        <span className="spacer" />
        <span className="muted small">{tasks.length} task(s)</span>
      </div>

      <ErrorBanner error={error} />

      <div className="card">
        {loading ? (
          <Spinner />
        ) : tasks.length === 0 ? (
          <Empty>No {filter.toLowerCase()} tasks.</Empty>
        ) : (
          <table>
            <thead>
              <tr>
                <th>Task</th>
                <th>Workflow</th>
                <th>Roles</th>
                <th>Status</th>
                <th>Started</th>
                <th></th>
              </tr>
            </thead>
            <tbody>
              {tasks.map((t: HumanTaskSummary) => (
                <tr key={t.taskId}>
                  <td>
                    <Link to={`/tasks/${encodeURIComponent(t.taskId)}`}>{shortTaskName(t.taskName)}</Link>
                  </td>
                  <td className="muted small">{t.parentWorkflowType ?? t.parentWorkflowId}</td>
                  <td className="muted small">{t.userRoles.join(", ")}</td>
                  <td>
                    <StatusBadge status={t.status} />
                  </td>
                  <td className="muted small">{formatTime(t.startTime)}</td>
                  <td className="row-actions">
                    <Link className="btn small" to={`/tasks/${encodeURIComponent(t.taskId)}`}>
                      Open
                    </Link>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
      </div>
    </div>
  );
}
