defmodule SymphonyElixir.Agenthub.Client do
  @moduledoc """
  HTTP client for Agenthub API.
  Handles bundle push/fetch, message board, and rate limiting.
  """

  require Logger

  @type bundle :: binary()
  @type commit_hash :: String.t()
  @type error :: {:error, String.t()}

  @doc """
  Push a git bundle to Agenthub.

  ## Parameters
  - bundle: Binary git bundle data
  - parent_hash: Optional parent commit hash

  ## Returns
  - {:ok, commit_hash} on success
  - {:error, reason} on failure
  """
  @spec push_bundle(bundle(), String.t() | nil) :: {:ok, commit_hash()} | error()
  def push_bundle(bundle, parent_hash \\ nil) do
    url = "#{base_url()}/api/git/push"

    headers = [
      {"authorization", "Bearer #{api_key()}"},
      {"content-type", "application/octet-stream"},
      {"x-parent-hash", parent_hash || ""}
    ]

    case Req.post(url, body: bundle, headers: headers, receive_timeout: 60_000) do
      {:ok, %{status: 200, body: body}} ->
        case decode_body(body) do
          {:ok, %{"hash" => hash}} ->
            Logger.info("Pushed bundle to Agenthub: #{hash}")
            {:ok, hash}

          {:ok, _other} ->
            {:error, "Unexpected response structure"}

          {:error, reason} ->
            {:error, "Failed to parse response: #{inspect(reason)}"}
        end

      {:ok, %{status: 429}} ->
        {:error, "Rate limit exceeded"}

      {:ok, %{status: status, body: body}} ->
        {:error, "HTTP #{status}: #{inspect(body)}"}

      {:error, %Req.TransportError{reason: reason}} ->
        {:error, "HTTP request failed: #{inspect(reason)}"}

      {:error, reason} ->
        {:error, "HTTP request failed: #{inspect(reason)}"}
    end
  end

  @doc """
  Fetch a git bundle from Agenthub by commit hash.

  ## Parameters
  - hash: Commit hash to fetch

  ## Returns
  - {:ok, bundle} on success
  - {:error, reason} on failure
  """
  @spec fetch_bundle(commit_hash()) :: {:ok, bundle()} | error()
  def fetch_bundle(hash) do
    url = "#{base_url()}/api/git/fetch/#{hash}"
    headers = [{"authorization", "Bearer #{api_key()}"}]

    case Req.get(url, headers: headers, receive_timeout: 60_000) do
      {:ok, %{status: 200, body: body}} ->
        Logger.info("Fetched bundle from Agenthub: #{hash}")
        {:ok, body}

      {:ok, %{status: 404}} ->
        {:error, "Bundle not found: #{hash}"}

      {:ok, %{status: status, body: body}} ->
        {:error, "HTTP #{status}: #{inspect(body)}"}

      {:error, %Req.TransportError{reason: reason}} ->
        {:error, "HTTP request failed: #{inspect(reason)}"}

      {:error, reason} ->
        {:error, "HTTP request failed: #{inspect(reason)}"}
    end
  end

  @doc """
  Get DAG leaves (commits with no children).

  ## Returns
  - {:ok, leaves} on success (list of maps with hash, agent_id, created_at)
  - {:error, reason} on failure
  """
  @spec get_leaves() :: {:ok, list(map())} | error()
  def get_leaves do
    url = "#{base_url()}/api/git/leaves"
    headers = [{"authorization", "Bearer #{api_key()}"}]

    case Req.get(url, headers: headers) do
      {:ok, %{status: 200, body: body}} ->
        case decode_body(body) do
          {:ok, %{"leaves" => leaves}} -> {:ok, leaves}
          {:ok, _other} -> {:error, "Unexpected response structure"}
          {:error, reason} -> {:error, "Failed to parse response: #{inspect(reason)}"}
        end

      {:ok, %{status: status, body: body}} ->
        {:error, "HTTP #{status}: #{inspect(body)}"}

      {:error, %Req.TransportError{reason: reason}} ->
        {:error, "HTTP request failed: #{inspect(reason)}"}

      {:error, reason} ->
        {:error, "HTTP request failed: #{inspect(reason)}"}
    end
  end

  @doc """
  Get diff between two commits.

  ## Parameters
  - from_hash: Starting commit hash
  - to_hash: Ending commit hash

  ## Returns
  - {:ok, diff_text} on success
  - {:error, reason} on failure
  """
  @spec get_diff(commit_hash(), commit_hash()) :: {:ok, String.t()} | error()
  def get_diff(from_hash, to_hash) do
    url = "#{base_url()}/api/git/diff/#{from_hash}/#{to_hash}"
    headers = [{"authorization", "Bearer #{api_key()}"}]

    case Req.get(url, headers: headers) do
      {:ok, %{status: 200, body: body}} ->
        case decode_body(body) do
          {:ok, %{"diff" => diff}} -> {:ok, diff}
          {:ok, _other} -> {:error, "Unexpected response structure"}
          {:error, reason} -> {:error, "Failed to parse response: #{inspect(reason)}"}
        end

      {:ok, %{status: 429}} ->
        {:error, "Rate limit exceeded (60 diffs/hour)"}

      {:ok, %{status: status, body: body}} ->
        {:error, "HTTP #{status}: #{inspect(body)}"}

      {:error, %Req.TransportError{reason: reason}} ->
        {:error, "HTTP request failed: #{inspect(reason)}"}

      {:error, reason} ->
        {:error, "HTTP request failed: #{inspect(reason)}"}
    end
  end

  @doc """
  Post a message to a channel.

  ## Parameters
  - channel_name: Channel name (created if doesn't exist)
  - content: Message content

  ## Returns
  - {:ok, post_id} on success
  - {:error, reason} on failure
  """
  @spec post_message(String.t(), String.t()) :: {:ok, integer()} | error()
  def post_message(channel_name, content) do
    url = "#{base_url()}/api/channels/#{channel_name}/posts"

    headers = [
      {"authorization", "Bearer #{api_key()}"},
      {"content-type", "application/json"}
    ]

    body = Jason.encode!(%{content: content})

    case Req.post(url, body: body, headers: headers) do
      {:ok, %{status: 200, body: resp_body}} ->
        case decode_body(resp_body) do
          {:ok, %{"id" => id}} ->
            Logger.info("Posted message to channel #{channel_name}: #{id}")
            {:ok, id}

          {:ok, _other} ->
            {:error, "Unexpected response structure"}

          {:error, reason} ->
            {:error, "Failed to parse response: #{inspect(reason)}"}
        end

      {:ok, %{status: 429}} ->
        {:error, "Rate limit exceeded (60 posts/hour)"}

      {:ok, %{status: status, body: resp_body}} ->
        {:error, "HTTP #{status}: #{inspect(resp_body)}"}

      {:error, %Req.TransportError{reason: reason}} ->
        {:error, "HTTP request failed: #{inspect(reason)}"}

      {:error, reason} ->
        {:error, "HTTP request failed: #{inspect(reason)}"}
    end
  end

  # Private helpers

  defp base_url do
    Application.get_env(:symphony_elixir, :agenthub_url, "http://localhost:8080")
  end

  defp api_key do
    System.get_env("AGENTHUB_API_KEY") ||
      raise "AGENTHUB_API_KEY environment variable not set"
  end

  # Req auto-decodes JSON when content-type is application/json.
  # When the body is already a map, skip Jason.decode; otherwise decode the string.
  defp decode_body(body) when is_map(body), do: {:ok, body}
  defp decode_body(body) when is_binary(body), do: Jason.decode(body)
  defp decode_body(body), do: {:ok, body}
end
