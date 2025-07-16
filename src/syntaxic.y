/* 
 * Yacc parser structure coming from Elephant Reasoner 
 *
 * The Elephant Reasoner
 * 
 * Copyright (C) Baris Sertkaya (sertkaya.baris@gmail.com)
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */


%code requires {
    #include "taxonomy.hh"
}

%{
	// #define YYDEBUG 1
	#include <stdio.h>
	#include <assert.h>
	#include <string.h>
	#include <string>
	#include <vector>
	#include <sys/types.h>
	// #include "datatypes.hh"
	// #include "../model/datatypes.h"
	// #include "../model/model.h"
	// #include "../model/limits.h"
    #include "taxonomy.hh"

	// int yydebug = 1;
	
	// #define YYSTYPE Expression

	extern char* yytext;
	int yylex(void);
	extern int yylineno;
	// void yyerror(TBox* tbox, ABox* abox, char* msg);
	// void yyerror(KB* kb, char* msg);
	void yyerror(Taxonomy* tx, std::string msg);
	extern FILE *yyin;
	// extern TBox* tbox;
	u_int32_t value = 2;

	std::vector<std::string> conjuncts = {};
	std::vector<std::string> equivalent_classes = {};
	std::vector<std::string> equivalent_objectproperties = {};
	std::vector<std::string> objectproperty_chain_components = {};
	std::vector<std::string> disjoint_classes = {};

    extern Taxonomy* tx;

	void unsupported_feature(std::string feature);
    void not_reimplemented_feature(std::string feature);
%}

%parse-param {Taxonomy* tx} 
/* %parse-param {KB* kb}  */

%initial-action {
	conjuncts.reserve(1024);
	disjoint_classes.reserve(1024);
	equivalent_classes.reserve(1024);
	equivalent_objectproperties.reserve(1024);
	objectproperty_chain_components.reserve(1024);
}

%start ontologyDocument

%token PNAME_NS PNAME_LN IRI_REF BLANK_NODE_LABEL LANGTAG QUOTED_STRING
%token DOUBLE_CARET

/* Ontology */
%token PREFIX ONTOLOGY IMPORT
%token DECLARATION

/* Annotation */
%token ANNOTATION ANNOTATION_ASSERTION SUB_ANNOTATION_PROPERTY_OF
%token ANNOTATION_PROPERTY ANNOTATION_PROPERTY_DOMAIN ANNOTATION_PROPERTY_RANGE

%token CLASS 
%token OBJECT_INTERSECTION_OF OBJECT_ONE_OF OBJECT_SOME_VALUES_FROM OBJECT_HAS_VALUE OBJECT_HAS_SELF
%token OBJECT_PROPERTY OBJECT_PROPERTY_CHAIN OBJECT_PROPERTY_DOMAIN OBJECT_PROPERTY_RANGE
%token DATA_INTERSECTION_OF DATA_ONE_OF DATA_SOME_VALUES_FROM DATA_HAS_VALUE 
%token DATA_PROPERTY SUB_DATA_PROPERTY_OF EQUIVALENT_DATA_PROPERTIES DATA_PROPERTY_DOMAIN DATA_PROPERTY_RANGE FUNCTIONAL_DATA_PROPERTY 
%token DATA_PROPERTY_ASSERTION NEGATIVE_DATA_PROPERTY_ASSERTION
%token DATATYPE DATATYPE_DEFINITION 
%token HAS_KEY 
%token NAMED_INDIVIDUAL SAME_INDIVIDUAL DIFFERENT_INDIVIDUALS 
%token OBJECT_PROPERTY_ASSERTION CLASS_ASSERTION NEGATIVE_OBJECT_PROPERTY_ASSERTION 
%token SUB_CLASS_OF EQUIVALENT_CLASSES DISJOINT_CLASSES
%token SUB_OBJECT_PROPERTY_OF TRANSITIVE_OBJECT_PROPERTY EQUIVALENT_OBJECT_PROPERTIES REFLEXIVE_OBJECT_PROPERTY

