# galaxyeggbert.com

The presentation website of **Galaxy Eggbert**, the free, open-source 3D remake of
*Speedy Blupi* / *Speedy Eggbert*. The game itself lives in
[openeggbert/galaxy-eggbert](https://github.com/openeggbert/galaxy-eggbert).

It is a static site: plain HTML, CSS and a little JavaScript. There is no build step and
no framework, and nothing is loaded from third-party servers (the fonts are self-hosted).

## Layout

| Path | What it is |
|---|---|
| `index.html` | The landing page: story for fans, features, worlds, screenshots, editor, download, controls, tech, roadmap, FAQ |
| `play/index.html` | The online player: a launcher that loads the WebAssembly build in an iframe on click |
| `play/game/` | The game's web build (`GalaxyEggbert.html/.js/.wasm/.data` + `Content/music/`), copied by `tools/update-web-build.sh` |
| `assets/css/style.css` | All styles (one dark "space" theme) |
| `assets/js/main.js` | Navigation, lightbox, Off/Ultra compare slider, tabs, platform detection |
| `assets/js/gallery-data.js` | The list of screenshots shown in the gallery |
| `assets/shots/` | Screenshots: `name.webp` (1600×960, lightbox) and `thumb/name.webp` (800×480, page) |
| `assets/img/` | Logo, Blupi art, icons, Open Graph image |
| `assets/fonts/` | Fredoka and Nunito (SIL OFL 1.1) |
| `tools/` | Maintenance scripts (below) |
| `CNAME`, `.nojekyll`, `404.html`, `robots.txt`, `sitemap.xml`, `site.webmanifest` | GitHub Pages plumbing |

## Run it locally

```bash
python3 -m http.server 8000
# open http://localhost:8000/
```

The web build must be served over HTTP; it doesn't run from `file://`.

## Common updates

**A new web build of the game.** Build the `WEBGL2` target in the game repository
(see its README), then:

```bash
tools/update-web-build.sh                 # from ../galaxy-eggbert/build-cna-webgl2
tools/update-web-build.sh /path/to/build  # or from anywhere else
```

`GalaxyEggbert.data` is about 92 MB. GitHub Pages rejects single files of 100 MB or more,
and the script warns when that limit gets close.

**A platform gets a release.** In `index.html`, section `#download`, change the card's
`data-status` (`available`, `preview`, `soon`, `planned`), its pill text and its primary
button's link. A comment above the cards explains it.

**New screenshots.** Convert a capture into both sizes:

```bash
tools/add-shot.sh capture.png w05            # -> assets/shots/w05.webp + thumb/w05.webp
```

Then list it in `assets/js/gallery-data.js`, or reference it in `index.html`.
`tools/capture/` holds the scripts that produced the current set. They run the native game
under Xvfb with its QA autoplay at 1600×960 and Ultra graphics, and grab the window every few seconds:

```bash
tools/capture/missions.sh out 042 055 081      # out/m042/, out/m055/, ... one frame every 5 s
```

They need a native build in `../galaxy-eggbert/build-cna-opengl3`, plus Xvfb, xdotool and ImageMagick.
Run one capture at a time, because llvmpipe under Xvfb is CPU-heavy. The run directory sits in the game's
`build-probe/website-run/`, so delete it and your `out/` folder when you're done.

The multiplayer shots (`feat-multiplayer`, `mp-lobby`, `mp-win`, 2026-11-11) come from a real two-player
match of mission #201 on this machine: the host Ann through `tools/capture/shoot.sh` at Ultra with the
game's network test hooks (`GALAXY_NET_TEST=host GALAXY_NET_NAME=Ann GALAXY_NET_PLAYERS=2
AUTOPLAY_REALTIME=1`, a script that waits in the match), and a second instance a few seconds later
under its own Xvfb as Ben (`GALAXY_NET_TEST=join`, a script that walks him behind the yellow bombs and
has him stand there), as the game repository's `tools/net_players.sh` starts its players.

The Off/Ultra pair in the graphics section is the same game tick (9120 of mission 055), saved by the
game itself (`AUTOPLAY_SHOTS=60`) once with `effectsLevel=0` and once with `effectsLevel=4`.
The images are 800×480.

**The social preview image** (`assets/img/og-image.jpg`, 1200×630) is rendered from
`tools/og/og.html`. Serve the site locally, then run `tools/og/render.sh`.

## Deploying

Publish the repository root with GitHub Pages (branch deploy, root folder). `CNAME` sets the
domain `galaxyeggbert.com` and `.nojekyll` makes Pages serve every file as is.

## Credits

Galaxy Eggbert is an independent, non-commercial fan project. *Speedy Blupi*, *Speedy Eggbert*
and Blupi were created by Daniel Roux and EPSITEC SA. The logo and Blupi artwork on this site
come from the game's own `Content/` folder, and every screenshot was captured from the game.
