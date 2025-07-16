#include <fstream>
#include <iostream>
#include "taxonomy.hh"

std::string find(Taxonomy &t, const std::string &c)
{
    if (t.equivalenceClassReplace.find(c) == t.equivalenceClassReplace.end())
        return c;
    if (t.equivalenceClassReplace[c] == c)
        return c;
    return t.equivalenceClassReplace[c] = find(t, t.equivalenceClassReplace[c]);
}

void Taxonomy::addSubClassOf(const std::string &sub, const std::string &sup)
{
    auto repSub = find(*this, sub);
    auto repSup = find(*this, sup);
    subclassOf[repSub].insert(repSup);
    std::cout << sub << " ⊑ " << sup << "\n";
}

void Taxonomy::addEquivalentClassesReplacer(const std::string &c1, const std::string &c2)
{
    auto rep1 = find(*this, c1);
    auto rep2 = find(*this, c2);
    if (rep1 != rep2)
    {
        equivalenceClassReplace[rep1] = rep2; // Union
    }
}

void Taxonomy::addEquivalentClasses(const std::string &c1, const std::string &c2)
{
    equivalenceClass[c1] = c2;
}

void Taxonomy::addEquivalentClasses(std::vector<std::string> &equivalent_classes)
{
    for (size_t i = 0; i < equivalent_classes.size() - 1; i++)
    {
        addEquivalentClassesReplacer(equivalent_classes[i], equivalent_classes[equivalent_classes.size() - 1]);
        for (size_t n = i + 1; n < equivalent_classes.size(); n++)
        {
            addEquivalentClasses(equivalent_classes[i], equivalent_classes[n]);
        }
    }
    for (size_t i = 0; i < equivalent_classes.size() - 1; i++)
    {
        std::cout << equivalent_classes[i] << " ≡ ";
    }
    std::cout << equivalent_classes[equivalent_classes.size() - 1] << "\n";
}

void Taxonomy::writeDOT(const std::string &filename)
{
    std::ofstream out(filename);
    out << "digraph Taxonomy {\n";
    for (auto &pair : subclassOf)
    {
        auto sub = pair.first;
        for (auto &sup : pair.second)
        {
            out << "  \"" << sub << "\" -> \"" << sup << "\";\n";
        }
    }
    for (auto &pair : equivalenceClass)
    {
        auto a = pair.first;
        out << "  \"" << pair.first << "\" -> \"" << pair.second << "\" [style=invis];\n";
        out << "  \"" << pair.first << "\" -> \"" << pair.second << "\" [dir=both];\n";
    }
    out << "}\n";
}