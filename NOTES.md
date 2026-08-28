# Kane's Arch — Devlog / Notes

Running notes, in rough chronological order. Less formal than the wiki —
this is closer to a maintainer's scratch file than documentation.

---

## v2.0 "Kane Got ARCHed"

- Went public. Repo is live, MIT licensed.
- Issue tracker filled up almost immediately with variations on "how does this
  actually work." None closed yet. Might write a proper explainer instead of
  answering each one individually.
- `pacman-cpu` naming might get confusing next to real `pacman` — consider
  renaming before this gets any more attention.
- fastfetch branding pass done: custom logo, `os-release` patched, boot menu
  text updated in both syslinux and grub configs.
- TODO: Plymouth boot splash. Bigger lift than the rest of the branding pass —
  needs a full theme directory, not just a config edit. Parking for now.
- TODO: consider a real desktop-environment build instead of the minimal
  `releng`-based live image, if this keeps getting used past the joke.

## v1.0 "The Big Bang"

- First working build. No public repo, no real changelog — this file is the
  closest thing to one that exists.
- RAM requirement was 1 MB, not 0. Worth remembering that the "zero" framing is
  a v2.0 thing specifically, not true of the whole project from day one.
- Never wrote proper install docs for this version since it was never really
  meant to leave one machine.

## Known issues

- `mkarchiso` build times vary a lot by connection speed, since it pulls a full
  package set. Not a bug, just worth flagging so nobody assumes something's
  broken during a long build.
- Boot menu label patch (`sed`-replacing "Arch Linux" → "Kane's Arch") is a
  blunt find-and-replace. If a future `archiso` release changes the boot config
  file structure, this may need updating.
- No installer GUI. No stable "install to disk" flow beyond what stock Arch's
  manual process provides — this is a live/rescue image, not a turnkey installer.

## Open questions / ideas

- Would a Manjaro/EndeavourOS-style graphical installer actually make this feel
  more "real," or is the minimal TTY-only version funnier as-is? Leaning toward
  keeping it minimal for now.
- Could theme `archinstall` itself instead of just the live environment — bigger
  effort, unclear if worth it yet.
- Someone asked if there's a Kane's Arch wallpaper. There isn't. Should there be.

---

*Last updated: ongoing. This file is not meant to be polished — see
[`WIKI.md`](./WIKI.md) for the actual documentation.*
