# F5 Automation Factory for Google Cloud

These Terraform modules can be used to establish an *automation factory* to
generate F5 product artefacts in your own GCP project.

## Overview

Customers often have to maintain their own deployment artefacts for F5 products
either to enforce consistent usage of approved versions, or because deployments
are not permitted to deploy artefacts from public repositories.

## Getting Started

The easiest way to begin is to use the [quick-start](examples/quick-start) example
as a base.

1. Clone the [quick-start](examples/quick-start) example

```shell
terraform init -from-module github.com/f5devcentral/terraform-google-f5-automation-factory/examples/quick-start
```

## Usage

The main root module enables required Google APIs, creates a VM builder service
account, and enables Cloud Build's service account to manage the building of
BIG-IP images, BIG-IQ images, NGINX+ images and containers.

Each [sub-module](modules) implements a specific automation factory use-case that
can be deployed independently as needed.

> NOTE: By default *all* F5 product sub-modules are enabled as part of the automation
> factory; you can selectively enable/disable aspects of the factory through the
> `features` variable.

## Development

Local development set up and contributing guidelines can be found in [CONTRIBUTING.md](CONTRIBUTING.md).

## Support

For support, please open a GitHub issue.  Note, the code in this repository is
community supported and is not supported by F5 Inc.  For a complete list of
supported projects please reference [SUPPORT.md](SUPPORT.md).

## Community Code of Conduct

Please refer to the [F5 DevCentral Community Code of Conduct](code_of_conduct.md).

## License

[Apache License 2.0](LICENSE)

## Copyright

Copyright 2022 F5, Inc.

### F5 Contributor License Agreement

Before you start contributing to any project sponsored by F5, Inc. (F5) on GitHub,
you will need to sign a Contributor License Agreement (CLA).

If you are signing as an individual, we recommend that you talk to your employer
(if applicable) before signing the CLA since some employment agreements may have
restrictions on your contributions to other projects. Otherwise by submitting a
CLA you represent that you are legally entitled to grant the licenses recited therein.

If your employer has rights to intellectual property that you create, such as your
contributions, you represent that you have received permission to make contributions
on behalf of that employer, that your employer has waived such rights for your
contributions, or that your employer has executed a separate CLA with F5.

If you are signing on behalf of a company, you represent that you are legally
entitled to grant the license recited therein. You represent further that each
employee of the entity that submits contributions is authorized to submit such
contributions on behalf of the entity pursuant to the CLA.
