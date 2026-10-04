#!/usr/bin/env python3
"""ds.py -- a workspace's own design system, read by every generator.

A workspace selects a design system by committing one file at its repo root:

    <repo>/.cc/design-tokens.json

and everything generated inside that repo wears it. A repo without the file
keeps the owner's house look: `find` prints nothing, and a generator that
finds nothing does exactly what it did before. Standard library only, bar
fontTools when an export ships its own font files.

    ds.py find [dir]                  print the tokens file that applies to dir
                                      (default: the current directory); exit 1
                                      and print nothing when none does
    ds.py import [<export>] [-o out] [--logo file|name] [--voice file]...
                                      turn a Claude Design export (a folder
                                      whose tokens/*.css hold :root custom
                                      properties) into a tokens file, default
                                      .cc/design-tokens.json. Beside it go the
                                      logo (an SVG converted to PDF), the
                                      icons as design-icons.pdf, and the
                                      @font-face files the type stacks name as
                                      static OTF/TTF in design-fonts/. With no
                                      <export> it re-imports the one the
                                      tokens file's "source" names, keeping
                                      its logo, voice guides and copyright
    ds.py check <tokens.json>         validate a tokens file
    ds.py voice <tokens.json>         print the voice guides it names, one
                                      absolute path a line
    ds.py latex <tokens.json>         print the LaTeX theme pdf-material-builder
                                      loads after housestyle.sty
    ds.py xlsx <data.csv> -o out.xlsx [--title T] [--tokens file] [--sheet S]
                                      write the CSV as a styled workbook; the
                                      tokens come from --tokens or from `find`
                                      on the CSV's directory, and there must be
                                      some (exit 1 otherwise)

How `find` decides: $DESIGN_TOKENS, when set, wins -- a path names the file
(exit 2 if it is missing) and the word `none` means no design system. Without
it, find walks up from dir and takes the first .cc/design-tokens.json it meets,
stopping at the first directory that holds .git, so it never reads above the
enclosing repo. Outside any repo it finds nothing.

The tokens file (SKILL.md beside this script has the full list):
    {"name": "...",
     "color": {"ink", "ink-secondary", "ink-muted", "paper", "fill",
               "code-fill", "accent", "rule"},             each "#RRGGBB"
     "type":  {"body": [families], "heading": [families], "mono": [families],
               "heading-case": "none" | "uppercase"},
     "table": {"header-fill", "header-text", "rule", "stripe"},
     "logo":  "logo.png",                  relative to the tokens file
     "copyright": {"holder": "..."},       who the PDFs' copyright line names
     "fonts": {family: {"regular", "bold", "italic", "bolditalic"}},
                                           font files, loaded by path
     "icons": {"file": "design-icons.pdf", "names": [...]},
                                           page n of file is names[n-1]
     "voice": ["guide.html", ...],         the writer follows these
     "source": {"path": dir, "logo": file}}  what `import` re-reads
Every key is optional: one left out keeps the house value. Every path is
relative to the tokens file.

SVGs become PDF through rsvg-convert, or headless Chrome when it is not
installed; with neither the import keeps no logo or icons and says so. Font
files need fontTools (and brotli for woff2); without it the families come by
name, as before.

Exit codes: 0 done, 1 nothing found / invalid tokens / no tokens for xlsx,
2 usage or a missing file.
"""
import csv
import json
import math
import os
import re
import shutil
import sys
import zipfile
from xml.sax.saxutils import escape

TOKENS_REL = os.path.join('.cc', 'design-tokens.json')
COLOR_KEYS = ('ink', 'ink-secondary', 'ink-muted', 'paper', 'fill',
              'code-fill', 'accent', 'rule')
TABLE_KEYS = ('header-fill', 'header-text', 'rule', 'stripe')
TYPE_LISTS = ('body', 'heading', 'mono')
TOP_KEYS = ('name', 'color', 'type', 'table', 'logo', 'copyright', 'fonts',
            'icons', 'voice', 'source')
FACE_KEYS = ('regular', 'bold', 'italic', 'bolditalic')
ICON_NAME = re.compile(r'^[A-Za-z0-9][A-Za-z0-9-]*$')
HEX = re.compile(r'^#[0-9A-Fa-f]{6}$')
# A family name or logo path goes into LaTeX source as typed.
TEX_UNSAFE = re.compile(r'[\\{}%#$&^~\n]')


def die(msg, code=1):
    print(f'ds.py: {msg}', file=sys.stderr)
    sys.exit(code)


# ---- find ------------------------------------------------------------------
def find(start):
    env = os.environ.get('DESIGN_TOKENS')
    if env is not None and env != '':
        if env == 'none':
            return None
        if not os.path.isfile(env):
            die(f'DESIGN_TOKENS names {env}, which is not a file', 2)
        return os.path.abspath(env)
    d = os.path.abspath(start)
    candidate = None
    while True:
        if candidate is None:
            cand = os.path.join(d, TOKENS_REL)
            if os.path.isfile(cand):
                candidate = cand
        if os.path.exists(os.path.join(d, '.git')):
            return candidate
        parent = os.path.dirname(d)
        if parent == d:
            # Reached the filesystem root with no .git anywhere above the
            # candidate (if any) — never take a token file above a repo's
            # .git, so there is no repo to take it for.
            return None
        d = parent


