defmodule Molabhbot.Tag do
  use GenStateMachine, callback_mode: :state_functions
  alias Molabhbot.Telegram.Build
  alias Molabhbot.Telegram.Reply
  #alias Molabhbot.Search

  def init(%{chat_id: chat_id} = initial_data) do
    :gproc.reg({:n, :l, {:fsm, :tag, chat_id}})
    {:ok, :started, initial_data}
  end

  def started({:call, from}, {:new_msg, msg}, data) do
    "Ok, please enter tagged content. Type /tagdone when done."
    |> Build.chat_message(msg, %{force_reply: true})
    |> Reply.post_reply("sendMessage")
    {:next_state, :gather_tagged_content, data, [{:reply, from, :ok}]}
  end

  def gather_tagged_content({:call, from}, {:new_msg, %{"text" => "/tag"} = msg}, data) do
    "Already tagging. Add more content or type /tagdone when done."
    |> Build.chat_message(msg, %{force_reply: true})
    |> Reply.post_reply("sendMessage")

    {:next_state, :started, data, [{:reply, from, :ok}]}
  end
  def gather_tagged_content({:call, from}, {:new_msg, %{"text" => "/tagdone"} = msg}, data) do
    data.content
    |> split()
    |> tags_only()
    |> save(data.content)

    "Ok, thanks! I'll process the tagged content and let you know."
    |> Build.chat_message(msg, %{force_reply: true})
    |> Reply.post_reply("sendMessage")

    {:next_state, :started, %{data | content: ""}, [{:reply, from, :ok}]}
  end
  def gather_tagged_content({:call, from}, {:new_msg, msg}, %{content: so_far} = data) do
    new_content = so_far <> msg["text"]
    IO.inspect new_content, label: "content so far"

    "Enter more content. Type /tagdone when done."
    |> Build.chat_message(msg, %{force_reply: true})
    |> Reply.post_reply("sendMessage")

    # {:stop_and_reply, :normal, [{:reply, from, :ok}]}
    {:next_state, :gather_tagged_content, %{data | content: new_content}, [{:reply, from, :ok}]}
  end

  def split(content) when is_binary(content) do
    parts = String.split(content,
      # e.g. #mola.expiry_date[2018-04-30] or #test[value] or just #test
      ~r{#([\w-_]+)(\.[\w-_]+)?(\[[\w-_ ]+\])?}, include_captures: true
    )
    for p <- parts, do: hash_taggify(p)
  end

  defp hash_taggify("#" <> hashtag) do
    case Regex.run(~r{([\w-_]+)(\.([\w-_]+))?(\[([\w-_ ]+)\])?}, hashtag) do
      [_, ns, _, tag] -> {:hashtag, {ns, tag}}
      [_, tag, "", "", _, val] -> {:hashtag, tag, val}
      [_, ns, _, tag, _, val] -> {:hashtag, {ns, tag}, val}
      [_, tag] -> {:hashtag, tag}
    end
  end
  defp hash_taggify(other), do: other

# API

  def ensure_started(%{"chat" => %{"id" => chat_id}} = msg) do
    IO.inspect chat_id, label: "start process for chat id"

    case :gproc.where({:n, :l, {:fsm, :tag, chat_id}}) do
      :undefined ->
        initial_data = %{first_msg: msg, chat_id: chat_id, content: ""}
        GenStateMachine.start(__MODULE__, initial_data)
      pid when is_pid(pid) ->
        {:ok, pid}
    end
  end

  def new_msg(%{"chat" => %{"id" => chat_id}} = msg) do
    case :gproc.where({:n, :l, {:fsm, :tag, chat_id}}) do
      pid when is_pid(pid) ->
        GenStateMachine.call(pid, {:new_msg, msg})
    end
  end

  def already_tagging?(chat_id) do
    is_pid(:gproc.where({:n, :l, {:fsm, :tag, chat_id}}))
  end

  defp hashtag?({:hashtag, _, _}), do: true
  defp hashtag?({:hashtag, _}), do: true
  defp hashtag?(_), do: false

  defp tags_only(tags) do
    for t <- tags, hashtag?(t), do: t
  end

  defp save(tags, content) do
    IO.puts("**********************************************************")
    IO.inspect content, label: "content"
    IO.puts("**********************************************************")
    IO.inspect tags, label: "tags"
    IO.puts("**********************************************************")
    save_tags(tags)
  end

  defp save_tags([]), do: :ok
  defp save_tags([h|t]) do
    save_tag(h)
    save_tags(t)
  end

  defp save_tag({:hashtag, {ns, tag}, _val}) do
    #Search.find_or_create_tag(ns,tag)
  end
  defp save_tag({:hashtag, tag, _val}) do
    #Search.find_or_create_tag("__none",tag)
  end
  defp save_tag({:hashtag, {ns, tag}}) do
    #Search.find_or_create_tag(ns,tag)
  end
  defp save_tag({:hashtag, tag}) do
    #Search.find_or_create_tag("__none",tag)
  end
end
