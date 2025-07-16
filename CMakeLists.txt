cmake_minimum_required(VERSION 3.10)
project(taxonoviz)
set(CMAKE_CXX_STANDARD 17)


# add_compile_options(-fsanitize=address)
# add_link_options(-fsanitize=address)

# Find Flex and Bison
find_program(LEX_EXE flex)
if(NOT LEX_EXE)
  message(FATAL_ERROR "dear user, please install flex!")
endif()

find_program(YACC_EXE bison)
if(NOT YACC_EXE)
  message(FATAL_ERROR "dear user, please install bison!")
endif()

# Output directory for generated sources and headers
set(GENERATED_DIR ${CMAKE_CURRENT_BINARY_DIR})

# Macro for Bison/Yacc
macro(YACC_FILE _filename)
  get_filename_component(_basename ${_filename} NAME_WE)
  add_custom_command(
    OUTPUT ${GENERATED_DIR}/${_basename}.cc
           ${GENERATED_DIR}/${_basename}.hh
    COMMAND ${YACC_EXE}
            -d ${CMAKE_CURRENT_SOURCE_DIR}/${_filename}
            -o ${GENERATED_DIR}/${_basename}.cc
            --defines=${GENERATED_DIR}/${_basename}.hh
    DEPENDS ${_filename}
    WORKING_DIRECTORY ${GENERATED_DIR}
    COMMENT "Running Bison on ${_filename}..."
  )
endmacro()

# Macro for Flex/Lex
macro(LEX_FILE _filename)
  get_filename_component(_basename ${_filename} NAME_WE)
  add_custom_command(
    OUTPUT ${GENERATED_DIR}/${_basename}.cc
    COMMAND ${LEX_EXE}
            -o ${GENERATED_DIR}/${_basename}.cc
            ${CMAKE_CURRENT_SOURCE_DIR}/${_filename}
    DEPENDS ${_filename}
    WORKING_DIRECTORY ${GENERATED_DIR}
    COMMENT "Running Flex on ${_filename}..."
  )
endmacro()

# Generate parser and lexer sources
YACC_FILE(src/parser/syntaxic.y)
LEX_FILE(src/parser/lexical.l)

# Include directories for generated headers and parser utilities
include_directories(
  ${GENERATED_DIR}
  ${CMAKE_CURRENT_SOURCE_DIR}/src/
)

# Source files
set(SOURCES
    src/main.cc
    ${GENERATED_DIR}/lexical.cc
    ${GENERATED_DIR}/syntaxic.cc
    src/taxonomy.cc
)

# Define executable
add_executable(taxonoviz ${SOURCES})
set_property(TARGET taxonoviz PROPERTY CXX_STANDARD 17)
target_compile_features(taxonoviz PRIVATE cxx_std_17)
