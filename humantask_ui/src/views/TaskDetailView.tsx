import { useState } from "react";
import { Link, useNavigate, useParams } from "react-router-dom";
import * as api from "../api";
import { useAsync } from "../useAsync";
import { COMPLETION_FORMS, DynamicForm, fieldsFromJsonSchema, KeyValues } from "../dynamic";
import { RetryTaskItem } from "../components";
import { isPending, shortTaskName } from "../types";
import { Empty, ErrorBanner, formatTime, Spinner, StatusBadge } from "../ui";

export default function TaskDetailView() {
  const { taskId = "" } = useParams();
  const navigate = useNavigate();
  const task = useAsync(() => api.getHumanTask(taskId), [taskId]);
  // Failed activities that belong to the same parent workflow as this task.
  const retries = useAsync(
    async () =>
      task.data
        ? api.listRetryTasks({ parentWorkflowId: task.data.parentWorkflowId })
        : Promise.resolve([]),
    [task.data?.parentWorkflowId],
  );

  const [busy, setBusy] = useState(false);
  const [actionError, setActionError] = useState<string | null>(null);

  async function act(fn: () => Promise<void>) {
    setBusy(true);
    setActionError(null);
    try {
      await fn();
      task.reload();
      retries.reload();
    } catch (e) {
      setActionError((e as Error).message);
    } finally {
      setBusy(false);
    }
  }

  if (task.loading) return <Spinner />;
  if (task.error || !task.data) {
    return (
      <div>
        <Link className="back-link" to="/tasks">← Back to tasks</Link>
        <ErrorBanner error={task.error ?? "Task not found"} />
      </div>
    );
  }

  const t = task.data;
  const shortName = shortTaskName(t.taskName);
  const pending = isPending(t.status);
  // Prefer the server-provided JSON schema; fall back to a known form config.
  const formFields = fieldsFromJsonSchema(t.formSchema) ?? COMPLETION_FORMS[shortName];

  return (
    <div>
      <Link className="back-link" to="/tasks">← Back to tasks</Link>

      <div className="card">
        <div className="card-head">
          <h3>{t.title || shortName}</h3>
          <StatusBadge status={t.status} />
        </div>
        <div className="card-body">
          {t.description && <p>{t.description}</p>}
          <KeyValues
            data={{
              "Task": shortName,
              "Task ID": t.taskId,
              "Parent workflow": t.parentWorkflowId,
              "Roles": t.userRoles.join(", "),
              "Created": formatTime(t.createdAt),
              "Closed": formatTime(t.closeTime),
              ...(t.completedBy ? { "Completed by": t.completedBy } : {}),
            }}
          />
        </div>
      </div>

      <div className="card">
        <div className="card-head"><h3>Task input</h3></div>
        <div className="card-body">
          <KeyValues data={t.payload} />
        </div>
      </div>

      {actionError && <div className="banner error">{actionError}</div>}

      {pending ? (
        <div className="card">
          <div className="card-head"><h3>Complete this task</h3></div>
          <div className="card-body">
            {shortName === "reviewErrorTask" && (
              <div className="btn-row" style={{ marginBottom: 16 }}>
                <button
                  className="btn primary"
                  disabled={busy}
                  onClick={() => act(() => api.completeHumanTask(t.taskId, { retryMessage: true }))}
                >
                  ✓ Approve retry
                </button>
                <button
                  className="btn"
                  disabled={busy}
                  onClick={() => act(() => api.completeHumanTask(t.taskId, { retryMessage: false }))}
                >
                  ✕ Reject (mark failed)
                </button>
              </div>
            )}

            {formFields ? (
              <DynamicForm
                fields={formFields}
                submitLabel="Complete task"
                busy={busy}
                onSubmit={(result) => act(() => api.completeHumanTask(t.taskId, result))}
              />
            ) : (
              <RawResultForm busy={busy} onSubmit={(result) => act(() => api.completeHumanTask(t.taskId, result))} />
            )}

            <div className="subhead">Or reject the task entirely</div>
            <FailForm busy={busy} onSubmit={(reason) => act(async () => {
              await api.failHumanTask(t.taskId, reason);
              navigate("/tasks");
            })} />
          </div>
        </div>
      ) : (
        <div className="card">
          <div className="card-head"><h3>Result</h3></div>
          <div className="card-body">
            {t.result ? <KeyValues data={t.result as Record<string, unknown>} /> : <Empty>No result recorded.</Empty>}
          </div>
        </div>
      )}

      <h2 className="subhead" style={{ fontSize: 13 }}>Failed activities in this workflow</h2>
      {retries.loading ? (
        <Spinner />
      ) : (retries.data ?? []).length === 0 ? (
        <div className="card"><Empty>None.</Empty></div>
      ) : (
        (retries.data ?? []).map((r) => <RetryTaskItem key={r.taskId} task={r} onChanged={() => { task.reload(); retries.reload(); }} />)
      )}
    </div>
  );
}

function RawResultForm({ busy, onSubmit }: { busy: boolean; onSubmit: (result: unknown) => void }) {
  const [text, setText] = useState("{\n  \n}");
  const [error, setError] = useState<string | null>(null);
  return (
    <div className="form">
      <div className="field">
        <label>Result (JSON)</label>
        <textarea className="mono" rows={6} value={text} onChange={(e) => setText(e.target.value)} />
      </div>
      {error && <p className="error">{error}</p>}
      <button
        className="btn primary"
        disabled={busy}
        onClick={() => {
          try {
            onSubmit(JSON.parse(text));
            setError(null);
          } catch (e) {
            setError(`Invalid JSON: ${(e as Error).message}`);
          }
        }}
      >
        Complete task
      </button>
    </div>
  );
}

function FailForm({ busy, onSubmit }: { busy: boolean; onSubmit: (reason: string) => void }) {
  const [reason, setReason] = useState("");
  return (
    <div className="form">
      <div className="field">
        <label>Reason</label>
        <input value={reason} onChange={(e) => setReason(e.target.value)} placeholder="Why is this task being failed?" />
      </div>
      <button className="btn danger" disabled={busy || !reason.trim()} onClick={() => onSubmit(reason.trim())}>
        Fail task
      </button>
    </div>
  );
}