# ---- load and check ----------------------------------------------------------
def check(tokens):
    """Return the problems with a tokens dict, [] when it is valid."""
    probs = []
    if not isinstance(tokens, dict):
        return ['the tokens file is not a JSON object']
    for k in tokens:
        if k not in TOP_KEYS:
            probs.append(f'unknown key {k!r} (known: {", ".join(TOP_KEYS)})')
    for group, keys in (('color', COLOR_KEYS), ('table', TABLE_KEYS)):
        g = tokens.get(group, {})
        if not isinstance(g, dict):
            probs.append(f'{group} is not an object')
            continue
        for k, v in g.items():
            if k not in keys:
                probs.append(f'unknown {group} key {k!r}')
            elif not (isinstance(v, str) and HEX.match(v)):
                probs.append(f'{group}.{k} is {v!r}, not "#RRGGBB"')
    t = tokens.get('type', {})
    if not isinstance(t, dict):
        probs.append('type is not an object')
        t = {}
    for k, v in t.items():
        if k in TYPE_LISTS:
            if not (isinstance(v, list) and v and all(isinstance(f, str) and f for f in v)):
                probs.append(f'type.{k} is not a non-empty list of family names')
            elif any(TEX_UNSAFE.search(f) for f in v):
                probs.append(f'type.{k} has a family name with a TeX special character')
        elif k == 'heading-case':
            if v not in ('none', 'uppercase'):
                probs.append(f'type.heading-case is {v!r}, not "none" or "uppercase"')
        else:
            probs.append(f'unknown type key {k!r}')
    logo = tokens.get('logo')
    if logo is not None and not (isinstance(logo, str) and logo):
        probs.append('logo is not a file name')
    c = tokens.get('copyright', {})
    if not isinstance(c, dict):
        probs.append('copyright is not an object')
        c = {}
    for k, v in c.items():
        if k != 'holder':
            probs.append(f'unknown copyright key {k!r}')
        elif not (isinstance(v, str) and v.strip()):
            probs.append('copyright.holder is not a name')
        elif TEX_UNSAFE.search(v):
            probs.append('copyright.holder has a TeX special character')
    fonts = tokens.get('fonts', {})
    if not isinstance(fonts, dict):
        probs.append('fonts is not an object')
        fonts = {}
    for fam, faces in fonts.items():
        if not (isinstance(faces, dict) and isinstance(faces.get('regular'), str)):
            probs.append(f'fonts.{fam} has no "regular" file')
            continue
        for k, v in faces.items():
            if k not in FACE_KEYS:
                probs.append(f'unknown fonts.{fam} key {k!r} (known: {", ".join(FACE_KEYS)})')
            elif not (isinstance(v, str) and v) or TEX_UNSAFE.search(v) or ' ' in v:
                probs.append(f'fonts.{fam}.{k} is not a file name without spaces or TeX specials')
    icons = tokens.get('icons')
    if icons is not None:
        if not (isinstance(icons, dict) and isinstance(icons.get('file'), str)
                and isinstance(icons.get('names'), list)):
            probs.append('icons is not {"file": ..., "names": [...]}')
        elif not all(isinstance(n, str) and ICON_NAME.match(n) for n in icons['names']):
            probs.append('icons.names holds a name that is not letters, digits and hyphens')
    voice = tokens.get('voice', [])
    if not (isinstance(voice, list) and all(isinstance(v, str) and v for v in voice)):
        probs.append('voice is not a list of file names')
    src = tokens.get('source')
    if src is not None and not (isinstance(src, dict) and isinstance(src.get('path'), str)
                                and all(k in ('path', 'logo') and isinstance(v, str)
                                        for k, v in src.items())):
        probs.append('source is not {"path": ..., "logo": ...}')
    return probs


def _beside(path, rel, what):
    """rel, a file the tokens file names, as an absolute path LaTeX can read."""
    full = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(path)), rel))
    if not os.path.isfile(full):
        die(f'{path} names {what} {rel}, which is not there')
    if TEX_UNSAFE.search(full) or ' ' in full:
        die(f'the {what} path {full} has a space or a TeX special character')
    return full


def load(path):
    try:
        with open(path, encoding='utf-8') as f:
            tokens = json.load(f)
    except OSError as e:
        die(f'cannot read {path}: {e.strerror}', 2)
    except ValueError as e:
        die(f'{path} is not JSON: {e}')
    probs = check(tokens)
    if probs:
        die(f'{path} is not a valid tokens file:\n  ' + '\n  '.join(probs))
    if tokens.get('logo'):
        tokens['logo'] = _beside(path, tokens['logo'], 'logo')
    for fam, faces in tokens.get('fonts', {}).items():
        faces = {k: _beside(path, v, 'font') for k, v in faces.items()}
        if len({os.path.dirname(v) for v in faces.values()}) != 1:
            die(f'{path}: the files of fonts.{fam} are not all in one directory')
        tokens['fonts'][fam] = faces
    if tokens.get('icons'):
        tokens['icons']['file'] = _beside(path, tokens['icons']['file'], 'icons')
    # A voice guide is a pointer the writer reads, never set in type, so one
    # that has moved is reported by `voice` and never stops a build.
    tokens['voice'] = [os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(path)), v))
                       for v in tokens.get('voice', [])]
    return tokens


# ---- import a Claude Design export -------------------------------------------
def _css_vars(export):
    """The :root custom properties of an export's token stylesheets."""
    tokdir = os.path.join(export, 'tokens')
    base = tokdir if os.path.isdir(tokdir) else export
    files = sorted(f for f in os.listdir(base) if f.endswith('.css'))
    if not files:
        die(f'{export} has no tokens/*.css (is it a Claude Design export?)', 2)
    out = {}
    for f in files:
        with open(os.path.join(base, f), encoding='utf-8') as fh:
            css = re.sub(r'/\*.*?\*/', '', fh.read(), flags=re.S)
        # Only :root blocks: a [data-brand=...] block is a sister brand's
        # override, not the system itself.
        for m in re.finditer(r'(?:^|})\s*:root\s*\{([^}]*)\}', css):
            for dm in re.finditer(r'(--[\w-]+)\s*:\s*([^;]+);', m.group(1)):
                out[dm.group(1)] = dm.group(2).strip()
    return out


def _resolve(vars_, value, depth=0):
    if depth > 20:
        die('a var() chain in the export loops')

    def sub(m):
        name, fallback = m.group(1), m.group(2)
        if name in vars_:
            return _resolve(vars_, vars_[name], depth + 1)
        return fallback.strip() if fallback else ''
    return re.sub(r'var\(\s*(--[\w-]+)\s*(?:,\s*([^()]*))?\)', sub, value)


