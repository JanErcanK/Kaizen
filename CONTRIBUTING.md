# Reporting issues and proposing changes

Kaizen is a portfolio project with restricted reuse rights. Public visibility is not an open-source license. Read [LICENSE.md](LICENSE.md); obtain permission before adapting or redistributing the author's work. Discuss proposed contributions with the maintainer before submitting code. No automatic copyright assignment or contributor license agreement is implied.

## Useful bug reports

Include device/model, operating-system version, app version/build, exact steps, expected/actual behavior and whether the problem also occurs after restarting. For body-map issues, include the zoom/back/folding sequence and whether the process closes or only a screen changes.

Redact personal profiles, health data, coordinates, friend codes and credentials from screenshots and logs. Never attach an API key, signing file or full application database to a public issue. For a security concern, follow [SECURITY.md](SECURITY.md).

## Working on an agreed change

Follow [setup](docs/GETTING_STARTED.md), keep the change focused, and preserve existing user data. Add meaningful regression tests for behavior changes. Run the relevant tests, then the full suite when shared state/navigation changes. Report analyzer warnings honestly. Update the affected docs and [changelog](CHANGELOG.md); do not describe planned features as shipped.

Pull requests should explain the problem, resulting behavior, verification and remaining limitations. Do not commit build artifacts, service keys, signing credentials, real user data or unlicensed assets.
