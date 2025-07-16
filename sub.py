#!/usr/bin/env python3
import re
import sys
import argparse
from collections import defaultdict, deque

class UnionFind:
    def __init__(self):
        self.parent = {}
    def find(self, x):
        if x not in self.parent:
            self.parent[x] = x
        if self.parent[x] != x:
            self.parent[x] = self.find(self.parent[x])
        return self.parent[x]
    def union(self, a, b):
        ra, rb = self.find(a), self.find(b)
        if ra != rb:
            self.parent[ra] = rb
    def groups(self):
        """Return dict rep -> set(members)."""
        out = defaultdict(set)
        for x in self.parent:
            out[self.find(x)].add(x)
        return out

def parse_owl(filename):
    prefixes = []
    sub_axioms = []        # list of (sub, sup)
    eq_axioms = []         # list of [c1, c2, ...]
    in_ontology = False

    re_prefix = re.compile(r'^\s*Prefix\(([^)]+)\)\s*$', re.IGNORECASE)
    re_sub = re.compile(r'^\s*SubClassOf\(\s*([^ \t\)]+)\s+([^ \t\)]+)\s*\)\s*$', re.IGNORECASE)
    re_eq = re.compile(r'^\s*EquivalentClasses\(\s*([^\)]+)\s*\)\s*$', re.IGNORECASE)

    with open(filename) as f:
        for line in f:
            line = line.strip()
            if not in_ontology:
                m = re_prefix.match(line)
                if m:
                    prefixes.append(line)
                    continue
                if line.lower().startswith('ontology('):
                    in_ontology = True
                    continue
            else:
                if line == ')' or line.lower() == 'ontology(':
                    continue
                m = re_sub.match(line)
                if m:
                    sub_axioms.append((m.group(1), m.group(2)))
                    continue
                m = re_eq.match(line)
                if m:
                    iris = m.group(1).split()
                    eq_axioms.append(iris)
                    continue
    return prefixes, sub_axioms, eq_axioms

def build_taxonomy(sub_axioms, eq_axioms):
    # subclass mapping: child -> set(parents)
    parents = defaultdict(set)
    for sub, sup in sub_axioms:
        parents[sub].add(sup)
    # build union-find for equivalence
    uf = UnionFind()
    for group in eq_axioms:
        for i in range(len(group)-1):
            uf.union(group[i], group[i+1])
    # ensure all IRIs appear
    for sub, sup in sub_axioms:
        uf.find(sub); uf.find(sup)
    return parents, uf

def extract_subtaxonomy(parents, uf, seeds):
    seen = set()      # all IRIs we have processed
    to_visit = deque(seeds)
    seen.update(seeds)

    # store the edges we need
    needed_sub = set()   # (sub, sup)
    # at the end we'll regenerate eq groups from uf.groups()

    while to_visit:
        cur = to_visit.popleft()
        # all eq members of cur should be considered too
        for member in uf.groups().get(uf.find(cur), {cur}):
            if member not in seen:
                seen.add(member)
                to_visit.append(member)
        # now take all direct parents
        for sup in parents.get(cur, ()):
            needed_sub.add((cur, sup))
            if sup not in seen:
                seen.add(sup)
                to_visit.append(sup)

    return needed_sub, seen

def write_ontology(outfn, prefixes, needed_sub, uf, seen):
    # invert groups
    groups = uf.groups()
    with open(outfn, 'w') as f:
        # write prefixes
        for p in prefixes:
            f.write(p + '\n')
        f.write('\nOntology(\n')
        # write all SubClassOf among seen
        for sub, sup in sorted(needed_sub):
            f.write(f'  SubClassOf({sub} {sup})\n')
        # write all EquivalentClasses for groups intersecting seen
        for rep, members in sorted(groups.items()):
            inter = members & seen
            if len(inter) > 1:
                # preserve full group for that rep
                # but only once
                full = sorted(groups[rep])
                f.write('  EquivalentClasses(' + ' '.join(full) + ')\n')
        f.write(')\n')

def main():
    parser = argparse.ArgumentParser(description='Extract sub-taxonomy from a functional OWL file.')
    parser.add_argument('input',  help='input OWL (functional syntax)')
    parser.add_argument('output', help='output OWL (functional syntax)')
    parser.add_argument('classes', nargs='+', help='one or more class IRIs to seed the extraction')
    args = parser.parse_args()

    prefixes, sub_axioms, eq_axioms = parse_owl(args.input)
    parents, uf = build_taxonomy(sub_axioms, eq_axioms)
    needed_sub, seen = extract_subtaxonomy(parents, uf, args.classes)
    write_ontology(args.output, prefixes, needed_sub, uf, seen)
    print(f'Wrote sub-taxonomy for {args.classes} to {args.output}')

if __name__ == '__main__':
    main()