%union {
	char* text;
	u_int32_t concept; // ID concept
	u_int32_t role; // ID role
}

%type <text> fullIRI prefixName subClassExpression superClassExpression Individual NamedIndividual Class ClassExpression sourceIndividual  
%type <text> ObjectHasSelf DataSomeValuesFrom ObjectHasValue ObjectIntersectionOf ObjectSomeValuesFrom ObjectOneOf targetIndividual DataHasValue
%type <text> ObjectPropertyExpression ObjectProperty superObjectPropertyExpression subObjectPropertyExpression propertyExpressionChain

%%

/*****************************************************************************/
/* General Definitions */

languageTag:
	LANGTAG;

nodeID:
	BLANK_NODE_LABEL;	

fullIRI: 
	IRI_REF { 
		$$ = strdup(yytext);
	};	
	
prefixName:
	PNAME_NS { 
		$$ = strdup(yytext);
	};
	
abbreviatedIRI:
	PNAME_LN;
	
IRI:
	fullIRI 
	| abbreviatedIRI;

/*****************************************************************************/
/* Ontology */
ontologyDocument:
	prefixDeclaration ontology;
	
prefixDeclaration:
	| prefixDeclaration PREFIX '(' prefixName '=' fullIRI ')' {
		// tx->createPrefix($4, $6); //TODO:
		/*
		// free the name, no need to keep it in the hash of prefixes
		// do not free the prefix itself, we need to store it in the hash
		free($4);
		*/
	};
	
ontology:
	ONTOLOGY '(' ontologyIRI versionIRI directlyImportsDocuments ontologyAnnotations axioms ')' 
	| ONTOLOGY '(' ontologyIRI directlyImportsDocuments ontologyAnnotations axioms ')' 
	| ONTOLOGY '(' directlyImportsDocuments ontologyAnnotations axioms ')';

ontologyIRI:
	IRI;

versionIRI:
	IRI;
	
directlyImportsDocuments:
	| directlyImportsDocuments IMPORT '(' IRI ')';
	
ontologyAnnotations:
	| ontologyAnnotations annotation;
	
axioms:
	| axioms Axiom;

Declaration: 
	DECLARATION '(' axiomAnnotations Entity ')'

Entity:
	CLASS '(' Class ')'
    | DATATYPE '(' Datatype ')'
    | OBJECT_PROPERTY '(' ObjectProperty ')'
    | DATA_PROPERTY '(' DataProperty ')'
    | ANNOTATION_PROPERTY '(' AnnotationProperty ')' 
    | NAMED_INDIVIDUAL '(' NamedIndividual ')';

/*****************************************************************************/
/* Annotation */

anonymousIndividual:
	nodeID;

annotationSubject:
	IRI 
	| anonymousIndividual;

annotationValue:
	anonymousIndividual 
	| IRI
	| Literal;
	
axiomAnnotations: 
	| axiomAnnotations annotation;
	
annotation:
	ANNOTATION '(' annotationAnnotations AnnotationProperty annotationValue ')';
	
annotationAnnotations:
	| annotationAnnotations annotation;

AnnotationAxiom:
	annotationAssertion
	| subAnnotationPropertyOf 
	| annotationPropertyDomain 
	| annotationPropertyRange;
	
annotationAssertion:
	ANNOTATION_ASSERTION '(' axiomAnnotations AnnotationProperty annotationSubject annotationValue ')';

subAnnotationPropertyOf:
	SUB_ANNOTATION_PROPERTY_OF '(' axiomAnnotations subAnnotationProperty superAnnotationProperty ')';
	
subAnnotationProperty:
	AnnotationProperty;
	
superAnnotationProperty:
	AnnotationProperty;

annotationPropertyDomain:
	ANNOTATION_PROPERTY_DOMAIN '(' axiomAnnotations AnnotationProperty IRI ')';

