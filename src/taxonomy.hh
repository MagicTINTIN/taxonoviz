#pragma once
#ifndef TAXONOMY_HH
#define TAXONOMY_HH

#include <string>
#include <unordered_map>
#include <unordered_set>
#include <vector>

class Taxonomy {
public:
    std::unordered_map<std::string, std::unordered_set<std::string>> subclassOf;
    std::unordered_map<std::string, std::string> equivalenceClassReplace;
    std::unordered_map<std::string, std::string> equivalenceClass;

    void addSubClassOf(const std::string& sub, const std::string& sup);
    void addEquivalentClassesReplacer(const std::string &c1, const std::string &c2);
    void addEquivalentClasses(const std::string &c1, const std::string &c2);
    void addEquivalentClasses(std::vector<std::string> &equivalent_classes);

    void writeDOT(const std::string& filename);
};

#endif // TAXONOMY_HH