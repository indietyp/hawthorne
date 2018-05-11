# Explanation

The mainframe is a concept that was introduced in the v0.7 release. The purpose of it is to handle certain things that are only possible in a centralised matter.

For security reasons, every instance that wants to use services offered by the mainframe needs to be registered, so if fraud would happen, this can be traced back.

The mainframe **only** saves data that is necessary and is the core application also open source.

## Saved data
- 24 hours for `hawthorne report` [Detailed information about the what is sent][1]
- IP, domain and a generated salt, when an instance is registered
- usage data (_this feature is not yet implemented_)
- discord bot usage (_this feature is not yet implemented_)
- local users

[1]:	toolchain/reference.md