annotationPropertyRange:
	ANNOTATION_PROPERTY_RANGE '(' axiomAnnotations AnnotationProperty IRI ')'; 
	
/*****************************************************************************/
	

Class:
	IRI	{
        // $$ = tx->createAtomicConcept(yytext); //TODO:
		$$ = strdup(yytext);
        };

Datatype:
	IRI;

ObjectProperty:
	IRI	{
		// $$ = tx->createRole(yytext); //TODO:
        };

DataProperty:
	IRI { 
		unsupported_feature("DataProperty");
	};

AnnotationProperty: 
	IRI;

Individual:
	NamedIndividual;

NamedIndividual:
	IRI	{
		//NOTE: our tbox and our abox are mixed, every individual is considered as a class
        // $$ = tx->createAtomicConcept(yytext); //TODO:
		$$ = strdup(yytext);
        };

Literal:
	typedLiteral 
	| stringLiteralNoLanguage 
	| stringLiteralWithLanguage;
	
typedLiteral:
	lexicalForm DOUBLE_CARET Datatype;
	
lexicalForm:
	QUOTED_STRING;
	
stringLiteralNoLanguage:
	QUOTED_STRING;
	
stringLiteralWithLanguage:
	QUOTED_STRING languageTag;

	
ObjectPropertyExpression:
	ObjectProperty;

DataPropertyExpression:
	DataProperty;


DataRange:
	Datatype
	| DataIntersectionOf
	| DataOneOf;

	// TODO-FROM-ELEPHANT:
DataIntersectionOf:
	DATA_INTERSECTION_OF '(' DataRange DataRange dataRanges ')' {
		unsupported_feature("DataIntersectionOf");
	};

dataRanges:
	| DataRange dataRanges {
	};

	// TODO-FROM-ELEPHANT:
DataOneOf:
	DATA_ONE_OF '(' Literal ')' {
		unsupported_feature("DataOneOf");
	}


ClassExpression:
	Class 
	| ObjectIntersectionOf 
	| ObjectOneOf
	| ObjectSomeValuesFrom
	| ObjectHasValue
	| ObjectHasSelf
	| DataSomeValuesFrom
	| DataHasValue; 

conjuncts:
	| ClassExpression conjuncts {
		// if ($1.concept != NULL)
		conjuncts.emplace_back($1); 
	};


ObjectIntersectionOf:
	OBJECT_INTERSECTION_OF '(' ClassExpression ClassExpression conjuncts ')' {
		conjuncts.emplace_back($3);
		conjuncts.emplace_back($4);

		// $$ = tx->createIntersectionConcept(conjuncts); //TODO:
		conjuncts.clear();
	};


// OWL2 EL allows only one individual in an ObjectOneOf description
ObjectOneOf:
	OBJECT_ONE_OF '(' Individual ')' {
		// $$.concept = get_create_nominal($3.individual, kb->tbox);
        //FIXME: 
		// unsupported_feature("ObjectOneOf");
        // not_reimplemented_feature("ObjectOneOf"); //TODO:
	};

ObjectSomeValuesFrom:
	OBJECT_SOME_VALUES_FROM '(' ObjectPropertyExpression ClassExpression ')' {
		// $$ = tx->createExistRestrictionConcept($3,$4); //TODO:
	};

	// TODO-FROM-ELEPHANT:
ObjectHasValue:
	OBJECT_HAS_VALUE '(' ObjectPropertyExpression Individual ')' {
		unsupported_feature("ObjecHasValue");
	};

	// TODO-FROM-ELEPHANT:
ObjectHasSelf:
	OBJECT_HAS_SELF '(' ObjectPropertyExpression ')' {
		unsupported_feature("ObjecHasSelf");
	};

	// 4 shift/reduce conflicts due to the dataPropertyExpressions in the middle //TODO-FROM-ELEPHANT:
