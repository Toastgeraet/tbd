# Godot — web export

> **Status:** proven · **Last verified:** 2026-09, Godot 4.7.2 · **Proven in:** cosmic-capitalist

Exports the game as HTML5/WebAssembly and serves it locally for browser testing.

**Only export when the user asks.** They normally run from the editor, and a
re-export after every change was explicitly unwanted.

## One-time setup

1. **Export templates.** In the editor, *Editor → Manage Export Templates →
   Download and Install*. The bundle is about 1.2 GB; the user prefers installing
   it through the GUI rather than having Claude download it. Templates land in
   `%APPDATA%\Godot\export_templates\4.7.2.stable\` on Windows.
2. **Renderer** must be GL Compatibility — the only renderer the web export
   supports. The templates already use it.
3. **Preset.** `templates/export_presets.cfg` holds a working `Web` preset:

   | Option | Value | Why |
   | --- | --- | --- |
   | `export_path` | `build/web/index.html` | `/build/` is gitignored |
   | `variant/thread_support` | `false` | The single-threaded build doesn't need cross-origin isolation, so it can run on plain static hosting (researched — only ever served locally) |
   | `html/canvas_resize_policy` | `2` (adaptive) | The canvas follows the browser window |
   | `html/export_icon` | `true` | |

## Export and serve

```bash
"$GODOT" --headless --path . --export-release "Web" build/web/index.html
python tools/serve_web.py 8060        # http://127.0.0.1:8060/
```

`.claude/launch.json` can run the server as a preview:

```json
{
  "version": "0.0.1",
  "configurations": [
    { "name": "web", "runtimeExecutable": "python", "runtimeArgs": ["tools/serve_web.py", "8060"], "port": 8060 }
  ]
}
```

## Why `serve_web.py` and not `python -m http.server`

- **Black page; the server log shows only `GET /`, and requests for `index.js` and
  `index.png` hang.** The single-threaded `socketserver.TCPServer` deadlocks on the
  browser's parallel, keep-alive connections. `serve_web.py` uses
  `ThreadingHTTPServer` with `daemon_threads`, and HTTP/1.1.
- `.wasm` must be served as `application/wasm`, or browsers refuse to
  stream-compile it.
- COOP/COEP headers are sent; they are needed only for threaded builds and are
  harmless otherwise.
- `Cache-Control: no-store`, so a re-export shows up on reload instead of a stale
  cached `.wasm`.

## Checking it in a browser

Limited — see [verification.md](verification.md#browser-based-checks). Use the
browser to confirm it loads; verify behaviour with in-engine probes.
