defmodule Memelex.Lib.Structs.MemexConcepts.V01.Project do
  @moduledoc """
  Represents the essence of a project.

  A project is an organized effort towards achieving certain goals or deliverables. This struct captures the core aspects of a project, while delegating specific details to sub-structures like %Timeline{} or %ProjectPlan{}.

  ## Fields:

  - `name`: The name or title of the project.
  - `description`: A brief overview or summary of the project.
  - `timeline`: The expected start and end dates of the project.
  - `status`: The current status of the project (e.g., Planning, In Progress, Completed).
  - `participants`: List of individuals or teams involved in the project.
  - `plan`: A detailed plan for the project, encapsulating milestones, tasks, and other key details.
  - `resources`: Resources associated with the project, which could be documents, tools, budgets, etc.
  - `goals`: The objectives or outcomes the project aims to achieve.
  - `notes`: Miscellaneous notes or comments about the project.
  - `report`: A report or evaluation summarizing the project's outcomes and any other relevant data.
  """

  @derive Jason.Encoder

  defstruct name: nil,
            description: nil,
            timeline: nil,
            status: nil,
            participants: [],
            plan: nil,
            resources: [],
            goals: [],
            notes: nil,
            report: nil

  @type t :: %__MODULE__{
          name: String.t(),
          description: String.t(),
          timeline: Timeline.t(),
          status: atom(),
          participants: [String.t()],
          plan: ProjectPlan.t(),
          resources: [Resource.t()],
          goals: [Goal.t()],
          notes: String.t(),
          report: Report.t()
        }
  def new(%{"name" => name}) do
    %__MODULE__{name: name}
  end
end

defmodule Memelex.Lib.Structs.MemexConcepts.V01.Project.ProjectPlan do
  @moduledoc """
  Represents a detailed plan of a project.

  Captures the planned milestones, tasks, and other pivotal details necessary for the execution of a project.

  ## Fields:

  - `milestones`: Key events or phases in the project.
  - `tasks`: Individual tasks that need to be completed for the project.
  """

  defstruct milestones: [],
            tasks: []

  @type t :: %__MODULE__{
          milestones: [Milestone.t()],
          tasks: [Task.t()]
        }
end

defmodule Memelex.Lib.Structs.MemexConcepts.V01.Project.Timeline do
  @moduledoc """
  Represents the time frame of a project.

  ## Fields:

  - `start_date`: The commencement date of the project.
  - `end_date`: The expected completion date of the project.
  """

  defstruct start_date: nil,
            end_date: nil

  @type t :: %__MODULE__{
          start_date: Date.t(),
          end_date: Date.t()
        }
end

defmodule Memelex.Lib.Structs.MemexConcepts.V01.Project.Resource do
  @moduledoc """
  Represents a resource associated with a project.

  Resources could be documents, tools, budgets, or any other essential assets.

  ## Fields:

  - `name`: Name or title of the resource.
  - `description`: Brief description of the resource.
  - `type`: Type or category of the resource (e.g., Document, Tool).
  """

  defstruct name: nil,
            description: nil,
            type: nil

  @type t :: %__MODULE__{
          name: String.t(),
          description: String.t(),
          type: String.t()
        }
end

defmodule Memelex.Lib.Structs.MemexConcepts.V01.Project.Goal do
  @moduledoc """
  Represents a goal or objective of a project.

  ## Fields:

  - `description`: Description of the goal.
  - `status`: Status of the goal (e.g., Achieved, In Progress).
  """

  defstruct description: nil,
            status: nil

  @type t :: %__MODULE__{
          description: String.t(),
          status: atom()
        }
end

defmodule Memelex.Lib.Structs.MemexConcepts.V01.Project.Report do
  @moduledoc """
  Represents a report summarizing the project's outcomes.

  ## Fields:

  - `summary`: A brief summary of the report.
  - `details`: Detailed information or findings.
  - `date`: Date when the report was generated.
  """

  defstruct summary: nil,
            details: nil,
            date: nil

  @type t :: %__MODULE__{
          summary: String.t(),
          details: String.t(),
          date: Date.t()
        }
end

defmodule Memelex.Lib.Structs.MemexConcepts.V01.Project.Milestone do
  @moduledoc """
  Represents a key event or phase in the project.

  ## Fields:

  - `name`: Name or title of the milestone.
  - `date`: Expected date of the milestone.
  """

  defstruct name: nil,
            date: nil

  @type t :: %__MODULE__{
          name: String.t(),
          date: Date.t()
        }
end

defmodule Memelex.Lib.Structs.MemexConcepts.V01.Project.Task do
  @moduledoc """
  Represents an individual task within a project.

  ## Fields:

  - `description`: Description of the task.
  - `status`: Status of the task (e.g., Completed, In Progress).
  """

  defstruct description: nil,
            status: nil

  @type t :: %__MODULE__{
          description: String.t(),
          status: atom()
        }
end
