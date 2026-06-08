defmodule GuitarVault.Uploads do
  @moduledoc """
  Filesystem storage for uploaded files.

  Binaries are written under a runtime-resolved directory (default
  `priv/uploads`, override with the `:uploads_dir` app env) and served by a
  dedicated `Plug.Static` mounted at `/uploads` in the endpoint. This module is
  the single seam to swap in object storage (e.g. S3) later — only `store/2`,
  `delete/1` and `url/1` would change.
  """

  @doc "Absolute path to the uploads directory, ensuring it exists."
  def dir do
    base =
      Application.get_env(:guitar_vault, :uploads_dir) ||
        Path.join(to_string(:code.priv_dir(:guitar_vault)), "uploads")

    File.mkdir_p!(base)
    base
  end

  @doc """
  Copies a file from `source_path` into storage under a fresh unique name,
  preserving the extension of `original_name`. Returns the stored filename.
  """
  def store(source_path, original_name) do
    filename = Ecto.UUID.generate() <> Path.extname(original_name)
    File.cp!(source_path, Path.join(dir(), filename))
    filename
  end

  @doc "Removes a stored file. Missing files are ignored."
  def delete(filename) when is_binary(filename) do
    _ = File.rm(Path.join(dir(), filename))
    :ok
  end

  @doc "Public URL path for a stored filename."
  def url(filename), do: "/uploads/#{filename}"
end
