# defmodule Memelex.My.TODOsTest do
#   use ExUnit.Case
#   alias Memelex.My.TODOs

#   test "creating a new TODO" do
#     title = "Test TODO"
#     {:ok, todo} = TODOs.create(title)
#     assert todo.title == title
#     assert todo.completed == false
#   end

#   test "listing all TODOs" do
#     title1 = "First TODO"
#     title2 = "Second TODO"
#     {:ok, todo1} = TODOs.create(title1)
#     {:ok, todo2} = TODOs.create(title2)

#     todos = TODOs.list()

#     assert Enum.count(todos) >= 2
#     assert Enum.any?(todos, &(&1.id == todo1.id))
#     assert Enum.any?(todos, &(&1.id == todo2.id))
#   end

#   test "completing a TODO" do
#     title = "Test TODO"
#     {:ok, todo} = TODOs.create(title)
#     assert todo.completed == false

#     {:ok, updated_todo} = TODOs.complete(todo.id)
#     assert updated_todo.completed == true
#   end

#   test "deleting a TODO" do
#     title = "Test TODO"
#     {:ok, todo} = TODOs.create(title)

#     todos_before_delete = TODOs.list()
#     assert Enum.any?(todos_before_delete, &(&1.id == todo.id))

#     :ok = TODOs.delete(todo.id)

#     todos_after_delete = TODOs.list()
#     assert Enum.all?(todos_after_delete, &(&1.id != todo.id))
#   end
# end
