# Taxonoviz
<img src="taxonoviz.png" width="120px" height="120px">

Converts an owl (functional) taxonomy to a .dot (Graphviz)

> Functional owl parser Lex/Yacc structure coming from ELpHant reasoner.

To compile
```bash
./compile.sh --release
```

## OWL to DOT
Then run:
```bash
build/taxonoviz -i taxonomy.owl -o taxonomy.dot
```

## DOT to PNG
You can then easily convert your Graphviz .dot file to a .png file.\
There are several dispositions available to represent the tree.
```bash
fdp -Tpng taxonomy.dot -o taxonomy.png # will give pretty good results
circo -Tpng taxonomy.dot -o taxonomy.png # good alternative with good results too
dot -Tpng taxonomy.dot -o taxonomy.png # not really readable with big ontologies
```

---
# Ontology extractor

You can use sub.py script to extract a part of your ontology (still in functional style). Just enter which classes you want to keep, and it will only keep your classes, their subsumers (parent classes) and each of their equivalences.
```bash
python sub.py big_ontology.owl extracted_ontology.owl "<http://example.org/owl#cat>" "<http://example.org/owl#marmot>" ...
```