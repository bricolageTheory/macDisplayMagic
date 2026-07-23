# Project Specific Rules for macDisplayMagic

- Dual GitHub account push (simultaneous pushing to both `nicklee76` and `bricolageTheory` repositories) is configured specifically for this project (`macDisplayMagic`).
- Do not apply dual-push remotes or `bricolageTheory` git configuration to other projects unless explicitly requested by the user.

## Homebrew Cask & Version Release Workflow
- Primary GitHub account for Homebrew Cask releases, downloads, and documentation URLs is `bricolageTheory` (`https://github.com/bricolageTheory/macDisplayMagic`).
- When releasing new versions:
  1. Bump version numbers in `build_app.sh` (`CFBundleShortVersionString` and `CFBundleVersion`) and `README.md` (header & changelog).
  2. Build and package release zip: `zip -r dist/macDisplayMagic.zip dist/macDisplayMagic.app`.
  3. Calculate release SHA-256 hash: `shasum -a 256 dist/macDisplayMagic.zip`.
  4. Ensure GitHub Release on `bricolageTheory/macDisplayMagic` is published for `v<VERSION>` with `macDisplayMagic.zip` attached.
  5. For Homebrew Cask version bumps, submit PR to `Homebrew/homebrew-cask` or run `brew bump-cask-pr --version <VERSION> macdisplaymagic`.