def _oklch_hex(l, c, h):
    a, b = c * math.cos(math.radians(h)), c * math.sin(math.radians(h))
    l_ = (l + 0.3963377774 * a + 0.2158037573 * b) ** 3
    m_ = (l - 0.1055613458 * a - 0.0638541728 * b) ** 3
    s_ = (l - 0.0894841775 * a - 1.2914855480 * b) ** 3
    rgb = (4.0767416621 * l_ - 3.3077115913 * m_ + 0.2309699292 * s_,
           -1.2684380046 * l_ + 2.6097574011 * m_ - 0.3413193965 * s_,
           -0.0041960863 * l_ - 0.7034186147 * m_ + 1.7076147010 * s_)

    def enc(x):
        x = min(max(x, 0.0), 1.0)
        x = 12.92 * x if x <= 0.0031308 else 1.055 * x ** (1 / 2.4) - 0.055
        return round(x * 255)
    return '#' + ''.join(f'{enc(x):02X}' for x in rgb)


def _color(value):
    """A CSS colour as "#RRGGBB", or None for one this cannot read."""
    v = value.strip()
    m = re.fullmatch(r'#([0-9A-Fa-f]{3}|[0-9A-Fa-f]{6})', v)
    if m:
        h = m.group(1)
        if len(h) == 3:
            h = ''.join(ch * 2 for ch in h)
        return '#' + h.upper()
    m = re.fullmatch(r'rgba?\(\s*(\d+)[\s,]+(\d+)[\s,]+(\d+)[^)]*\)', v)
    if m:
        return '#' + ''.join(f'{int(x):02X}' for x in m.groups())
    m = re.fullmatch(r'oklch\(\s*([\d.]+)(%?)\s+([\d.]+)\s+([\d.]+)(?:deg)?\s*(?:/[^)]*)?\)', v)
    if m:
        l = float(m.group(1)) / (100 if m.group(2) else 1)
        return _oklch_hex(l, float(m.group(3)), float(m.group(4)))
    return None


def _families(value):
    fams = [f.strip().strip('"\'') for f in value.split(',')]
    return [f for f in fams if f and not TEX_UNSAFE.search(f)]


# Which of the export's semantic roles fills which token. The first name that
# the export defines wins; a token none of them fills keeps the house value.
# Two naming schemes so far: --text-*/--surface-*/--border-* and the numbered
# --fg-1/--bg-page/--border-1 of a Claude Design export like Bayesian
# Squirrel's. A new export with other names gets a row here, not a special case.
IMPORT_COLOR = {
    'ink': ('--text-primary', '--color-text', '--ink', '--fg-1'),
    'ink-secondary': ('--text-secondary', '--fg-2'),
    'ink-muted': ('--text-muted', '--fg-3'),
    'paper': ('--surface-page', '--color-background', '--background', '--bg-page'),
    'fill': ('--surface-subtle', '--surface-sunken'),
    'code-fill': ('--surface-sunken',),
    'accent': ('--brand-accent', '--color-primary', '--primary', '--accent',
               '--fg-accent', '--action-accent'),
    'rule': ('--border-default', '--border', '--border-1'),
}
IMPORT_TABLE = {
    'header-fill': ('--surface-sunken',),
    'header-text': ('--text-primary', '--fg-1'),
    'rule': ('--border-strong', '--border-default'),
    'stripe': ('--surface-subtle',),
}
IMPORT_TYPE = {
    'body': ('--type-body-family', '--font-sans', '--font-body'),
    'heading': ('--type-heading-family', '--font-heading', '--font-display',
                '--font-sans'),
    'mono': ('--type-data-family', '--font-mono'),
}
HOUSE_INK = '#15140F'  # housestyle.sty's ink, for icons when the system sets none


def _font_faces(export):
    """{family: [(italic, weight, file)]} from the export's @font-face rules."""
    tokdir = os.path.join(export, 'tokens')
    base = tokdir if os.path.isdir(tokdir) else export
    faces = {}
    for f in sorted(os.listdir(base)):
        if not f.endswith('.css'):
            continue
        with open(os.path.join(base, f), encoding='utf-8') as fh:
            css = re.sub(r'/\*.*?\*/', '', fh.read(), flags=re.S)
        for m in re.finditer(r'@font-face\s*\{([^}]*)\}', css):
            body = m.group(1)
            fam = re.search(r'font-family\s*:\s*([^;]+)', body)
            url = re.search(r'url\(\s*[\'"]?([^\'")]+\.(?:woff2|woff|ttf|otf))[\'"]?\s*\)', body, re.I)
            if not (fam and url):
                continue
            w = re.search(r'font-weight\s*:\s*(\w+)', body)
            w = {'normal': 400, 'bold': 700}.get(w.group(1), w.group(1)) if w else 400
            italic = bool(re.search(r'font-style\s*:\s*(italic|oblique)', body))
            path = os.path.normpath(os.path.join(base, url.group(1)))
            if os.path.isfile(path) and str(w).isdigit():
                faces.setdefault(fam.group(1).strip().strip('"\''), []).append(
                    (italic, int(w), path))
    return faces


def _choose_faces(faces):
    """{'regular': (weight, file), ...}: 400 upright and italic, and the
    heaviest weight above it as bold, the one nearest 700."""
    out = {}
    for italic, reg, bold in ((False, 'regular', 'bold'), (True, 'italic', 'bolditalic')):
        fs = sorted((w, p) for i, w, p in faces if i == italic)
        if not fs:
            continue
        out[reg] = min(fs, key=lambda f: (abs(f[0] - 400), f[0]))
        heavy = [f for f in fs if f[0] > out[reg][0]]
        if heavy:
            out[bold] = min(heavy, key=lambda f: abs(f[0] - 700))
    return out if 'regular' in out else {}


def _font_file(src, weight, dest_stem):
    """Write src (woff2, woff, ttf or otf) as a static TrueType or OpenType
    file fontspec loads by path; a variable font is cut at weight. Returns the
    file name written."""
    from fontTools.ttLib import TTFont
    f = TTFont(src, recalcTimestamp=False)
    if 'fvar' in f:
        from fontTools.varLib import instancer
        pins = {a.axisTag: (min(max(weight, a.minValue), a.maxValue)
                            if a.axisTag == 'wght' else a.defaultValue)
                for a in f['fvar'].axes}
        f = instancer.instantiateVariableFont(f, pins)
    f.flavor = None
    out = dest_stem + ('.ttf' if 'glyf' in f else '.otf')
    f.save(out)
    return os.path.basename(out)