DataSomeValuesFrom:
	DATA_SOME_VALUES_FROM '(' DataPropertyExpression dataPropertyExpressions DataRange ')' {
		unsupported_feature("DataSomeValuesFrom");
	};

	// TODO-FROM-ELEPHANT:
dataPropertyExpressions:
	| DataPropertyExpression dataPropertyExpressions {
		unsupported_feature("dataPropertyExpressions");
	};

	// TODO-FROM-ELEPHANT:
DataHasValue:
	DATA_HAS_VALUE '(' DataPropertyExpression Literal ')' {
		unsupported_feature("DataHasValue");
		// for now just return the top concept
		// $$.concept = kb->tbox->top_concept;
        // CHECK: // REVIEW:
        // not_reimplemented_feature("DataHasValue");
		// $$ = 0; //NOTE: 0 is our top concept
		//TODO:
	};

Axiom:
	Declaration
	| ClassAxiom 
	| ObjectPropertyAxiom
	| DataPropertyAxiom
	| DatatypeDefinition
	| HasKey
	| Assertion
	| AnnotationAxiom;

ClassAxiom:
	SubClassOf 
	| EquivalentClasses
	| DisjointClasses;

SubClassOf:
	SUB_CLASS_OF '(' axiomAnnotations subClassExpression superClassExpression ')' {
		tx->addSubClassOf($4,$5);
	};

subClassExpression:
	ClassExpression;

superClassExpression:
	ClassExpression;

// TODO-FROM-ELEPHANT: move the creation of binary axioms to preprocessing
EquivalentClasses:
	EQUIVALENT_CLASSES '(' axiomAnnotations ClassExpression ClassExpression equivalentClassExpressions ')' {
		equivalent_classes.emplace_back($4);
		equivalent_classes.emplace_back($5);
		tx->addEquivalentClasses(equivalent_classes);
		equivalent_classes.clear();
	};

// for parsing EquivalentClasses axioms containing more than 2 class expressions
equivalentClassExpressions:
	| ClassExpression equivalentClassExpressions {
		equivalent_classes.emplace_back($1);
	};

DisjointClasses:
	DISJOINT_CLASSES '(' axiomAnnotations ClassExpression ClassExpression disjointClassExpressions ')' {
		disjoint_classes.emplace_back($4);
		disjoint_classes.emplace_back($5);
		// tx->addDisjunction(disjoint_classes); //TODO:
		disjoint_classes.clear();
	};


disjointClassExpressions:
	| ClassExpression disjointClassExpressions {
		disjoint_classes.emplace_back($1);
	};


ObjectPropertyAxiom:
	EquivalentObjectProperties 
	| SubObjectPropertyOf 
	| ObjectPropertyDomain 
	| ObjectPropertyRange 
	| ReflexiveObjectProperty 
	| TransitiveObjectProperty;

	
SubObjectPropertyOf:
	SUB_OBJECT_PROPERTY_OF '(' axiomAnnotations subObjectPropertyExpression superObjectPropertyExpression ')' {
		// tx->addRoleSubsumption($4,$5); //TODO:
	};

subObjectPropertyExpression:
	ObjectPropertyExpression 
	| propertyExpressionChain;

propertyExpressionChain:
	OBJECT_PROPERTY_CHAIN '(' ObjectPropertyExpression ObjectPropertyExpression chainObjectPropertyExpressions ')' {
		objectproperty_chain_components.emplace_back($4);
		objectproperty_chain_components.emplace_back($3);
		// $$ = tx->createCompositionRole(objectproperty_chain_components); //TODO:
		objectproperty_chain_components.clear();
	}

chainObjectPropertyExpressions:
	| ObjectPropertyExpression chainObjectPropertyExpressions {
		objectproperty_chain_components.emplace_back($1);
	};

superObjectPropertyExpression:
	ObjectPropertyExpression;

