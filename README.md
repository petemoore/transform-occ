# transform-occ

This is a utility to convert an OCC manifest into a powershell script, to make it easier to see what powershell is run behind the scenes.

# Usage

The `transform-occ` command line tool expects a single argument, which should be the OpenCloudConfig managed worker type name.

For example:
```
go get github.com/petemoore/transform-occ && transform-occ gecko-1-b-win2012
```