def _chrome():
    c = os.environ.get('CHROME')
    if c:
        return c
    for n in ('google-chrome', 'chromium', 'chromium-browser'):
        if shutil.which(n):
            return n
    import glob
    found = sorted(glob.glob(os.path.expanduser(
        '~/.cache/puppeteer/chrome/*/chrome-linux64/chrome')))
    return found[-1] if found else None


def _svg_size(svg):
    tag = re.search(r'<svg\b[^>]*>', svg, re.S)
    tag = tag.group(0) if tag else ''

    def attr(n):
        m = re.search(r'\s%s\s*=\s*"\s*([\d.]+)(?:px)?\s*"' % n, tag)
        return float(m.group(1)) if m else None
    w, h = attr('width'), attr('height')
    if not (w and h):
        vb = re.search(r'viewBox\s*=\s*"\s*[-\d.]+[\s,]+[-\d.]+[\s,]+([\d.]+)[\s,]+([\d.]+)', tag)
        if vb:
            w, h = float(vb.group(1)), float(vb.group(2))
    return (w or 24.0), (h or 24.0)


def svgs_to_pdf(svgs, out, color=None):
    """Write the SVG files as one PDF, a page each at its own size, for
    \\includegraphics; currentColor is painted color when one is given.
    rsvg-convert when installed, else headless Chrome (as diagram-maker's
    export.sh does). False when the machine has neither."""
    import subprocess
    import tempfile
    with tempfile.TemporaryDirectory() as tmp:
        texts = []
        for i, p in enumerate(svgs):
            with open(p, encoding='utf-8') as f:
                t = f.read()
            if color:
                t = t.replace('currentColor', color)
            texts.append(t)
        if shutil.which('rsvg-convert'):
            files = []
            for i, t in enumerate(texts):
                files.append(os.path.join(tmp, f'{i}.svg'))
                with open(files[-1], 'w', encoding='utf-8') as f:
                    f.write(t)
            subprocess.run(['rsvg-convert', '-f', 'pdf', '-o', out] + files, check=True)
            return True
        chrome = _chrome()
        if not chrome:
            return False
        css, body = ['html,body{margin:0}'], []
        for i, t in enumerate(texts):
            w, h = _svg_size(t)
            t = re.sub(r'<\?xml[^>]*\?>|<!DOCTYPE[^>]*>', '', t)
            css.append(f'@page p{i}{{size:{w}px {h}px;margin:0}}'
                       f'.p{i}{{page:p{i};width:{w}px;height:{h}px;overflow:hidden;break-after:page}}'
                       f'.p{i}>svg{{display:block;width:{w}px;height:{h}px}}')
            body.append(f'<div class="p{i}">{t}</div>')
        html = os.path.join(tmp, 'page.html')
        with open(html, 'w', encoding='utf-8') as f:
            f.write('<!doctype html><meta charset="utf-8"><style>' + ''.join(css)
                    + '</style>' + ''.join(body))
        subprocess.run([chrome, '--headless=new', '--disable-gpu', '--no-sandbox',
                        '--no-first-run', f'--user-data-dir={tmp}/profile',
                        '--no-pdf-header-footer', f'--print-to-pdf={out}',
                        'file://' + html], stdout=subprocess.DEVNULL,
                       stderr=subprocess.DEVNULL, check=False)
        if not (os.path.isfile(out) and os.path.getsize(out)):
            die(f'{chrome} wrote no PDF for the SVGs')
        return True


def _rel(path, outdir):
    return os.path.relpath(os.path.abspath(path), outdir)