// TODO-FROM-ELEPHANT: move the creation of binary axioms to preprocessing
EquivalentObjectProperties:
	EQUIVALENT_OBJECT_PROPERTIES '(' axiomAnnotations ObjectPropertyExpression ObjectPropertyExpression equivalentObjectPropertyExpressions ')' {
		equivalent_objectproperties.emplace_back($4);
		equivalent_objectproperties.emplace_back($5);
		// tx->addRoleEquivalence(equivalent_objectproperties) //TODO:;
		equivalent_objectproperties.clear();
	};
	
equivalentObjectPropertyExpressions:
	| ObjectPropertyExpression equivalentObjectPropertyExpressions {
		equivalent_objectproperties.emplace_back($1);
	};

ObjectPropertyDomain:
	OBJECT_PROPERTY_DOMAIN '(' axiomAnnotations ObjectPropertyExpression ClassExpression ')' {
		// tx->addDomainRestriction($4,$5); //TODO:
	};

ObjectPropertyRange:
	OBJECT_PROPERTY_RANGE '(' axiomAnnotations ObjectPropertyExpression ClassExpression ')' {
		unsupported_feature("ObjectPropertyRange");
	};

ReflexiveObjectProperty:
	REFLEXIVE_OBJECT_PROPERTY '(' axiomAnnotations ObjectPropertyExpression ')' {
		unsupported_feature("ReflexiveObjectProperty");
	};

TransitiveObjectProperty:
	TRANSITIVE_OBJECT_PROPERTY '(' axiomAnnotations ObjectPropertyExpression ')' {
		// ADD_TRANSITIVE_OBJECTPROPERTY_AXIOM(create_transitive_role_axiom($4.role), kb->tbox);
        //REVIEW: //NOTE: FOR THE MOMENT EVERY OBJECT PROPERTY IS TRANSITIVE APPARENTLY
        // not_reimplemented_feature("TransitiveObjectProperty");
	};

DataPropertyAxiom:
    SubDataPropertyOf 
    | EquivalentDataProperties 
    | DataPropertyDomain 
    | DataPropertyRange 
    | FunctionalDataProperty;
    
SubDataPropertyOf:
	SUB_DATA_PROPERTY_OF '(' axiomAnnotations subDataPropertyExpression superDataPropertyExpression ')' {
		unsupported_feature("SubDataPropertyOf");
	};

subDataPropertyExpression:
	DataPropertyExpression;

superDataPropertyExpression:
	DataPropertyExpression;
	
EquivalentDataProperties:
	EQUIVALENT_DATA_PROPERTIES '(' axiomAnnotations DataPropertyExpression DataPropertyExpression dataPropertyExpressions ')' {
		unsupported_feature("EquivalentDataProperties");
	};
	
DataPropertyDomain:
	DATA_PROPERTY_DOMAIN '(' axiomAnnotations DataPropertyExpression ClassExpression ')' {
		unsupported_feature("DataPropertyDomain");
	};

DataPropertyRange:
	DATA_PROPERTY_RANGE '(' axiomAnnotations DataPropertyExpression DataRange ')' {
		unsupported_feature("DataPropertyRange");
	};

FunctionalDataProperty:
	FUNCTIONAL_DATA_PROPERTY '(' axiomAnnotations DataPropertyExpression ')' {
		unsupported_feature("FunctionalDataProperty");
	};

DatatypeDefinition:
	DATATYPE_DEFINITION '(' axiomAnnotations Datatype DataRange ')' {
		unsupported_feature("DatatypeDefinition");
	};

HasKey:
	HAS_KEY '(' axiomAnnotations ClassExpression '(' hasKeyObjectPropertyExpressions ')' '(' dataPropertyExpressions ')' ')' {
		unsupported_feature("HasKey");
	};

hasKeyObjectPropertyExpressions:
	| ObjectPropertyExpression hasKeyObjectPropertyExpressions {
		// if ($1.role != NULL)
		// 	haskey_objectproperties[haskey_objectproperty_expression_count++] = $1.role;
        //TODO-FROM-ELEPHANT:
		// not_reimplemented_feature("hasKeyObjectPropertyExpressions");
	};

