defmodule Memelex.AgentTools.ElixirTools do
  @moduledoc """
  A utility module to check if the current Elixir project compiles successfully.

  Returns:
    {:ok, warnings} if the project compiles with warnings.
    {:error, errors} if the project fails to compile.
  """

  @doc """
  Checks if the project compiles.

  Returns:
  - {:ok, warnings} - The project compiles successfully but has warnings.
  - {:error, errors} - The project fails to compile with errors.
  """
  def compile_proj do
    source_files = get_project_files()
    tmp_path = "_build/tmp" # Temporary in-memory compilation directory.

    # Ensure the temporary build directory exists
    File.mkdir_p!(tmp_path)

    # Compile and capture warnings/errors
    case Kernel.ParallelCompiler.compile(source_files) do
      {:ok, _modules, warnings} ->
        {true, [], warnings}

      {:error, errors, warnings} ->
        {false, errors, warnings}
    end
  end



#     fix_compilation_error_system_prompt = """
#     You are an expert Elixir debugger. Your job is to debug and fix Elixir compilation errors by analyzing the provided error message and returning structured, machine-readable output. Follow these steps:

#     Analyze the Error:
#         Identify the file, line number, and root cause of the error.
#         Explain the issue in plain language.

#     Propose Fixes:
#         Provide exact changes for the code, specifying:
#             The line number(s) to modify.
#             The current code at those lines.
#             The updated code for those lines.
#         If multiple changes are required, return a list of changes.

#     Validate:
#         Ensure the fix aligns with Elixir syntax and resolves the root issue.

#     Structured Output: Return the result as a JSON object with the following fields:

#     {
#       "status": "ok" | "error",
#       "analysis": {
#         "file": "string",
#         "line": "integer",
#         "cause": "string",
#         "explanation": "string"
#       },
#       "changes": [
#         {
#           "line": "integer",
#           "current_code": "string",
#           "new_code": "string"
#         }
#       ]
#     }

# Output Example

# For an input error message:

# == Compilation error in file lib/example.ex ==
# ** (CompileError) lib/example.ex:15: undefined function foo/1

# The output should look like this:

# {
#   "status": "ok",
#   "analysis": {
#     "file": "lib/example.ex",
#     "line": 15,
#     "cause": "undefined function foo/1",
#     "explanation": "The function `foo/1` is called on line 15, but it is not defined in the current module or imported."
#   },
#   "changes": [
#     {
#       "line": 15,
#       "current_code": "foo(arg)",
#       "new_code": "def foo(arg) do\n  # Add your implementation here\nend"
#     }
#   ]
# }

# Steps in Detail
# Step 1: Analyze the Compilation Error

# Instructions:

#     Extract the file name, line number, and error message.
#     Provide an explanation of the error.

# Example Input:

# == Compilation error in file lib/example.ex ==
# ** (CompileError) lib/example.ex:25: no function clause matching in Example.foo/1

# Example Output:

# {
#   "status": "ok",
#   "analysis": {
#     "file": "lib/example.ex",
#     "line": 25,
#     "cause": "no function clause matching in Example.foo/1",
#     "explanation": "On line 25, the function `foo/1` was called with arguments that do not match any existing clauses in the function definition."
#   },
#   "changes": []
# }

# Step 2: Suggest Fixes

# Instructions:

#     For each issue, specify:
#         The line number of the error.
#         The current code causing the issue.
#         The updated code that resolves it.

# Example Input:

# == Compilation error in file lib/example.ex ==
# ** (CompileError) lib/example.ex:10: undefined variable 'x'

# Example Output:

# {
#   "status": "ok",
#   "analysis": {
#     "file": "lib/example.ex",
#     "line": 10,
#     "cause": "undefined variable 'x'",
#     "explanation": "On line 10, the variable `x` is used but is not defined in the current scope."
#   },
#   "changes": [
#     {
#       "line": 10,
#       "current_code": "IO.puts(x)",
#       "new_code": "x = \"Default value\"\nIO.puts(x)"
#     }
#   ]
# }

# Step 3: Handle Multiple Changes

# If the fix requires changes across multiple lines, return a list of all required changes.

# Example Input:

# == Compilation error in file lib/sample.ex ==
# ** (CompileError) lib/sample.ex:5: undefined function bar/0

# Example Output:

# {
#   "status": "ok",
#   "analysis": {
#     "file": "lib/sample.ex",
#     "line": 5,
#     "cause": "undefined function bar/0",
#     "explanation": "On line 5, the function `bar/0` is called, but it is not defined in the current module or imported."
#   },
#   "changes": [
#     {
#       "line": 5,
#       "current_code": "bar()",
#       "new_code": "def bar do\n  # Add your implementation here\nend\nbar()"
#     }
#   ]
# }

# Failure Case

# If the error cannot be fixed due to insufficient context, return:

# {
#   "status": "error",
#   "analysis": {
#     "file": "unknown",
#     "line": 0,
#     "cause": "unknown issue",
#     "explanation": "The provided error message does not include enough information to debug the issue."
#   },
#   "changes": []
# }

