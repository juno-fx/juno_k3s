# Developer docs


This will help you get started working with this role as a developer.

## Prerequisites

- [devbox](https://www.jetpack.io/devbox/docs/) (optional)
  - we use it to ensure consistent version for dependencies such as python. 
  Your local interpreter will be fine in most cases
- GNU make
- an authenticated AWS CLI. Run `aws sts get-caller-identity` to verify.


## Documentation standards
The README.md shouldn't be edited directly. Instead, edit the template in `docs/readme/README.md.j2` template and run
`make readme` to generate the README.md.

You should not:
- document example playbooks manually. You should instead include them in the test scenario and source them from there.

### Documenting variables
Each variable should have an explicit default value in defaults/main.yml.

Above the var, document it with a comment. The comment should be in the form:

```
#@var <variable name>:description: This is my description
<variable name>: <default value>
```


## Developer workflow

To see supported Platforms check the README or the Makefile directly.

When working with this role, you can use the below `make` targets to validate it:

- `make converge-<platform name>` - this spins up all needed EC2 instances on AWS and applies the example playbook to them directly.
The example playbook it applies is defined in `molecule/ec2/converge.yml`. When testing new functionality, you can add it there.

You can define multiple runs in there, to test different configurations.
Changes to variables the user would supply themselves go there.
Changes to tasks that the role is responsible for go into `tasks/`

- `make login` - log in to one of instances you just created. We default to the controplane node.
You can log in to any of those instances - run `venv/bin/molecule login --help` to see options

- `make destroy-<platform name>` - when done working with it, clean up the dev env. Otherwise you will generate AWS costs!

- `make test-<platform name>` - run the full test suite.
Note that if one of your steps defined in `tasks/` failed, the instances will be cleaned up and you will have no ability to inspect them.

That's why `make test-*` is preferrable for CI, while `converge` is better for local dev.
You still might want to run it locally when checking for idempotency - `make test` runs the playbook twice and expects no changes flagged on the 2nd run.


## Release workflow

This section aims to guide maintainers through the release workflow.


When making a release tag, we first run the airgap tests.
Those are expensive in terms of time - about 30 minutes per platform!

Execution in customer environments is much faster - a bulk of that time is taken performing k3s image uploads
from the runners to AWS.

We manually trigger the airgap tests for now, by going to GH actions tab and running the workflow.
