module Bugsage
  class ExceptionsApp
    def call(env)
      exception = env["action_dispatch.exception"] || env["action_dispatch.original_exception"]
      suggestion = Rule.match(exception) if exception

      if suggestion
        context = Middleware.new(nil).send(:rails_context, env)
        Store.add(suggestion, context)
        [500, { "Content-Type" => "text/html" }, [ErrorPage.render(suggestion, context)]]
      else
        [500, { "Content-Type" => "text/html" }, ["<h1>BugSage could not classify this exception.</h1>"]]
      end
    end
  end
end