def import_export(export, out, logo=None, voice=()):
    """Write the tokens file out from the export folder; returns the notes.
    A tokens file already at out keeps its copyright and its voice guides, so
    a re-import after the design changes loses nothing set by hand."""
    vars_ = _css_vars(export)
    outdir = os.path.dirname(os.path.abspath(out))
    os.makedirs(outdir, exist_ok=True)
    old = {}
    if os.path.isfile(out):
        with open(out, encoding='utf-8') as f:
            try:
                old = json.load(f)
            except ValueError:
                old = {}

    def first(names, conv):
        for n in names:
            if n in vars_:
                v = conv(_resolve(vars_, vars_[n]))
                if v:
                    return v
        return None
    tokens = {'name': old.get('name') if isinstance(old.get('name'), str)
              else os.path.basename(os.path.normpath(os.path.abspath(export)))}
    for group, table, conv in (('color', IMPORT_COLOR, _color),
                               ('table', IMPORT_TABLE, _color),
                               ('type', IMPORT_TYPE, _families)):
        g = {}
        for key, names in table.items():
            v = first(names, conv)
            if v:
                g[key] = v
        if g:
            tokens[group] = g
    case = first(('--type-heading-case',), lambda v: v.strip())
    if case == 'uppercase':
        tokens.setdefault('type', {})['heading-case'] = 'uppercase'

    notes = []
    # Fonts by file: a family the type stacks name and the export ships in an
    # @font-face is written as static OTF/TTF beside the tokens file, which
    # fontspec loads by path, so nothing is installed on the machine.
    faces = _font_faces(export)
    wanted = []
    for k in TYPE_LISTS:
        for fam in tokens.get('type', {}).get(k, []):
            if fam in faces and fam not in wanted:
                wanted.append(fam)
    if wanted:
        try:
            import fontTools  # noqa: F401
        except ImportError:
            notes.append('fontTools is not installed, so ' + ', '.join(wanted)
                         + ' still come by name (pip install fonttools brotli)')
            wanted = []
    fontdir = os.path.join(outdir, 'design-fonts')
    if os.path.isdir(fontdir):
        shutil.rmtree(fontdir)
    for fam in wanted:
        chosen = _choose_faces(faces[fam])
        if not chosen:
            notes.append(f'{fam} has no upright face in the export, so it comes by name')
            continue
        os.makedirs(fontdir, exist_ok=True)
        slug = re.sub(r'[^a-z0-9]+', '-', fam.lower()).strip('-')
        entry = {}
        for role, (w, src) in chosen.items():
            stem = os.path.join(fontdir, f'{slug}-{w}' + ('-italic' if 'italic' in role else ''))
            entry[role] = 'design-fonts/' + _font_file(src, w, stem)
        tokens.setdefault('fonts', {})[fam] = entry

    # The logo: one named with --logo (a file, or a name in assets/logo/), the
    # one a re-import remembers, or the only one the export has. An SVG is
    # converted to PDF for LaTeX.
    src = old.get('source', {}) if isinstance(old.get('source'), dict) else {}
    logodir = os.path.join(export, 'assets', 'logo')
    if logo and not os.path.isfile(logo):
        named = [os.path.join(logodir, logo + e) for e in ('', '.svg', '.pdf', '.png', '.jpg')]
        named = [n for n in named if os.path.isfile(n)]
        if not named:
            die(f'--logo {logo} is not a file, nor a logo in {logodir}', 2)
        logo = named[0]
    if logo is None and src.get('logo'):
        logo = os.path.join(outdir, src['logo'])
        if not os.path.isfile(logo):
            notes.append(f'the logo the last import took, {src["logo"]}, is gone; none taken')
            logo = None
    if logo is None and os.path.isdir(logodir):
        cands = sorted(f for f in os.listdir(logodir)
                       if f.lower().endswith(('.png', '.pdf', '.jpg', '.svg')))
        if len(cands) == 1:
            logo = os.path.join(logodir, cands[0])
        elif cands:
            notes.append('several logos, none taken; name one with --logo: '
                         + ', '.join(cands))
    for f in os.listdir(outdir):
        if f.startswith('design-logo.'):
            os.remove(os.path.join(outdir, f))
    ink = tokens.get('color', {}).get('ink', HOUSE_INK)
    if logo:
        ext = os.path.splitext(logo)[1].lower()
        if ext == '.svg':
            if svgs_to_pdf([logo], os.path.join(outdir, 'design-logo.pdf'), ink):
                tokens['logo'] = 'design-logo.pdf'
            else:
                notes.append('no SVG converter here (rsvg-convert or Chrome), so no logo')
        else:
            shutil.copyfile(logo, os.path.join(outdir, 'design-logo' + ext))
            tokens['logo'] = 'design-logo' + ext

    # Icons: every SVG in assets/icons/ as one page of design-icons.pdf, drawn
    # in the system's ink; \dsicon{name} places one inline.
    icondir = os.path.join(export, 'assets', 'icons')
    icons = sorted(f for f in os.listdir(icondir)
                   if f.lower().endswith('.svg')) if os.path.isdir(icondir) else []
    icons = [f for f in icons if ICON_NAME.match(f[:-4])]
    iconpdf = os.path.join(outdir, 'design-icons.pdf')
    if os.path.isfile(iconpdf):
        os.remove(iconpdf)
    if icons:
        if svgs_to_pdf([os.path.join(icondir, f) for f in icons], iconpdf, ink):
            tokens['icons'] = {'file': 'design-icons.pdf', 'names': [f[:-4] for f in icons]}
        else:
            notes.append('no SVG converter here (rsvg-convert or Chrome), so no icons')

    # The voice guide: a pointer the writer follows, never a copy of it.
    guides = [os.path.join(outdir, v) for v in old.get('voice', []) if isinstance(v, str)]
    gdir = os.path.join(export, 'guidelines')
    if os.path.isdir(gdir):
        guides += [os.path.join(gdir, f) for f in sorted(os.listdir(gdir))
                   if 'voice' in f.lower() and f.lower().endswith(('.html', '.md', '.txt'))]
    for v in voice:
        if not os.path.isfile(v):
            die(f'--voice {v} is not a file', 2)
        guides.append(v)
    rels = []
    for g in guides:
        r = _rel(g, outdir)
        if os.path.isfile(g) and r not in rels:
            rels.append(r)
    if rels:
        tokens['voice'] = rels

    if isinstance(old.get('copyright'), dict):
        tokens['copyright'] = old['copyright']
    tokens['source'] = {'path': _rel(export, outdir)}
    if logo:
        tokens['source']['logo'] = _rel(logo, outdir)

    for group, keys in (('color', COLOR_KEYS), ('table', TABLE_KEYS),
                        ('type', TYPE_LISTS)):
        missing = [k for k in keys if k not in tokens.get(group, {})]
        if missing:
            notes.append(f'not in the export, so the house value stays: '
                         + ', '.join(f'{group}.{k}' for k in missing))
    for k in TYPE_LISTS:
        fams = tokens.get('type', {}).get(k, [])
        if fams and not any(f in tokens.get('fonts', {}) for f in fams):
            notes.append(f'type.{k} ({fams[0]}) comes by name: the export ships no file for it')
    probs = check(tokens)
    if probs:
        die('the import made an invalid tokens file:\n  ' + '\n  '.join(probs))
    with open(out, 'w', encoding='utf-8') as f:
        json.dump(tokens, f, indent=2)
        f.write('\n')
    return notes


# ---- LaTeX -----------------------------------------------------------------
# Token -> the housestyle.sty colour it replaces.
LATEX_COLORS = {'ink': 'ink', 'ink-secondary': 'inkseventy',
                'ink-muted': 'inkfiftyfive', 'paper': 'paper', 'fill': 'fill',
                'code-fill': 'codefill', 'accent': 'accent', 'rule': 'rulegrey'}


def _pick(macro, fams):
    """\\IfFontExistsTF over a family stack, first found defining macro."""
    tail = ''
    for f in reversed(fams):
        tail = f'\\IfFontExistsTF{{{f}}}{{\\def{macro}{{{f}}}}}{{{tail}}}'
    return tail


