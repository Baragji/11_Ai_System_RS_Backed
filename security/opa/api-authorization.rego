package platform.authz

default allow = false

scopes = {
  "planner": {"actions": {"POST /tasks"}},
  "coder": {"actions": {"POST /tasks"}},
  "critic": {"actions": {"POST /tasks"}}
}

allow {
  required := scopes[input.auth.scope]
  action := sprintf("%s %s", [input.request.method, input.request.path])
  action == required.actions[_]
}

violation[msg] {
  not allow
  msg := {
    "type": "https://platform.company.com/errors/unauthorized",
    "title": "Unauthorized",
    "status": 403,
    "detail": sprintf("scope %s is not permitted to call %s %s", [input.auth.scope, input.request.method, input.request.path])
  }
}
