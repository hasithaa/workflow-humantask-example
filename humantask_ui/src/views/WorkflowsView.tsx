import { Link } from "react-router-dom";
import * as api from "../api";
import { REVIEW_WORKFLOW_TYPE } from "../api";
import { useAsync } from "../useAsync";
import { RetryTaskItem } from "../components";
import { shortTaskName, type HumanTaskSummary, type RetryTaskSummary, type WorkflowSummary } from "../types";
import { Empty, ErrorBanner, formatTime, Spinner, StatusBadge } from "../ui";

interface Grouped {
  workflows: WorkflowSummary[];
  tasksByWf: Map<string, HumanTaskSummary[]>;
  retriesByWf: Map<string, RetryTaskSummary[]>;
  ids: string[];
}

function groupBy<T>(items: T[], key: (t: T) => string): Map<string, T[]> {
  const m = new Map<string, T[]>();
  for (const it of items) {
    const k = key(it);
    (m.get(k) ?? m.set(k, []).get(k)!).push(it);
  }
  return m;
}

export default function WorkflowsView() {
  const { data, error, loading, reload } = useAsync<Grouped>(async () => {
    const [workflows, tasks, retries] = await Promise.all([
      api.listWorkflows({ workflowType: REVIEW_WORKFLOW_TYPE }).catch(() => []),
      api.listHumanTasks({}),
      api.listRetryTasks({}),
    ]);
    const tasksByWf = groupBy(tasks, (t) => t.parentWorkflowId);
    const retriesByWf = groupBy(retries, (r) => r.parentWorkflowId);
    // Union of workflow ids known from the workflow list and from child tasks.
    const ids = new Set<string>(workflows.map((w) => w.workflowId));
    for (const k of tasksByWf.keys()) ids.add(k);
    for (const k of retriesByWf.keys()) ids.add(k);
    return { workflows, tasksByWf, retriesByWf, ids: [...ids] };
  }, []);

  return (
    <div>
      <h1 className="page-title">Review Shipment Errors</h1>
      <p className="page-sub">
        Every <code>{REVIEW_WORKFLOW_TYPE}</code> instance, expandable to its human tasks and failed activities.
      </p>

      <ErrorBanner error={error} />

      {loading ? (
        <Spinner />
      ) : !data || data.ids.length === 0 ? (
        <div className="card">
          <Empty>No shipment review workflows yet. Trigger a failing shipping request to create one.</Empty>
        </div>
      ) : (
        data.ids.map((wfId) => {
          const wf = data.workflows.find((w) => w.workflowId === wfId);
          const tasks = data.tasksByWf.get(wfId) ?? [];
          const retries = data.retriesByWf.get(wfId) ?? [];
          return (
            <details className="tree" key={wfId} open={data.ids.length <= 3}>
              <summary>
                <span>{wf?.workflowType ?? REVIEW_WORKFLOW_TYPE}</span>
                <StatusBadge status={wf?.status ?? "RUNNING"} />
                <span className="spacer" />
                <span className="muted small mono">{wfId}</span>
              </summary>
              <div className="tree-body">
                <div className="subhead">
                  Human tasks <span className="pill-count">{tasks.length}</span>
                </div>
                {tasks.length === 0 ? (
                  <p className="muted small">None.</p>
                ) : (
                  <table>
                    <tbody>
                      {tasks.map((t) => (
                        <tr key={t.taskId}>
                          <td>
                            <Link to={`/tasks/${encodeURIComponent(t.taskId)}`}>{shortTaskName(t.taskName)}</Link>
                          </td>
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

                <div className="subhead">
                  Failed activities <span className="pill-count">{retries.length}</span>
                </div>
                {retries.length === 0 ? (
                  <p className="muted small">None.</p>
                ) : (
                  retries.map((r) => <RetryTaskItem key={r.taskId} task={r} onChanged={reload} />)
                )}
              </div>
            </details>
          );
        })
      )}
    </div>
  );
}
