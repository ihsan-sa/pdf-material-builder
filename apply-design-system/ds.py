#!/usr/bin/env python3
"""ds.py -- a workspace's own design system, read by every generator.

A workspace selects a design system by committing one file at its repo root:

    <repo>/.cc/design-tokens.json

and everything generated inside that repo wears it. A repo without the file
keeps the owner's house look: `find` prints nothing, and a generator that
finds nothing does exactly what it did before. Standard library only.

    ds.py find [dir]                  print the tokens file that applies to dir
                                      (default: the current directory); exit 1
                                      and print nothing when none does
    ds.py import <export> [-o out] [--logo file]
                                      turn a Claude Design export (a folder
                                      whose tokens/*.css hold :root custom
                                      properties) into a tokens file, default
                                      .cc/design-tokens.json; the logo is copied
                                      beside it
    ds.py check <tokens.json>         validate a tokens file
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
     "logo":  "logo.png"}                  relative to the tokens file
Every key is optional: one left out keeps the house value.

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
TOP_KEYS = ('name', 'color', 'type', 'table', 'logo')
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
    return probs


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
    logo = tokens.get('logo')
    if logo:
        full = os.path.join(os.path.dirname(os.path.abspath(path)), logo)
        if not os.path.isfile(full):
            die(f'{path} names logo {logo}, which is not beside it')
        if TEX_UNSAFE.search(full) or ' ' in full:
            die(f'the logo path {full} has a space or a TeX special character')
        tokens['logo'] = full
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
IMPORT_COLOR = {
    'ink': ('--text-primary', '--color-text', '--ink'),
    'ink-secondary': ('--text-secondary',),
    'ink-muted': ('--text-muted',),
    'paper': ('--surface-page', '--color-background', '--background'),
    'fill': ('--surface-subtle',),
    'code-fill': ('--surface-sunken',),
    'accent': ('--brand-accent', '--color-primary', '--primary', '--accent'),
    'rule': ('--border-default', '--border'),
}
IMPORT_TABLE = {
    'header-fill': ('--surface-sunken',),
    'header-text': ('--text-primary',),
    'rule': ('--border-strong', '--border-default'),
    'stripe': ('--surface-subtle',),
}
IMPORT_TYPE = {
    'body': ('--type-body-family', '--font-sans', '--font-body'),
    'heading': ('--type-heading-family', '--font-heading', '--font-sans'),
    'mono': ('--type-data-family', '--font-mono'),
}


def import_export(export, out, logo=None):
    vars_ = _css_vars(export)

    def first(names, conv):
        for n in names:
            if n in vars_:
                v = conv(_resolve(vars_, vars_[n]))
                if v:
                    return v
        return None
    tokens = {'name': os.path.basename(os.path.normpath(export))}
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
    logodir = os.path.join(export, 'assets', 'logo')
    if logo is None and os.path.isdir(logodir):
        cands = sorted(f for f in os.listdir(logodir)
                       if f.lower().endswith(('.png', '.pdf', '.jpg')))
        if len(cands) == 1:
            logo = os.path.join(logodir, cands[0])
        elif cands:
            notes.append('several logos, none taken; name one with --logo: '
                         + ', '.join(cands))
    os.makedirs(os.path.dirname(os.path.abspath(out)), exist_ok=True)
    if logo:
        if not os.path.isfile(logo):
            die(f'--logo {logo} is not a file', 2)
        name = 'design-logo' + os.path.splitext(logo)[1].lower()
        shutil.copyfile(logo, os.path.join(os.path.dirname(os.path.abspath(out)), name))
        tokens['logo'] = name
    for key in COLOR_KEYS:
        if key not in tokens.get('color', {}):
            notes.append(f'color.{key} not in the export; the house value stays')
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
    if 'body' in t:
        o.append(_pick('\\ds@body', stack(t['body'])))
        o += ['\\ifdefined\\ds@body',
              '  \\setmainfont{\\ds@body}[Numbers={Proportional,Lining}]',
              '  \\renewfontfamily\\labelfont{\\ds@body}[Letters=SmallCaps,LetterSpace=5.0]',
              '  \\renewfontfamily\\hs@eyebrowfont{\\ds@body}[Letters=SmallCaps,LetterSpace=6.0]',
              '  \\renewfontfamily\\hs@runfont{\\ds@body}[Letters=SmallCaps,LetterSpace=9.0]',
              '  \\renewfontfamily\\hs@notefont{\\ds@body}[Ligatures=TeXOff]',
              '  \\renewfontfamily\\hs@figfont{\\ds@body}[Numbers={Lining,Tabular}]',
              '\\fi']
    if 'heading' in t:
        o.append(_pick('\\ds@heading', stack(t['heading'])))
        o += ['\\ifdefined\\ds@heading',
              '  \\renewfontfamily\\hssubheadfont{\\ds@heading}[]',
              '  \\renewfontfamily\\hsdisplayfont{\\ds@heading}[]',
              '  \\renewfontfamily\\statfont{\\ds@heading}[Numbers={Lining,Tabular}]',
              '\\fi']
    if 'mono' in t:
        o.append(_pick('\\ds@mono', stack(t['mono'])))
        o += ['\\ifdefined\\ds@mono \\setmonofont{\\ds@mono}[Scale=0.86]\\fi']
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
        if len(args) != 1 or not os.path.isdir(args[0]):
            die('usage: ds.py import <export-dir> [-o out] [--logo file]', 2)
        out = out or TOKENS_REL
        for n in import_export(args[0], out, logo):
            print(f'note: {n}', file=sys.stderr)
        print(f'wrote {out}')
        return 0
    if cmd == 'check':
        if len(args) != 1:
            die('usage: ds.py check <tokens.json>', 2)
        load(args[0])
        print(f'{args[0]}: ok')
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
