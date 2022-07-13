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
end