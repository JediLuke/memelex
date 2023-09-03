
defmodule Memelex.StructLib.Project.V001 do
  @moduledoc """
  This Project struct contains the following fields:

    id: A unique identifier for the project.
    title: The project's title.
    description: A brief description of the project.
    owner: The project owner's name or identifier.
    start_date: The project's start date.
    end_date: The project's end date.
    milestones: A list of project milestones. Each milestone has an id, title, description, due_date, and a list of associated tasks.
    tasks: A list of all tasks in the project, regardless of the milestone they belong to. Each task has an id, title, description, status, start_date, end_date, and a list of dependencies (other task IDs that must be completed before this task can start).
  """

  defstruct [
    :id,
    :title,
    :description,
    :owner,
    :start_date,
    :end_date,
    :milestones,
    :tasks,
    :collection
  ]
end