# Validation Rules

#     Ensure the output JSON is parseable.
#     All code changes should include both the current code and the new code.
#     If no changes are needed (e.g., the error is a runtime error), the changes list should remain empty.
#     """


  # Memelex.AgentTools.ElixirTools.fix_compilation_error({"/home/luke/workbench/flx/flamelex/test/gui/components/memex_screen/memex_screen_test.exs", 2, "module ExUnitProperties is not loaded and could not be found"}, Mistral7B)

  # {"/home/luke/workbench/flx/flamelex/test/gui/components/memex_screen/memex_screen_test.exs", 2, "module ExUnitProperties is not loaded and could not be found"}
  def fix_compilation_error({file, line_num, error}, Mistral7B) do

    fix_compilation_error_system_prompt = """
You are an expert Elixir debugger. Your job is to fix Elixir compilation errors by analyzing the provided error message and returning the updated file contents, ready for use. Your output should include **only the modified file content**. Do not return explanations, JSON, or any additional information.

Instructions:
1. Analyze the provided error message and determine the necessary changes to the specified file.
2. Apply the changes directly to the file content.
3. Return the entire updated file as plain text. Do not include any metadata, comments, annotations or explanations.

Rules:
- Your output must be valid Elixir code.
- Do not include any additional information or context beyond the fixed file content. Simply return the new fixed version of the file, the full module.
- Ensure the fix resolves the compilation error.

Input Example

Error: undefined function foo/1
Line: 15
File: lib/example.ex

Current file content:
```
defmodule Example do
  def bar(arg) do
    foo(arg)
  end
end
```

Output Example (ONLY return the complete valid Elixir module):

```
defmodule Example do
  def bar(arg) do
    foo(arg)
  end

  def foo(arg) do
    # Add implementation here
  end
end
```

Here is another example:

Error: module ExUnitProperties is not loaded and could not be found
Line: 2
File: /home/luke/workbench/flx/flamelex/test/gui/components/memex_screen/memex_screen_test.exs

Current file content:
```
defmodule Flamelex.Test.GUI.Components.MemexScreen do
  use ExUnitProperties

  # property "bin1 <> bin2 always starts with bin1" do
  #     check all bin1 <- binary(),
  #                 bin2 <- binary() do
  #         assert String.starts_with?(bin1 <> bin2, bin1)
  #     end
  # end
end
```

In this case, the fix was to remove the `use ExUnitProperties` line.

Output Example (ONLY return the complete valid Elixir module):

```
defmodule Flamelex.Test.GUI.Components.MemexScreen do

  # property "bin1 <> bin2 always starts with bin1" do
  #     check all bin1 <- binary(),
  #                 bin2 <- binary() do
  #         assert String.starts_with?(bin1 <> bin2, bin1)
  #     end
  # end
end
```
"""

    code_before_fix = File.read!(file)

    user_prompt = """
    This is the issue we need to fix:

    Error: #{error}
    Line number: #{line_num}
    File (#{file}):

    ```
    #{code_before_fix}
    ```
    """

    %{results: [%{text: text}]} = Nx.Serving.batched_run(Mistral7B, fix_compilation_error_system_prompt <> "\n\n" <> user_prompt)

    with {:ok, code} <- extract_code_block(text),
         {:ok, _success_msg, _module_name} <- try_compile(code) do

        IO.puts "GOT THE FIX WOOHOO"
        {:ok, %{file: file, before: code_before_fix, after: code}}
    end
  end

      # {:ok, %{choices: [%{"message" => %{"content" => llm_response}}]}} = OpenAI.chat_completion(
    #     model: "gpt-4",
    #     messages: [
    #       # %{"role" => "system", "content" => sys_prompt},
    #       %{"role" => "system", "content" => fix_compilation_error_system_prompt},
    #       %{"role" => "user", "content" => user_prompt}
    #     ]
    #   )


  # Fetch all source files in the project (lib/ and test/)
  defp get_project_files do
    Path.wildcard("lib/**/*.ex") ++ Path.wildcard("test/**/*.exs")
  end

  def extract_code_block(text) do
    case Regex.run(~r/```(?:elixir)?\n(.*?)```/s, text) do
      [_, code] -> {:ok, code}
      _ -> {:error, "No code block found"}
    end
  end

  def try_compile(code) do
    case Code.compile_string(code) do
      [{module, binary}] when is_atom(module) ->
        {:ok, "Compiled successfully", module}
      errors ->
        IO.inspect(code)
        {:error, "Compilation failed", errors}
    end
  end

  # # Callback to handle compiler diagnostics
  # defp diagnostic_callback(diagnostic) do
  #   send(self(), {:diagnostic, diagnostic})
  # end

  # Format diagnostics into human-readable messages
  # defp format_diagnostics(diagnostics) do
  #   diagnostics
  #   |> Enum.map(fn %{file: file, line: line, message: msg, severity: severity} ->
  #     "[#{severity}] #{file}:#{line} - #{msg}"
  #   end)
  # end
end
