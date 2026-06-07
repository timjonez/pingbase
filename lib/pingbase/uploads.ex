defmodule Pingbase.Uploads do
  @moduledoc """
  The Uploads context.

  This context is responsible for managing file uploads
  using S3-compatible storage with presigned URLs.
  """

  @default_expiry 3600

  @doc """
  Generates a presigned URL for uploading a file.
  """
  def presign_upload(filename, content_type) do
    bucket = System.get_env("S3_BUCKET", "pingbase-uploads")
    key = "#{Ecto.UUID.generate()}/#{filename}"
    region = System.get_env("S3_REGION", "us-east-1")
    host = System.get_env("S3_HOST", "s3.amazonaws.com")
    access_key = System.get_env("S3_ACCESS_KEY_ID")
    secret_key = System.get_env("S3_SECRET_ACCESS_KEY")

    if is_nil(access_key) or is_nil(secret_key) do
      # Fallback for dev: return a direct URL without signing
      {:ok, %{
        url: "https://#{host}/#{bucket}/#{key}",
        key: key,
        fields: %{
          "Content-Type" => content_type,
          "key" => key
        }
      }}
    else
      presigned_url = generate_presigned_url(
        access_key,
        secret_key,
        region,
        host,
        bucket,
        key,
        content_type,
        @default_expiry
      )

      {:ok, %{
        url: presigned_url,
        key: key,
        fields: %{
          "Content-Type" => content_type,
          "key" => key
        }
      }}
    end
  end

  @doc """
  Generates a presigned GET URL for downloading a file.
  """
  def presign_download(key) do
    bucket = System.get_env("S3_BUCKET", "pingbase-uploads")
    region = System.get_env("S3_REGION", "us-east-1")
    host = System.get_env("S3_HOST", "s3.amazonaws.com")
    access_key = System.get_env("S3_ACCESS_KEY_ID")
    secret_key = System.get_env("S3_SECRET_ACCESS_KEY")

    if is_nil(access_key) or is_nil(secret_key) do
      {:ok, "https://#{host}/#{bucket}/#{key}"}
    else
      presigned_url = generate_presigned_url(
        access_key,
        secret_key,
        region,
        host,
        bucket,
        key,
        "",
        @default_expiry
      )

      {:ok, presigned_url}
    end
  end

  defp generate_presigned_url(access_key, secret_key, region, host, bucket, key, content_type, expiry) do
    now = DateTime.utc_now()
    date_stamp = Calendar.strftime(now, "%Y%m%d")
    amz_date = Calendar.strftime(now, "%Y%m%dT%H%M%SZ")
    credential = "#{access_key}/#{date_stamp}/#{region}/s3/aws4_request"

    query_params = [
      "X-Amz-Algorithm=AWS4-HMAC-SHA256",
      "X-Amz-Credential=#{URI.encode_www_form(credential)}",
      "X-Amz-Date=#{amz_date}",
      "X-Amz-Expires=#{expiry}",
      "X-Amz-SignedHeaders=host"
    ]

    query_params =
      if content_type != "" do
        ["X-Amz-SignedHeaders=host%3Bcontent-type" | query_params]
      else
        query_params
      end

    query_string = Enum.join(query_params, "&")
    uri = "https://#{bucket}.#{host}/#{key}?#{query_string}"

    # Sign the request
    canonical_request = build_canonical_request(uri, host, content_type, amz_date)
    string_to_sign = build_string_to_sign(amz_date, date_stamp, region, canonical_request)
    signature = calculate_signature(secret_key, date_stamp, region, string_to_sign)

    "#{uri}&X-Amz-Signature=#{signature}"
  end

  defp build_canonical_request(uri, host, content_type, _amz_date) do
    headers =
      if content_type != "" do
        "host:#{host}\ncontent-type:#{content_type}\n"
      else
        "host:#{host}\n"
      end

    signed_headers =
      if content_type != "" do
        "host;content-type"
      else
        "host"
      end

    # Extract query string without leading ?
    query_string =
      case URI.parse(uri) do
        %{query: nil} -> ""
        %{query: query} -> query
      end

    # Remove X-Amz-Signature from query string if present
    query_string =
      query_string
      |> String.split("&")
      |> Enum.reject(&String.starts_with?(&1, "X-Amz-Signature="))
      |> Enum.join("&")

    "GET\n/\n#{query_string}\n#{headers}\n#{signed_headers}\nUNSIGNED-PAYLOAD"
  end

  defp build_string_to_sign(amz_date, date_stamp, region, canonical_request) do
    credential_scope = "#{date_stamp}/#{region}/s3/aws4_request"
    hashed_request = Base.encode16(:crypto.hash(:sha256, canonical_request), case: :lower)

    "AWS4-HMAC-SHA256\n#{amz_date}\n#{credential_scope}\n#{hashed_request}"
  end

  defp calculate_signature(secret_key, date_stamp, region, string_to_sign) do
    date_key = hmac_sha256("AWS4#{secret_key}", date_stamp)
    region_key = hmac_sha256(date_key, region)
    service_key = hmac_sha256(region_key, "s3")
    signing_key = hmac_sha256(service_key, "aws4_request")

    Base.encode16(hmac_sha256(signing_key, string_to_sign), case: :lower)
  end

  defp hmac_sha256(key, data) when is_binary(key) and is_binary(data) do
    :crypto.mac(:hmac, :sha256, key, data)
  end
end
