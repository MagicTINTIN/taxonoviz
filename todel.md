Below is a standalone Python 3 script, **`extract_subtaxonomy.py`**, which

1. Reads a Functional‐style OWL file containing only `Prefix`, `SubClassOf` and `EquivalentClasses` axioms
2. Takes one or more **class IRIs** as positional arguments
3. Recursively collects all **subsumers** and **equivalent classes** of those inputs
4. Writes out a new file with the **same prefix declarations**, plus exactly the `SubClassOf(...)` and `EquivalentClasses(...)` axioms **among** the collected classes

```python
#!/usr/bin/env python3
"""
extract_subtaxonomy.py

Usage:
    extract_subtaxonomy.py INPUT.owl OUTPUT.owl Class1 [Class2 ...]
"""
import re
import sys
import argparse
from collections import defaultdict, deque

def parse_args():
    p = argparse.ArgumentParser(
        description="Extract sub-taxonomy for given classes from a functional OWL file")
    p.add_argument("input",  help="input OWL (functional syntax)")
    p.add_argument("output", help="output OWL (functional syntax)")
    p.add_argument("classes", nargs='+',
                   help="one or more class IRIs (e.g. :Cat or <http://...#Cat>)")
    return p.parse_args()

def main():
    args = parse_args()

    prefixes = []
    raw_sub = []    # list of (sub, sup)
    raw_eq = []     # list of [c1, c2, ...]
    # regexes
    pref_re = re.compile(r'^(Prefix\(\s*\w+:\s*<[^>]+>\s*\))')
    sub_re  = re.compile(r'^SubClassOf\(\s*([^ )]+)\s+([^ )]+)\s*\)')
    eq_re   = re.compile(r'^EquivalentClasses\(\s*([^)]+)\s*\)')

    # 1) Read and parse
    with open(args.input) as f:
        for line in f:
            line = line.strip()
            if not line or line.startswith('#'):
                continue
            m = pref_re.match(line)
            if m:
                prefixes.append(m.group(1))
                continue
            m = sub_re.match(line)
            if m:
                raw_sub.append((m.group(1), m.group(2)))
                continue
            m = eq_re.match(line)
            if m:
                # split on whitespace
                toks = line[len("EquivalentClasses("):-1].strip().split()
                raw_eq.append(toks)
                continue
            # ignore everything else

    # 2) Build graph and union-find
    parent = {}       # union-find parent mapping
    def find(x):
        parent.setdefault(x, x)
        if parent[x] != x:
            parent[x] = find(parent[x])
        return parent[x]
    def union(a, b):
        ra, rb = find(a), find(b)
        if ra != rb:
            parent[ra] = rb

    # collect all classes seen
    all_classes = set()
    for s, o in raw_sub:
        all_classes |= {s, o}
    for group in raw_eq:
        all_classes |= set(group)
    for c in all_classes:
        parent.setdefault(c, c)

    # apply all EquivalentClasses axioms
    for group in raw_eq:
        # union them all into one set
        first = group[0]
        for other in group[1:]:
            union(first, other)

    # build subsumption map on *representatives*
    supers = defaultdict(set)  # rep -> set of rep
    for s, o in raw_sub:
        rs, ro = find(s), find(o)
        if rs != ro:
            supers[rs].add(ro)

    # 3) compute closure for requested classes
    requested = [find(c) for c in args.classes]
    queue = deque(requested)
    relevant = set(requested)
    while queue:
        c = queue.popleft()
        # add all equivalents
        for x in all_classes:
            if find(x) == c and x not in relevant:
                relevant.add(x)
                queue.append(x)
        # add all direct superclasses
        for sp in supers.get(c, []):
            if sp not in relevant:
                relevant.add(sp)
                queue.append(sp)

    # 4) prepare output axioms
    out_sub = []
    for s, o in raw_sub:
        if s in relevant and o in relevant:
            out_sub.append((s, o))
    # for equivalent groups, re-build by rep
    eq_groups = defaultdict(list)
    for c in all_classes:
        if c in relevant:
            eq_groups[find(c)].append(c)
    out_eq = [grp for grp in eq_groups.values() if len(grp) > 1]

    # 5) write result
    with open(args.output, 'w') as w:
        # prefixes
        for p in prefixes:
            w.write(p + "\n")
        w.write("\n")
        # SubClassOf axioms
        for s, o in out_sub:
            w.write(f"SubClassOf({s} {o})\n")
        w.write("\n")
        # EquivalentClasses axioms
        for grp in out_eq:
            w.write("EquivalentClasses(" + " ".join(grp) + ")\n")

    print(f"Wrote {len(out_sub)} SubClassOf and {len(out_eq)} EquivalentClasses axioms to {args.output}")

if __name__ == "__main__":
    main()
```

### How it works

1. **Prefix capture**
   Lines beginning with `Prefix(...)=<...>` are collected verbatim and emitted first.
2. **Axiom parsing**

   * **`SubClassOf(A B)`** → stored as `(A, B)`
   * **`EquivalentClasses(A B C...)`** → stored as list `['A','B','C',…]`
3. **Union‐find**
   All `EquivalentClasses` are unioned into disjoint sets; each class’s representative is `find(c)`.
4. **Subsumption graph**
   We collapse every `SubClassOf(s o)` to `SubClassOf(find(s) find(o))` (dropping “self‐loops”).
5. **Closure**
   Starting from your input IRIs (union‐find normalized), we BFS:

   * Add all equivalent members of each class
   * Add all direct superclasses
     … until fixpoint.
6. **Output**
   Emits only those `SubClassOf` and `EquivalentClasses` axioms **whose terms lie entirely in that closure**.

---

#### Usage example

```bash
chmod +x extract_subtaxonomy.py
./extract_subtaxonomy.py ontology.owl subtax.owl :Cat :Mammal
# -> subtax.owl will contain all prefixes, plus the relevant SubClassOf / EquivalentClasses
```

Feel free to adapt the regexes (e.g. to handle `Class(...)` wrappers) or to hook in an OWL‐API parser if you need more generality.
