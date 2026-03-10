defmodule SymphonyElixir.Harness.Runner do
  @moduledoc """
  Subprocess wrapper for Harness Engineering 6-Gate QA.
  Executes run-gates.sh and parses JSON results.
  """

  require Logger

  @type gate_result :: %{
          name: String.t(),
          status: String.t(),
          duration_ms: integer(),
          output: String.t()
        }

  @type gate_results :: %{
          gates: list(gate_result()),
          overall: String.t(),
          total_duration_ms: integer()
        }

  @type error :: {:error, String.t()}

  @doc """
  Run Harness 6-Gate QA on a workspace.

  ## Parameters
  - workspace_dir: Absolute path to project workspace
  - opts: Options map
    - fail_fast: Stop on first gate failure (default: true)
    - timeout_ms: Maximum execution time (default: 600_000 = 10 minutes)

  ## Returns
  - {:ok, gate_results} on success (even if gates fail)
  - {:error, reason} on script error
  """
  @spec run_gates(String.t(), map()) :: {:ok, gate_results()} | error()
  def run_gates(workspace_dir, opts \\ %{}) do
    fail_fast = Map.get(opts, :fail_fast, true)
    timeout_ms = Map.get(opts, :timeout_ms, 600_000)

    script_path = harness_script_path()

    args = [
      "--project-root",
      workspace_dir,
      "--output-format",
      "json"
    ]

    args = if fail_fast, do: args ++ ["--fail-fast"], else: args

    Logger.info("Running Harness gates: #{script_path} #{Enum.join(args, " ")}")

    case System.cmd(script_path, args,
           stderr_to_stdout: true,
           cd: workspace_dir,
           env: [{"PATH", System.get_env("PATH")}],
           timeout: timeout_ms
         ) do
      {output, 0} ->
        parse_results(output)

      {output, 1} ->
        # Gates failed, but script succeeded
        parse_results(output)

      {output, exit_code} ->
        Logger.error("Harness script error (exit #{exit_code}): #{output}")
        {:error, "Script exited with code #{exit_code}: #{output}"}
    end
  rescue
    e in ErlangError ->
      if e.original == :timeout do
        {:error, "Harness gates timed out"}
      else
        {:error, "Unexpected error: #{inspect(e)}"}
      end
  end

  @doc """
  Parse JSON output from run-gates.sh.

  ## Parameters
  - output: Raw stdout from script

  ## Returns
  - {:ok, gate_results} on success
  - {:error, reason} on parse failure
  """
  @spec parse_results(String.t()) :: {:ok, gate_results()} | error()
  def parse_results(output) do
    case Jason.decode(output) do
      {:ok, %{"gates" => gates, "overall" => overall, "total_duration_ms" => duration}} ->
        results = %{
          gates:
            Enum.map(gates, fn gate ->
              %{
                name: gate["name"],
                status: gate["status"],
                duration_ms: gate["duration_ms"],
                output: gate["output"]
              }
            end),
          overall: overall,
          total_duration_ms: duration
        }

        Logger.info("Harness gates completed: #{overall} (#{duration}ms)")
        {:ok, results}

      {:ok, _} ->
        {:error, "Invalid JSON structure: missing required fields"}

      {:error, reason} ->
        {:error, "Failed to parse JSON: #{inspect(reason)}"}
    end
  end

  # Private helpers

  defp harness_script_path do
    Application.get_env(
      :symphony_elixir,
      :harness_script_path,
      "/home/lunark/projects/ai-native-agentic-org/harness-engineering/.harness/run-gates.sh"
    )
  end
end