def latex(tokens):
    o = ['% Generated by apply-design-system/ds.py from the design system',
         f'% "{tokens.get("name", "")}". Do not edit: edit the tokens file.',
         '\\makeatletter']
    for key, v in tokens.get('color', {}).items():
        o.append(f'\\definecolor{{{LATEX_COLORS[key]}}}{{HTML}}{{{v[1:]}}}')
    o.append('\\pagecolor{paper}\\color{ink}')
    t = tokens.get('type', {})
    # A CSS stack ends in a generic name no font carries; these stand in for
    # it. A stack none of whose faces is installed keeps the house face.
    generic = {'sans-serif': ['FreeSans', 'DejaVu Sans'],
               'serif': ['FreeSerif', 'DejaVu Serif'],
               'monospace': ['FreeMono', 'DejaVu Sans Mono']}

    def stack(fams):
        out = []
        for f in fams:
            out += generic.get(f, [f])
        return out
    files = tokens.get('fonts', {})

    def face(macro, fams):
        # A family the system ships as files is loaded by path, ahead of the
        # stack's installed faces; otherwise the first installed one wins.
        # Returns the lines that pick it, the font argument, the options every
        # fontspec call adds, and the guard around those calls.
        for f in fams:
            if f in files:
                ff = files[f]
                opts = f'Path={os.path.dirname(ff["regular"])}/,'
                for k, key in (('bold', 'BoldFont'), ('italic', 'ItalicFont'),
                               ('bolditalic', 'BoldItalicFont')):
                    if k in ff:
                        opts += f'{key}={os.path.basename(ff[k])},'
                return [], os.path.basename(ff['regular']), opts, '', ''
        return ([_pick(macro, stack(fams))], macro, '', f'\\ifdefined{macro}', '\\fi')
    if 'body' in t:
        pick, fn, op, on, off = face('\\ds@body', t['body'])
        o += pick + [on,
                     f'  \\setmainfont{{{fn}}}[{op}Numbers={{Proportional,Lining}}]',
                     f'  \\renewfontfamily\\labelfont{{{fn}}}[{op}Letters=SmallCaps,LetterSpace=5.0]',
                     f'  \\renewfontfamily\\hs@eyebrowfont{{{fn}}}[{op}Letters=SmallCaps,LetterSpace=6.0]',
                     f'  \\renewfontfamily\\hs@runfont{{{fn}}}[{op}Letters=SmallCaps,LetterSpace=9.0]',
                     f'  \\renewfontfamily\\hs@notefont{{{fn}}}[{op}Ligatures=TeXOff]',
                     f'  \\renewfontfamily\\hs@figfont{{{fn}}}[{op}Numbers={{Lining,Tabular}}]',
                     off]
    if 'heading' in t:
        pick, fn, op, on, off = face('\\ds@heading', t['heading'])
        o += pick + [on,
                     f'  \\renewfontfamily\\hssubheadfont{{{fn}}}[{op}]',
                     f'  \\renewfontfamily\\hsdisplayfont{{{fn}}}[{op}]',
                     f'  \\renewfontfamily\\statfont{{{fn}}}[{op}Numbers={{Lining,Tabular}}]',
                     off]
    if 'mono' in t:
        pick, fn, op, on, off = face('\\ds@mono', t['mono'])
        o += pick + [f'{on} \\setmonofont{{{fn}}}[{op}Scale=0.86]{off}']
    o = [line for line in o if line]
    if t.get('heading-case') == 'uppercase':
        # Headings, the title, labels and the running head print in capitals,
        # whatever case the source writes them in. The theme loads right after
        # housestyle.sty, ahead of the document's own preamble, which sets its
        # heading formats and may call \hsnumbersections; so the capitals go on
        # at \begin{document}, numbered if \hsnumbersections ran by then.
        head = ('\\titleformat{\\%s}{\\hssubheadfont\\fontsize{%s}{%s}\\selectfont'
                '\\color{ink}}{%s}{%s}{\\MakeUppercase}')
        o += ['\\newcommand\\ds@upperheads{%',
              '  ' + head % ('section', '17pt', '21pt', '', '0pt') + '%',
              '  ' + head % ('subsection', '13pt', '17pt', '', '0pt') + '}',
              '\\newcommand\\ds@upperheadsnum{%',
              '  ' + head % ('section', '17pt', '21pt',
                             '\\textcolor{inkfiftyfive}{\\thesection}', '12pt') + '%',
              '  ' + head % ('subsection', '13pt', '17pt',
                             '\\textcolor{inkfiftyfive}{\\thesubsection}', '8pt') + '}',
              '\\newif\\ifds@num',
              '\\AddToHook{cmd/hsnumbersections/after}{\\ds@numtrue}',
              '\\AddToHook{begindocument/before}{\\ifds@num\\ds@upperheadsnum\\else\\ds@upperheads\\fi}',
              '\\NewCommandCopy\\ds@hstitle\\hstitle',
              '\\renewcommand{\\hstitle}[2][32pt]{\\ds@hstitle[#1]{\\MakeUppercase{#2}}}',
              '\\renewcommand{\\hsrunlabel}[1]{{\\hs@runfont\\fontsize{8pt}{10pt}\\selectfont',
              '  \\color{inkfiftyfive}\\MakeUppercase{#1}}}',
              '\\ExplSyntaxOn',
              '\\cs_set_eq:NN \\__ds_label:nn \\hs_label:nn',
              '\\cs_generate_variant:Nn \\__ds_label:nn { ne }',
              '\\cs_set_protected:Npn \\hs_label:nn #1#2',
              '  { \\__ds_label:ne {#1} { \\text_uppercase:n {#2} } }',
              '\\ExplSyntaxOff']
    if tokens.get('logo'):
        # The logo sits at the right of the first page's head, where the house
        # style leaves the head empty.
        o += ['\\fancypagestyle{hsfirst}{\\fancyhead{}\\renewcommand{\\headrule}{}%',
              f'  \\fancyhead[R]{{\\includegraphics[height=14pt]{{{tokens["logo"]}}}}}}}']
    icons = tokens.get('icons')
    if icons:
        # \dsicon[height]{name}: one of the system's icons, inline, at the
        # height of a capital unless a height is given; an unknown name stops
        # the build and says so.
        o += [f'\\@namedef{{ds@icon@{n}}}{{{i + 1}}}' for i, n in enumerate(icons['names'])]
        o += ['\\NewDocumentCommand\\dsicon{O{0.75em}m}{%',
              '  \\ifcsname ds@icon@#2\\endcsname',
              '    \\raisebox{-0.1em}{\\includegraphics[height=#1,page=\\csname ds@icon@#2\\endcsname]'
              f'{{{icons["file"]}}}}}%',
              '  \\else\\PackageError{design system}{No icon named #2}{The icons are: '
              + ', '.join(icons['names']) + '}\\fi}']
    holder = tokens.get('copyright', {}).get('holder')
    if holder:
        # The foot's copyright line names the workspace's holder; a document's
        # own \hscopyrightholder, set later in its preamble, still wins.
        o.append(f'\\hscopyrightholder{{{holder.strip()}}}')
    o.append('\\makeatother')
    return '\n'.join(o) + '\n'


