defmodule Molabhbot.SearchTest do
  use Molabhbot.DataCase

  alias Molabhbot.Search

  describe "namespaces" do
    alias Molabhbot.Search.Namespace

    @valid_attrs %{ns: "some ns"}
    @update_attrs %{ns: "some updated ns"}
    @invalid_attrs %{ns: nil}

    def namespace_fixture(attrs \\ %{}) do
      {:ok, namespace} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Search.create_namespace()

      namespace
    end

    test "list_namespaces/0 returns all namespaces" do
      namespace = namespace_fixture()
      assert Search.list_namespaces() == [namespace]
    end

    test "get_namespace!/1 returns the namespace with given id" do
      namespace = namespace_fixture()
      assert Search.get_namespace!(namespace.id) == namespace
    end

    test "create_namespace/1 with valid data creates a namespace" do
      assert {:ok, %Namespace{} = namespace} = Search.create_namespace(@valid_attrs)
      assert namespace.ns == "some ns"
    end

    test "create_namespace/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Search.create_namespace(@invalid_attrs)
    end

    test "update_namespace/2 with valid data updates the namespace" do
      namespace = namespace_fixture()
      assert {:ok, namespace} = Search.update_namespace(namespace, @update_attrs)
      assert %Namespace{} = namespace
      assert namespace.ns == "some updated ns"
    end

    test "update_namespace/2 with invalid data returns error changeset" do
      namespace = namespace_fixture()
      assert {:error, %Ecto.Changeset{}} = Search.update_namespace(namespace, @invalid_attrs)
      assert namespace == Search.get_namespace!(namespace.id)
    end

    test "delete_namespace/1 deletes the namespace" do
      namespace = namespace_fixture()
      assert {:ok, %Namespace{}} = Search.delete_namespace(namespace)
      assert_raise Ecto.NoResultsError, fn -> Search.get_namespace!(namespace.id) end
    end

    test "change_namespace/1 returns a namespace changeset" do
      namespace = namespace_fixture()
      assert %Ecto.Changeset{} = Search.change_namespace(namespace)
    end
  end

  describe "tags" do
    alias Molabhbot.Search.Tag

    setup do
      namespace = namespace_fixture(%{ns: "bob"})
      {:ok, namespace: namespace}
    end

    @valid_namespace %{ns: "tag_fixture_namespace"}
    @valid_attrs %{name: "some name"}
    @update_attrs %{name: "some updated name"}
    @invalid_attrs %{name: nil}

    def tag_fixture(attrs \\ %{}) do
      {:ok, namespace} = Search.create_namespace(@valid_namespace)
      {:ok, tag} =
        Enum.into(%{namespace_id: namespace.id}, attrs)
        |> Enum.into(@valid_attrs)
        |> Search.create_tag()
      tag
    end

    test "list_tags/0 returns all tags" do
      tag = tag_fixture()
      assert Search.list_tags() == [tag]
    end

    test "get_tag!/1 returns the tag with given id" do
      tag = tag_fixture()
      assert Search.get_tag!(tag.id) == tag
    end

    test "create_tag/1 with valid data creates a tag", %{namespace: namespace} do
      assert {:ok, %Tag{} = tag} = Search.create_tag(Enum.into(%{namespace_id: namespace.id}, @valid_attrs))
      assert tag.name == "some name"
    end

    test "create_tag/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Search.create_tag(@invalid_attrs)
    end

    test "update_tag/2 with valid data updates the tag" do
      tag = tag_fixture()
      assert {:ok, tag} = Search.update_tag(tag, @update_attrs)
      assert %Tag{} = tag
      assert tag.name == "some updated name"
    end

    test "update_tag/2 with invalid data returns error changeset" do
      tag = tag_fixture()
      assert {:error, %Ecto.Changeset{}} = Search.update_tag(tag, @invalid_attrs)
      assert tag == Search.get_tag!(tag.id)
    end

    test "delete_tag/1 deletes the tag" do
      tag = tag_fixture()
      assert {:ok, %Tag{}} = Search.delete_tag(tag)
      assert_raise Ecto.NoResultsError, fn -> Search.get_tag!(tag.id) end
    end

    test "change_tag/1 returns a tag changeset" do
      tag = tag_fixture()
      assert %Ecto.Changeset{} = Search.change_tag(tag)
    end

    test "get_or_insert_tag/2" do
      {:ok, tag_ev} = Search.get_or_insert_tag("mola", "event")
      {:ok, tag_date1} = Search.get_or_insert_tag("mola", "date")
      {:ok, tag_date2} = Search.get_or_insert_tag("mola", "date")
      assert tag_ev.name == "event"
      assert (tag_ev |> Repo.preload(:namespace)).namespace.ns == "mola"
      assert tag_date1.name == "date"
      assert tag_date1.id == tag_date2.id
      assert (tag_date1 |> Repo.preload(:namespace)).namespace.id == (tag_date2 |> Repo.preload(:namespace)).namespace.id
    end
  end
end
