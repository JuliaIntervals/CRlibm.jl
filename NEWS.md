# v0.4

- API change: Doing `using CRlibm` **no longer defines the rounded functions**.
You must explicitly call `CRlibm.setup()`

# v0.3.1

- Now works correctly on Windows by wrapping MPFR 

# v0.3
f
- Source code now included in the Julia package

## v0.2.4

- Remove 0.5 deprecation warnings; some code clean-up

## v0.2.3

- Removed failure when running on Windows; defaults to shadowing MPFR functions

# v0.2

- Added MPFR wrappers
