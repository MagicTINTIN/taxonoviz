// main.cpp
#include <iostream>
#include <string>
#include <unistd.h>
#include "taxonomy.hh"

extern FILE * yyin;
int yyparse(Taxonomy *tx);

void printUsage(const char* progName) {
    std::cerr << "Usage: " << progName << " -i <input.owl> -o <output.dot>\n";
}

int main(int argc, char* argv[]) {
    std::string inputFile;
    std::string outputFile;
	FILE *input_ontology;
    int opt;

    while ((opt = getopt(argc, argv, "i:o:")) != -1) {
        switch (opt) {
            case 'i':
                inputFile = optarg;
                break;
            case 'o':
                outputFile = optarg;
                break;
            default:
                printUsage(argv[0]);
                return 1;
        }
    }

	input_ontology = fopen(inputFile.c_str(), "r");

    if (inputFile.empty() || outputFile.empty() || input_ontology == NULL) {
        printUsage(argv[0]);
        return 1;
    }

    Taxonomy tax;
    yyin = input_ontology;
    int parser = yyparse(&tax);
	if (parser != 0)
    {
        // print_short_stats(this);
        fprintf(stderr, "aborting\n");
        exit(-1);
    }

    try {
        tax.writeDOT(outputFile);
    } catch (const std::exception& e) {
        std::cerr << "Error writing DOT file: " << e.what() << "\n";
        return 3;
    }

    std::cout << "Successfully wrote taxonomy to " << outputFile << "\n";
    return 0;
}
