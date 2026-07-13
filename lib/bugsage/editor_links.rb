# frozen_string_literal: true

module Bugsage
  module EditorLinks
    module_function

    def for_location(location)
      file_path, line_number = CodeContext.extract_location(location)
      return {} unless file_path

      absolute = File.expand_path(file_path)
      line = line_number || 1

      {
        file_path: absolute,
        line_number: line,
        cursor: cursor_url(absolute, line),
        vscode: vscode_url(absolute, line)
      }
    end

    def cursor_url(file_path, line = 1, column = 1)
      "cursor://file/#{escape_path(file_path)}:#{line}:#{column}"
    end

    def vscode_url(file_path, line = 1, column = 1)
      "vscode://file/#{escape_path(file_path)}:#{line}:#{column}"
    end

    def escape_path(file_path)
      file_path.to_s.gsub(" ", "%20")
    end
  end
end