# ---- xlsx --------------------------------------------------------------------
def _num(s):
    s = s.strip()
    if re.fullmatch(r'-?\d+', s):
        return int(s)
    if re.fullmatch(r'-?\d*\.\d+', s):
        return float(s)
    return None


def _col(i):
    s = ''
    i += 1
    while i:
        i, r = divmod(i - 1, 26)
        s = chr(65 + r) + s
    return s


def xlsx_styles(tokens):
    """The workbook's cell styles, by role, as plain values a writer maps."""
    c, t, tb = tokens.get('color', {}), tokens.get('type', {}), tokens.get('table', {})
    generic = {'sans-serif': 'Arial', 'serif': 'Georgia', 'monospace': 'Courier New'}

    def face(key, default):
        fam = t.get(key, [default])[0]
        return generic.get(fam, fam)
    ink = c.get('ink', '#000000')
    body, head, mono = face('body', 'Calibri'), face('heading', 'Calibri'), face('mono', 'Consolas')
    return {
        'title': {'font': head, 'size': 16, 'color': ink, 'bold': False},
        'header': {'font': body, 'size': 10, 'bold': True,
                   'color': tb.get('header-text', ink), 'fill': tb.get('header-fill'),
                   'bottom': tb.get('rule', ink), 'bottom-style': 'medium'},
        'body': {'font': body, 'size': 10, 'color': ink,
                 'bottom': c.get('rule'), 'bottom-style': 'thin'},
        'number': {'font': mono, 'size': 10, 'color': ink, 'align': 'right',
                   'bottom': c.get('rule'), 'bottom-style': 'thin'},
        'stripe': tb.get('stripe'),
    }


def write_xlsx(path, rows, tokens, title=None, sheet='Sheet1'):
    st = xlsx_styles(tokens)
    upper = tokens.get('type', {}).get('heading-case') == 'uppercase'
    fonts, fills, borders, xfs = [], ['none', 'gray125'], [None], [(0, 0, 0, None, None)]

    def idx(lst, v):
        if v not in lst:
            lst.append(v)
        return lst.index(v)

    fonts.append(('Calibri', 11, '#000000', False))
    xf_of = {}

    def xf(role, striped=False, numfmt=0):
        s = st[role]
        f = idx(fonts, (s['font'], s['size'], s['color'], s.get('bold', False)))
        fillc = s.get('fill') or (st['stripe'] if striped else None)
        fi = idx(fills, fillc) if fillc else 0
        b = idx(borders, (s['bottom-style'], s['bottom'])) if s.get('bottom') else 0
        key = (f, fi, b, s.get('align'), numfmt)
        if key not in xf_of:
            xfs.append(key)
            xf_of[key] = len(xfs) - 1
        return xf_of[key]

    header, data = rows[0], rows[1:]
    ncols = max(len(r) for r in rows)
    cells, r = [], 1
    widths = [len(h) for h in header] + [0] * (ncols - len(header))
    if title:
        text = title.upper() if upper else title
        cells.append((r, [(0, text, xf('title'))], 24))
        r += 2
    head_row = r
    cells.append((r, [(i, h.upper() if upper else h, xf('header')) for i, h in enumerate(header)], 18))
    for n, row in enumerate(data):
        r += 1
        striped = bool(st['stripe']) and n % 2 == 1
        out = []
        for i, v in enumerate(row):
            widths[i] = max(widths[i], len(v))
            num = _num(v)
            # Built-in numFmtId: 3 = "#,##0" for an int, 4 = "#,##0.00" for a float.
            numfmt = 3 if isinstance(num, int) else 4 if isinstance(num, float) else 0
            out.append((i, num if num is not None else v,
                        xf('number' if num is not None else 'body', striped, numfmt)))
        cells.append((r, out, None))

    def argb(h):
        return 'FF' + h[1:].upper()
    sx = ['<?xml version="1.0" encoding="UTF-8" standalone="yes"?>',
          '<styleSheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">',
          f'<fonts count="{len(fonts)}">']
    for name, size, color, bold in fonts:
        sx.append(f'<font>{"<b/>" if bold else ""}<sz val="{size}"/>'
                  f'<color rgb="{argb(color)}"/><name val="{escape(name)}"/></font>')
    sx.append(f'</fonts><fills count="{len(fills)}">')
    for fl in fills:
        if fl in ('none', 'gray125'):
            sx.append(f'<fill><patternFill patternType="{fl}"/></fill>')
        else:
            sx.append(f'<fill><patternFill patternType="solid"><fgColor rgb="{argb(fl)}"/>'
                      '<bgColor indexed="64"/></patternFill></fill>')
    sx.append(f'</fills><borders count="{len(borders)}">')
    for bd in borders:
        if bd is None:
            sx.append('<border><left/><right/><top/><bottom/><diagonal/></border>')
        else:
            sx.append(f'<border><left/><right/><top/><bottom style="{bd[0]}">'
                      f'<color rgb="{argb(bd[1])}"/></bottom><diagonal/></border>')
    sx.append('</borders><cellStyleXfs count="1"><xf numFmtId="0" fontId="0" fillId="0" borderId="0"/>'
              f'</cellStyleXfs><cellXfs count="{len(xfs)}">')
    for f, fi, b, align, numfmt in xfs:
        nf = numfmt or 0
        al = f'<alignment horizontal="{align}" vertical="center"/>' if align else '<alignment vertical="center"/>'
        sx.append(f'<xf numFmtId="{nf}" fontId="{f}" fillId="{fi}" borderId="{b}" xfId="0" '
                  f'applyFont="1" applyFill="1" applyBorder="1" applyAlignment="1"'
                  + (' applyNumberFormat="1"' if nf else '') + f'>{al}</xf>')
    sx.append('</cellXfs><cellStyles count="1"><cellStyle name="Normal" xfId="0" builtinId="0"/>'
              '</cellStyles></styleSheet>')

    ws = ['<?xml version="1.0" encoding="UTF-8" standalone="yes"?>',
          '<worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">',
          f'<sheetViews><sheetView workbookViewId="0" showGridLines="0"><pane ySplit="{head_row}" '
          f'topLeftCell="A{head_row + 1}" activePane="bottomLeft" state="frozen"/></sheetView></sheetViews>',
          '<cols>']
    for i, w in enumerate(widths):
        ws.append(f'<col min="{i + 1}" max="{i + 1}" width="{min(max(w + 3, 8), 60)}" customWidth="1"/>')
    ws.append('</cols><sheetData>')
    for rn, row, ht in cells:
        hattr = f' ht="{ht}" customHeight="1"' if ht else ''
        ws.append(f'<row r="{rn}"{hattr}>')
        for i, v, s in row:
            ref = f'{_col(i)}{rn}'
            if isinstance(v, (int, float)):
                ws.append(f'<c r="{ref}" s="{s}"><v>{v}</v></c>')
            else:
                ws.append(f'<c r="{ref}" s="{s}" t="inlineStr"><is><t xml:space="preserve">'
                          f'{escape(v)}</t></is></c>')
        ws.append('</row>')
    ws.append('</sheetData><pageMargins left="0.7" right="0.7" top="0.75" bottom="0.75" '
              'header="0.3" footer="0.3"/></worksheet>')

    parts = {
        '[Content_Types].xml':
            '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
            '<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">'
            '<Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>'
            '<Default Extension="xml" ContentType="application/xml"/>'
            '<Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/>'
            '<Override PartName="/xl/worksheets/sheet1.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>'
            '<Override PartName="/xl/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.styles+xml"/>'
            '</Types>',
        '_rels/.rels':
            '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
            '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
            '<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="xl/workbook.xml"/>'
            '</Relationships>',
        'xl/workbook.xml':
            '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
            '<workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" '
            'xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">'
            f'<sheets><sheet name="{escape(sheet[:31])}" sheetId="1" r:id="rId1"/></sheets></workbook>',
        'xl/_rels/workbook.xml.rels':
            '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
            '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
            '<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet1.xml"/>'
            '<Relationship Id="rId2" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/>'
            '</Relationships>',
        'xl/styles.xml': ''.join(sx),
        'xl/worksheets/sheet1.xml': ''.join(ws),
    }
    with zipfile.ZipFile(path, 'w', zipfile.ZIP_DEFLATED) as z:
        for name, body in parts.items():
            # A fixed stamp, so the same rows and tokens make the same bytes.
            z.writestr(zipfile.ZipInfo(name, (2026, 1, 1, 0, 0, 0)), body)