Assertion:
	SameIndividual 
	| DifferentIndividuals 
	| ClassAssertion 
	| ObjectPropertyAssertion 
	| NegativeObjectPropertyAssertion 
	| DataPropertyAssertion 
	| NegativeDataPropertyAssertion;
	
sourceIndividual: 
	Individual;

targetIndividual:
	Individual;
	
targetValue:
	Literal;
	
SameIndividual:
	SAME_INDIVIDUAL '(' axiomAnnotations Individual Individual sameIndividuals ')' {
		//NOTE: our tbox and our abox are mixed, every individual is considered as a class
		equivalent_classes.emplace_back($4);
		equivalent_classes.emplace_back($5);
		tx->addEquivalentClasses(equivalent_classes);
		equivalent_classes.clear();
	};
	
sameIndividuals:
	| Individual sameIndividuals {
		//NOTE: our tbox and our abox are mixed, every individual is considered as a class
		equivalent_classes.emplace_back($1); 
	};

DifferentIndividuals:
	DIFFERENT_INDIVIDUALS '(' axiomAnnotations Individual Individual differentIndividuals  ')' {
		//NOTE: our tbox and our abox are mixed, every individual is considered as a class
		disjoint_classes.emplace_back($4);
		disjoint_classes.emplace_back($5);
		// tx->addDisjunction(disjoint_classes); //TODO:
		disjoint_classes.clear();
	};

differentIndividuals:
	| Individual differentIndividuals {
		//NOTE: our tbox and our abox are mixed, every individual is considered as a class
		disjoint_classes.emplace_back($1); 
	};

ClassAssertion:
	CLASS_ASSERTION '(' axiomAnnotations ClassExpression Individual ')' {
		// add_concept_assertion(create_concept_assertion($5.individual, $4.concept), kb->abox);
        //FIXME: //REVIEW:
        // not_reimplemented_feature("ClassAssertion");
	};

ObjectPropertyAssertion:
	OBJECT_PROPERTY_ASSERTION '(' axiomAnnotations ObjectPropertyExpression sourceIndividual targetIndividual ')' {
		// add_role_assertion(create_role_assertion($4.role, $5.individual, $6.individual), kb->abox);
        //FIXME: //REVIEW:
        not_reimplemented_feature("ObjectPropertyAssertion");
	};

NegativeObjectPropertyAssertion:
	NEGATIVE_OBJECT_PROPERTY_ASSERTION '(' axiomAnnotations ObjectPropertyExpression sourceIndividual targetIndividual ')' {
		unsupported_feature("NegativeObjectPropertyAssertion");
	};

DataPropertyAssertion:
	DATA_PROPERTY_ASSERTION '(' axiomAnnotations DataPropertyExpression sourceIndividual targetValue ')' {
		unsupported_feature("DataPropertyAssertion");
	};
	
NegativeDataPropertyAssertion:
	NEGATIVE_DATA_PROPERTY_ASSERTION '(' axiomAnnotations DataPropertyExpression sourceIndividual targetValue ')' {
		unsupported_feature("NegativeDataPropertyAssertion");
	};

%%

/* void yyerror(KB* kb, char* msg) {
	fprintf(stderr, "\nline %d near %s: %s\n", yylineno, yytext, msg);
} */
void yyerror(Taxonomy* tx, std::string msg) {
	fprintf(stderr, "\nline %d near %s: %s\n", yylineno, yytext, msg.c_str());
}

void unsupported_feature(std::string feature) {
	fprintf(stderr, "unsupported feature: %s\n", feature.c_str());
}

void not_reimplemented_feature(std::string feature) {
	fprintf(stderr, "not reimplemented feature: %s (line %d, near '%s')\n", feature.c_str(), yylineno, yytext);
}