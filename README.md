# Taxonoviz
Converts an owl (functional) taxonomy to a .dot (Graphviz)

To compile
```bash
./compile.sh --release
```

Then run:
```bash
build/taxonoviz -i taxonomy.owl -o taxonomy.dot
dot -Tpng taxonomy.dot -o taxonomy.png
```