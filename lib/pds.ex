HTTPoison.start()

defmodule PDS do
  # this is for everyone to figure out for themselves :)
  @users %{
    "neil" => %{
      :uid => "0xd349bcad8f05460cfefc9168900605e6e6f97db2",
      :pub =>
        "0xac34f582de44be3d2860101cad51695d6a9fa229f256a4b7c0e821d5fee24cbad0d441b77b1549bb1ce6d84570f8e8b7ad322ac47e5e76ac174bc44ec58333dc",
      :priv => "0x76eda7b636778bdf5b9176f8fd630c4a7f13c04c72ff63303600ea020ce024b0"
    }
  }
  @service URI.parse("https://pdsapi.dase.io:8081/api/")
  @offer_permutations [{:in, "buy"}, {:in, "sell"}, {:out, "buy"}, {:out, "sell"}]
  @seconds_in_a_day 86400
  @vault_id 2

  defp gurler(gurls) do
    URI.parse(
      URI.merge(
        @service,
        gurls
      )
      |> to_string()
    )
  end

  defp creds(user) do
    @users[user]
  end

  def a_simple_test(user) do
    creds(user)
  end

  def balances(user) do
    if Map.has_key?(@users, user) do
      gurl = gurler("balances?zetoniumUserId=#{creds(user).uid}")

      IO.puts(gurl)

      case HTTPoison.get(gurl) do
        {:ok,
         %HTTPoison.Response{
           status_code: 200,
           body: body
         }} ->
          IO.puts("Silver Leos: " <> Poison.decode!(body)["silver_leos"])
          IO.puts("  Gold Leos: " <> Poison.decode!(body)["gold_leos"])

        {:ok, %HTTPoison.Response{status_code: 404}} ->
          IO.puts("Not found :(")

        {:error, %HTTPoison.Error{reason: reason}} ->
          IO.inspect(reason)
      end
    else
      IO.puts("User #{user} does not exist.")
    end
  end

  def offers(user, direction, tx_type) do
    if Map.has_key?(@users, user) do
      gurl =
        gurler(
          "offers?userId=#{creds(user).uid}&limit=100&offerDirectionType=#{String.upcase(direction)}&tradeType=#{String.upcase(tx_type)}"
        )

      IO.puts(gurl)

      case HTTPoison.get(gurl) do
        {:ok,
         %HTTPoison.Response{
           status_code: 200,
           body: body
         }} ->
          total_count = Poison.decode!(body)["totalCount"]

          IO.puts(
            "You have " <>
              Integer.to_string(total_count) <>
              " #{String.upcase(direction)} #{String.upcase(tx_type)} offer(s)."
          )

          pp_offer = fn _idx, offer ->
            # IO.puts(Integer.to_string(idx))
            {:ok, o} = offer

            if Map.has_key?(o, "assetId") do
              IO.puts("  Asset ID: " <> o["assetId"])
            end

            if Map.has_key?(o, "tagId") do
              IO.puts("PLEASE NOTE THIS IS A TAG!")
              IO.puts("    Tag ID: " <> o["tagId"])
            end

            IO.puts("     Buyer: " <> o["buyerId"])
            IO.puts("    Seller: " <> o["sellerId"])
            IO.puts("Term Sheet: " <> o["termSheetTemplate"])
            IO.puts("   License: " <> o["licenseType"])
            {:ok, dt, 0} = DateTime.from_iso8601(o["createdAt"])
            IO.puts("   Created: " <> DateTime.to_string(dt))

            {:ok, ndt} = DateTime.now("Etc/UTC")
            dd = DateTime.diff(ndt, dt)
            ddd = div(dd, @seconds_in_a_day)

            IO.puts(
              "This offer is " <>
                Integer.to_string(dd) <>
                " seconds old, or " <> Integer.to_string(ddd) <> " day(s)."
            )
          end

          if total_count > 0 do
            Enum.each(
              0..(total_count - 1),
              &pp_offer.(&1, Enum.fetch(Poison.decode!(body)["offers"], &1))
            )
          end

        {:ok, %HTTPoison.Response{status_code: 404}} ->
          IO.puts("Not found :(")

        {:error, %HTTPoison.Error{reason: reason}} ->
          IO.inspect(reason)
      end
    else
      IO.puts("User #{user} does not exist.")
    end
  end

  def all_offers(user) do
    IO.puts("All Incoming Offers")

    for {:in, tx_type} <- @offer_permutations do
      offers(user, to_string(:in), tx_type)
    end

    IO.puts("All Outgoing Offers")

    for {:out, tx_type} <- @offer_permutations do
      offers(user, to_string(:out), tx_type)
    end
  end

  def deals(user) do
    if Map.has_key?(@users, user) do
      gurl = gurler("deals?userId=#{creds(user).uid}&limit=100")

      IO.puts(gurl)

      case HTTPoison.get(gurl) do
        {:ok,
         %HTTPoison.Response{
           status_code: 200,
           body: body
         }} ->
          total_count = Poison.decode!(body)["totalCount"]

          IO.puts(
            "You have " <>
              Integer.to_string(total_count) <>
              " deal(s)."
          )

          pp_deal = fn _idx, deal ->
            # IO.puts(Integer.to_string(idx))
            {:ok, d} = deal

            if Map.has_key?(d, "assetId") do
              # note that this is an int, not a string, in this json payload
              IO.puts("  Asset ID: " <> Integer.to_string(d["assetId"]))
            end

            if Map.has_key?(d, "tagId") do
              IO.puts("PLEASE NOTE THIS IS A TAG!")
              IO.puts("    Tag ID: " <> d["tagId"])
            end

            IO.puts("   License: " <> d["licenseType"])

            {:ok, dt, 0} = DateTime.from_iso8601(d["dateTime"])
            IO.puts("  DateTime: " <> DateTime.to_string(dt))
          end

          if total_count > 0 do
            Enum.each(
              0..(total_count - 1),
              &pp_deal.(&1, Enum.fetch(Poison.decode!(body)["deals"], &1))
            )
          end

        {:ok, %HTTPoison.Response{status_code: 404}} ->
          IO.puts("Not found :(")

        {:error, %HTTPoison.Error{reason: reason}} ->
          IO.inspect(reason)
      end
    else
      IO.puts("User #{user} does not exist.")
    end
  end

  def licenses(user) do
    if Map.has_key?(@users, user) do
      gurl = gurler("licenses?userId=#{creds(user).uid}&limit=100")

      IO.puts(gurl)

      case HTTPoison.get(gurl) do
        {:ok,
         %HTTPoison.Response{
           status_code: 200,
           body: body
         }} ->
          total_count = Poison.decode!(body)["totalCount"]

          IO.puts(
            "You have " <>
              Integer.to_string(total_count) <>
              " licenses(s)."
          )

          pp_license = fn _idx, license ->
            # IO.puts(Integer.to_string(idx))
            {:ok, l} = license

            if Map.has_key?(l, "assetId") do
              # note that this is an int, not a string, in this json payload
              IO.puts("  Asset ID: " <> Integer.to_string(l["assetId"]))
            end

            if Map.has_key?(l, "tagId") do
              IO.puts("PLEASE NOTE THIS IS A TAG!")
              IO.puts("    Tag ID: " <> l["tagId"])
            end

            IO.puts("   License: " <> l["licenseType"])

            {:ok, dt, 0} = DateTime.from_iso8601(l["dateTime"])
            IO.puts("  DateTime: " <> DateTime.to_string(dt))
          end

          if total_count > 0 do
            Enum.each(
              0..(total_count - 1),
              &pp_license.(&1, Enum.fetch(Poison.decode!(body)["licenses"], &1))
            )
          end

        {:ok, %HTTPoison.Response{status_code: 404}} ->
          IO.puts("Not found :(")

        {:error, %HTTPoison.Error{reason: reason}} ->
          IO.inspect(reason)
      end
    else
      IO.puts("User #{user} does not exist.")
    end
  end

  defp pretty_print_asset(user, a) do
    if Map.has_key?(a, "assetId") do
      # note that this is an int, not a string, in this json payload
      IO.puts("       Asset ID: " <> Integer.to_string(a["assetId"]))
    end

    if Map.has_key?(a, "tagId") do
      IO.puts("PLEASE NOTE THIS IS A TAG!")
      IO.puts("         Tag ID: " <> a["tagId"])
    end

    IO.puts("    Description: " <> a["description"])
    IO.puts("      File Type: " <> a["assetContentType"])

    if creds(user).uid == a["ownerId"] do
      IO.puts("               Note that user " <> user <> " is the owner of this asset.")
    else
      IO.puts("               Note that user " <> user <> " is NOT the owner of this asset.")
    end

    IO.puts("          Owner: " <> a["ownerId"])

    {:ok, dt, 0} = DateTime.from_iso8601(a["createdAt"])
    IO.puts("        Created: " <> DateTime.to_string(dt))

    {:ok, ndt} = DateTime.now("Etc/UTC")
    dd = DateTime.diff(ndt, dt)
    ddd = div(dd, @seconds_in_a_day)

    IO.puts(
      "This asset is " <>
        Integer.to_string(dd) <>
        " seconds old, or " <> Integer.to_string(ddd) <> " day(s)."
    )
  end

  defp assets_rest_call(user, gurl) do
    case HTTPoison.get(gurl) do
      {:ok,
       %HTTPoison.Response{
         status_code: 200,
         body: body
       }} ->
        if is_map(Poison.decode!(body)) do
          total_count = Poison.decode!(body)["totalCount"]

          IO.puts(
            "You have " <>
              Integer.to_string(total_count) <>
              " assets(s)."
          )

          pp_asset = fn idx, asset ->
            IO.puts("\n Index Position: " <> Integer.to_string(idx))
            {:ok, a} = asset
            pretty_print_asset(user, a)
          end

          if total_count > 0 do
            Enum.each(
              0..(total_count - 1),
              &pp_asset.(&1, Enum.fetch(Poison.decode!(body)["assets"], &1))
            )
          end
        else
          asset = Enum.fetch(Poison.decode!(body), 0)
          {:ok, a} = asset
          pretty_print_asset(user, a)
        end

      {:ok, %HTTPoison.Response{status_code: 404}} ->
        IO.puts("Not found :(")

      {:error, %HTTPoison.Error{reason: reason}} ->
        IO.inspect(reason)
    end
  end

  def assets(user) do
    if Map.has_key?(@users, user) do
      gurl = gurler("assets?ownerIds=#{creds(user).uid}&limit=100")
      IO.puts(gurl)
      assets_rest_call(user, gurl)
    else
      IO.puts("User #{user} does not exist.")
    end
  end

  # Note its plural and in theory is a list but I don't think they handle it as a list, yet.
  def assets(user, assetIds) do
    if Map.has_key?(@users, user) do
      gurl = gurler("assets?ownerIds=#{creds(user).uid}&assetIds=#{assetIds}")
      IO.puts(gurl)
      assets_rest_call(user, gurl)
    else
      IO.puts("User #{user} does not exist.")
    end
  end

  def upload_and_register(user, publish_dir) do
    if Map.has_key?(@users, user) do
      # hardcoded to 2 which is PDS Goog or AWS, cannot remember

      do_upload = fn file ->
        {signature, vault_url, everything} = get_access_ticket(user)
        headers = get_upload_session(everything, vault_url)
        asset_name = upload_file(vault_url, headers["vault-session-id"], file)
        IO.inspect(asset_name)

        # "vtid=1:|:avid=:|:asid=5225fb689f.ed1aef1da30d1537a848f8d1187bd3e746bd3d08bb933bc6239f02e47e6d21ba0f55faf43603b820fab6d2b2cff62b67c05103ed1026f56642284231c650dd9eda04d2281847ac0d4023313466de4f5022006a4d4ce394a86e31386d0b5b2dc8c1cfbabb9d2e63042928f8ba2f3f727e:|:mime=image/svg+xml"
        pds_demarcation_hack = ":|:"

        asset_url =
          "vtid=#{@vault_id}#{pds_demarcation_hack}avid=#{pds_demarcation_hack}asid=#{asset_name}#{pds_demarcation_hack}"

        IO.inspect(asset_url)
        register_asset(user, asset_url, Path.basename(file))
      end

      latest_publications = list_all(publish_dir)
      Enum.each(latest_publications, &do_upload.(&1))
    else
      IO.puts("User #{user} does not exist.")
    end
  end

  defp get_access_ticket(user) do
    # hardcoded to 2 which is PDS Goog or AWS, cannot remember
    gurl =
      gurler(
        "tokens?accessType=UPLOAD&userId=#{creds(user).uid}&userPubKey=#{creds(user).pub}&vaultId=#{@vault_id}"
      )

    IO.puts(gurl)

    case HTTPoison.get(gurl) do
      {:ok,
       %HTTPoison.Response{
         status_code: 200,
         body: body
       }} ->
        signature = Poison.decode!(body)["signature"]
        vault_url = Poison.decode!(body)["vaultUrl"]

        dec_payload = Poison.decode!(body)
        ree_payload = to_string(Poison.encode!(dec_payload))
        IO.puts(ree_payload)
        enc_ree = Base.url_encode64(ree_payload)
        IO.puts(enc_ree)

        {signature, vault_url, enc_ree}

      {:ok, %HTTPoison.Response{status_code: 404}} ->
        IO.puts("Not found :(")

      {:error, %HTTPoison.Error{reason: reason}} ->
        IO.inspect(reason)
    end
  end

  defp get_upload_session(access_ticket_encoded, vault_url) do
    gurls = "/getsession?ticket=#{access_ticket_encoded}"

    gurl =
      URI.parse(
        URI.merge(
          vault_url,
          gurls
        )
        |> to_string()
      )

    IO.puts(gurl)

    case HTTPoison.get(gurl) do
      {:ok,
       %HTTPoison.Response{
         status_code: 200,
         headers: headers,
         body: body
       }} ->
        Enum.into(headers, %{})

      {:ok, %HTTPoison.Response{status_code: 404}} ->
        IO.puts("Not found :(")

      {:error, %HTTPoison.Error{reason: reason}} ->
        IO.inspect(reason)
    end
  end

  defp upload_file(vault_url, session_id, path_to_file) do
    IO.puts(
      "Being asked to upload " <>
        path_to_file <> " to " <> vault_url <> " with session id " <> session_id
    )

    headers = [{"Content-type", "multipart/form-data"}]

    gurls = "/upload?sid=#{session_id}"

    gurl =
      URI.parse(
        URI.merge(
          vault_url,
          gurls
        )
        |> to_string()
      )

    IO.puts(gurl)

    form =
      {:multipart,
       [
         {:file, path_to_file,
          {"form-data", [{:name, "file"}, {:filename, Path.basename(path_to_file)}]}, []}
       ]}

    case HTTPoison.post(gurl, form, headers, []) do
      {:ok,
       %HTTPoison.Response{
         status_code: 200,
         headers: headers,
         body: body
       }} ->
        IO.inspect(body)
        asset_id = Poison.decode!(body)["asset"]
        IO.inspect(asset_id)
        asset_id["name"]

      {:ok, %HTTPoison.Response{status_code: 404}} ->
        IO.puts("Not found :(")

      {:error, %HTTPoison.Error{reason: reason}} ->
        IO.inspect(reason)
    end
  end

  defp register_asset(user, asset_url, asset_description) do
    IO.puts(
      "Being asked to register " <>
        asset_description
    )

    headers = [{"Content-type", "application/json"}]

    gurl = gurler("assets/create")

    IO.puts(gurl)

    form = %{
      ownerId: creds(user).uid,
      ownerCredentials: creds(user).priv,
      dataArr: [
        %{
          assetUrl: asset_url,
          description: asset_description
        }
      ]
    }

    IO.inspect(form)

    dec_payload = JSON.encode!(form)
    #    ree_payload = to_string(Poison.code!(form))

    IO.inspect(dec_payload)

    ree_payload = to_string(dec_payload)
    IO.puts(ree_payload)

    case HTTPoison.post(gurl, ree_payload, headers, []) do
      {:ok,
       %HTTPoison.Response{
         status_code: 200,
         body: body
       }} ->
        IO.inspect(body)

      {:ok, %HTTPoison.Response{status_code: 404}} ->
        IO.puts("Not found :(")

      {:error, %HTTPoison.Error{reason: reason}} ->
        IO.inspect(reason)
    end
  end

  def list_all(filepath) do
    _list_all(filepath)
  end

  defp _list_all(filepath) do
    cond do
      String.contains?(filepath, ".git") -> []
      true -> expand(File.ls(filepath), filepath)
    end
  end

  defp expand({:ok, files}, path) do
    files
    |> Enum.flat_map(&_list_all("#{path}/#{&1}"))
  end

  defp expand({:error, _}, path) do
    [path]
  end
end
