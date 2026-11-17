# Security reporting

Do not publish credentials, health data, locations, exploitable backend details or full databases in an issue.

If this repository has GitHub private vulnerability reporting enabled, use the **Security → Report a vulnerability** flow. Its availability has not yet been verified. Otherwise contact the owner through [their GitHub profile](https://github.com/JanErcanK), or open a minimal issue requesting a private contact channel without disclosing the vulnerability.

There is no guaranteed response-time or supported-version policy yet. This project is still being prepared for store release.

## Maintainer notes

Provider API keys belong only in the app's secure storage. Local service configuration belongs in ignored `config/local.defines.json`; upload signing keys and passwords must never be committed. Public Firebase client configuration is not an administrative secret, and access must be enforced by backend rules.

A previously embedded routing token needs revocation/rotation before public distribution. Removing it from the working tree does not remove it from existing Git history or previously built applications. Do not rewrite shared Git history without coordinating with the owner.