# ---- command line ------------------------------------------------------------
def _opt(args, flag):
    if flag in args:
        i = args.index(flag)
        if i + 1 >= len(args):
            die(f'{flag} needs a value', 2)
        v = args[i + 1]
        del args[i:i + 2]
        return v
    return None


def main(argv):
    if not argv or argv[0] in ('-h', '--help'):
        print(__doc__)
        return 0 if argv else 2
    cmd, args = argv[0], list(argv[1:])
    if cmd == 'find':
        p = find(args[0] if args else '.')
        if p:
            print(p)
            return 0
        return 1
    if cmd == 'import':
        out, logo = _opt(args, '-o'), _opt(args, '--logo')
        voice = []
        while '--voice' in args:
            voice.append(_opt(args, '--voice'))
        usage = 'usage: ds.py import [<export-dir>] [-o out] [--logo file] [--voice file]...'
        if len(args) > 1:
            die(usage, 2)
        out = out or (find('.') if not args else None) or TOKENS_REL
        if args:
            export = args[0]
        else:
            # A re-import: the export is the one the tokens file came from.
            try:
                with open(out, encoding='utf-8') as f:
                    src = json.load(f).get('source', {})
                export = os.path.join(os.path.dirname(os.path.abspath(out)), src['path'])
            except (OSError, ValueError, KeyError, TypeError, AttributeError):
                die(f'{out} names no source export to re-import; give the export folder', 2)
        if not os.path.isdir(export):
            die(f'{export} is not a folder\n{usage}', 2)
        for n in import_export(export, out, logo, voice):
            print(f'note: {n}', file=sys.stderr)
        print(f'wrote {out}')
        return 0
    if cmd == 'check':
        if len(args) != 1:
            die('usage: ds.py check <tokens.json>', 2)
        load(args[0])
        print(f'{args[0]}: ok')
        return 0
    if cmd == 'voice':
        if len(args) != 1:
            die('usage: ds.py voice <tokens.json>', 2)
        for v in load(args[0])['voice']:
            if os.path.isfile(v):
                print(v)
            else:
                print(f'ds.py: {args[0]} names voice guide {v}, which is not there;'
                      ' re-import to drop it', file=sys.stderr)
        return 0
    if cmd == 'latex':
        if len(args) != 1:
            die('usage: ds.py latex <tokens.json>', 2)
        sys.stdout.write(latex(load(args[0])))
        return 0
    if cmd == 'xlsx':
        out, title = _opt(args, '-o'), _opt(args, '--title')
        tok, sheet = _opt(args, '--tokens'), _opt(args, '--sheet') or 'Sheet1'
        if len(args) != 1 or not out:
            die('usage: ds.py xlsx <data.csv> -o out.xlsx [--title T] [--tokens file] [--sheet S]', 2)
        if not os.path.isfile(args[0]):
            die(f'{args[0]} is not a file', 2)
        tok = tok or find(os.path.dirname(os.path.abspath(args[0])))
        if not tok:
            die('no design system applies here (see `ds.py find`); give --tokens')
        with open(args[0], newline='', encoding='utf-8') as f:
            rows = [r for r in csv.reader(f) if r]
        if not rows:
            die(f'{args[0]} has no rows')
        write_xlsx(out, rows, load(tok), title, sheet)
        print(f'wrote {out}')
        return 0
    die(f'unknown command {cmd!r}; ds.py --help lists them', 2)


if __name__ == '__main__':
    sys.exit(main(sys.argv[1:]))
