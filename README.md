# Termux LibGhostty packages

This repository contains the Termux package recipes and CI configuration for
the LibGhostty Termux fork.

The Android application package is `com.termux_libghostty`, so packages are built
for the separate prefix:

```text
/data/data/com.termux_libghostty/files/usr
```

They must not be mixed with binary packages built for stock `com.termux`.

## CI/CD

The workflows are based on the upstream Termux package build system:

- `Package updates` checks upstream package sources every six hours and commits
  recipe updates.
- `Packages` builds changed packages for all supported Android architectures.
- `Publish LibGhostty APT repository` collects successful build artifacts,
  generates signed APT metadata, and publishes the repository on the `gh-pages`
  branch.

The package build workflow intentionally bootstraps from source instead of
using stock Termux binary dependencies. Once this repository has enough custom
packages available, the build can be changed to use `-I` against the custom
repository.

## Required repository secrets

Configure these Actions secrets before publishing packages:

- `APT_GPG_PRIVATE_KEY`: ASCII-armored private signing key.
- `APT_GPG_PASSPHRASE`: passphrase for that key.

After GitHub Pages is enabled for the `gh-pages` branch, the repository URLs
will be:

```text
https://hritikbtw.github.io/termux_libghostty-packages/apt/termux-main
https://hritikbtw.github.io/termux_libghostty-packages/apt/termux-root
https://hritikbtw.github.io/termux_libghostty-packages/apt/termux-x11
```
