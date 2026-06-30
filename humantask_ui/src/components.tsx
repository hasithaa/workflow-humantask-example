import { useState } from "react";
import * as api from "./api";
import { useAsync } from "./useAsync";
import { DynamicForm, fieldsFromObject, KeyValues } from "./dynamic";
import { formatTime, StatusBadge } from "./ui";
import { isPending, shortTaskName, type RetryTaskSummary } from "./types";

/**
 * A failed activity (manual retry task) with its actions: retry as-is, retry
 * with edited input, or fail permanently. The input form is generated
 * dynamically from the activity's recorded arguments.
 */
export function RetryTaskItem({
  task,
  onChanged,
}: {
  task: RetryTaskSummary;
  onChanged: () => void;
}) {
  const info = useAsync(() => api.getRetryTask(task.taskId), [task.taskId]);
  const [mode, setMode] = useState<"none" | "edit">("none");
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const pending = isPending(task.status);

  async function act(fn: () => Promise<void>) {
    setBusy(true);
    setError(null);
    try {
      await fn();
      onChanged();
    } catch (e) {
      setError((e as Error).message);
    } finally {
      setBusy(false);
    }
  }

  const args = info.data?.activityArgs ?? {};

  return (
    <div className="card">
      <div className="card-head">
        <h3>
          ⚙️ {task.activityName || shortTaskName(task.taskName)}{" "}
          <span className="muted small">activity</span>
        </h3>
        <StatusBadge status={task.status} />
      </div>
      <div className="card-body">
        {info.data?.errorMessage && (
          <div className="banner error" style={{ whiteSpace: "pre-wrap" }}>
            {info.data.errorMessage}
          </div>
        )}
        <div className="subhead">Activity arguments</div>
        <KeyValues data={args} />

        {error && <p className="error">{error}</p>}

        {pending && (
          <div className="btn-row" style={{ marginTop: 16 }}>
            <button className="btn primary" disabled={busy} onClick={() => act(() => api.retryActivity(task.taskId))}>
              Retry (same input)
            </button>
            <button className="btn" disabled={busy} onClick={() => setMode(mode === "edit" ? "none" : "edit")}>
              {mode === "edit" ? "Cancel edit" : "Retry with new input…"}
            </button>
            <button className="btn danger" disabled={busy} onClick={() => act(() => api.failActivity(task.taskId))}>
              Fail permanently
            </button>
          </div>
        )}

        {pending && mode === "edit" && (
          <div style={{ marginTop: 16 }}>
            <div className="subhead">Edit input and retry</div>
            <DynamicForm
              fields={fieldsFromObject(args)}
              submitLabel="Retry with this input"
              busy={busy}
              onSubmit={(payload) => act(() => api.retryActivityWithInput(task.taskId, payload))}
            />
          </div>
        )}

        {!pending && (
          <p className="muted small" style={{ marginTop: 12 }}>
            Decided {info.data?.decidedBy ? `by ${info.data.decidedBy} ` : ""}
            {formatTime(info.data?.decidedAt)}
          </p>
        )}
      </div>
    </div>
  );
}
