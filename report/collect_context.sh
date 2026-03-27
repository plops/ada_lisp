#!/usr/bin/env bash

set -euo pipefail

REPORT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$REPORT_DIR/.." && pwd)"
OUTPUT_FILE="${OUTPUT_FILE:-$REPORT_DIR/ada_lisp_context.txt}"

declare -a ORDERED_FILES=()
declare -A SEEN_FILES=()

queue_file() {
    local relative_path="$1"
    local description="$2"
    local absolute_path="$PROJECT_DIR/$relative_path"

    if [[ ! -f "$absolute_path" ]]; then
        echo "warning: missing file skipped: $relative_path" >&2
        return
    fi

    if [[ -n "${SEEN_FILES[$relative_path]:-}" ]]; then
        return
    fi

    SEEN_FILES["$relative_path"]=1
    ORDERED_FILES+=("$relative_path|$description")
}

append_separator() {
    {
        echo "================================================================="
        echo "$1"
        echo "================================================================="
    } >> "$OUTPUT_FILE"
}

append_file() {
    local relative_path="$1"
    local description="$2"
    local absolute_path="$PROJECT_DIR/$relative_path"

    {
        echo
        append_separator "FILE: $relative_path"
        echo "DESCRIPTION: $description"
        echo
        cat "$absolute_path"
        echo
    } >> "$OUTPUT_FILE"
}

queue_remaining_files() {
    local absolute_path
    local relative_path

    while IFS= read -r absolute_path; do
        relative_path="${absolute_path#$PROJECT_DIR/}"
        queue_file "$relative_path" "Additional project file not explicitly prioritized"
    done < <(
        find \
            "$PROJECT_DIR/src" \
            "$PROJECT_DIR/proofs" \
            "$PROJECT_DIR/app" \
            "$PROJECT_DIR/tests" \
            "$PROJECT_DIR/docs" \
            "$PROJECT_DIR/doc" \
            "$PROJECT_DIR/scripts" \
            -maxdepth 1 -type f | sort
    )
}

queue_file "AGENTS.md" "Repository workflow and proof guidance"
queue_file "README.md" "Project overview"
queue_file "lisp_prove.gpr" "Proof project file"
queue_file "lisp.gpr" "Build and test project file"
queue_file "spark.adc" "SPARK mode configuration"

queue_file "docs/proof-status.md" "Current SPARK verification status and focused proof notes"
queue_file "docs/invariants.md" "Core invariants referenced by multiple proof units"
queue_file "docs/semantics.md" "Frozen language semantics"
queue_file "doc/02_proof_hints.md" "Proof tactics and known prover friction points"
queue_file "doc/03_about_excessive_proof_runtimes.md" "Proof runtime notes"
queue_file "doc/01_implementation_plan.md" "Implementation and verification plan"

queue_file "scripts/prove-adacore.sh" "Preferred repo-local proof entry point"
queue_file "scripts/prove.sh" "System-toolchain proof entry point"
queue_file "scripts/with-adacore.sh" "Toolchain wrapper used by build, test, and proof runs"
queue_file "scripts/build.sh" "Build script"
queue_file "scripts/test.sh" "Regression test script"
queue_file "scripts/install-adacore-community.sh" "Toolchain installation helper"

queue_file "src/lisp-config.ads" "Shared capacity and configuration constants"
queue_file "src/lisp-types.ads" "Fundamental scalar and bounded types"
queue_file "src/lisp.ads" "Root package marker"

queue_file "src/lisp-text_buffers.ads" "Bounded text buffer specification"
queue_file "src/lisp-text_buffers.adb" "Bounded text buffer implementation"
queue_file "src/lisp-symbols.ads" "Intern table contracts and helper predicates"
queue_file "src/lisp-symbols.adb" "Intern table implementation"
queue_file "src/lisp-store.ads" "Heap cell model and arena contracts"
queue_file "src/lisp-store.adb" "Heap cell model and arena implementation"
queue_file "src/lisp-env.ads" "Environment and frame validity contracts"
queue_file "src/lisp-env.adb" "Environment and frame implementation"
queue_file "src/lisp-runtime.ads" "Combined runtime state and reserved-name facts"
queue_file "src/lisp-runtime.adb" "Combined runtime initialization and helper lemmas"

queue_file "src/lisp-lexer.ads" "Lexer interface"
queue_file "src/lisp-lexer.adb" "Lexer implementation"
queue_file "src/lisp-parser.ads" "Parser contracts preserving runtime validity"
queue_file "src/lisp-parser.adb" "Parser implementation"
queue_file "src/lisp-arith.ads" "Arithmetic helper contracts"
queue_file "src/lisp-arith.adb" "Arithmetic helper implementation"
queue_file "src/lisp-primitives.ads" "Primitive evaluator contracts"
queue_file "src/lisp-primitives.adb" "Primitive evaluator implementation"
queue_file "src/lisp-eval.ads" "Evaluator contracts and proof helpers"
queue_file "src/lisp-eval.adb" "Evaluator implementation"
queue_file "src/lisp-printer.ads" "Printer interface and contracts"
queue_file "src/lisp-printer.adb" "Printer implementation"
queue_file "src/lisp-driver.ads" "Top-level run interface"
queue_file "src/lisp-driver.adb" "Top-level run pipeline"

queue_file "proofs/proof.ads" "Proof namespace root"
queue_file "proofs/lisp-model.ads" "Ghost model contracts"
queue_file "proofs/lisp-model.adb" "Ghost model implementation"
queue_file "proofs/proof-refinement.adb" "Executable versus model refinement scaffold"

queue_file "app/lisp-main.adb" "Non-SPARK executable wrapper"

queue_file "tests/test.ads" "Shared test utilities"
queue_file "tests/test-symbols.adb" "Symbol-table regression tests"
queue_file "tests/test-store.adb" "Store regression tests"
queue_file "tests/test-env.adb" "Environment regression tests"
queue_file "tests/test-lexer.adb" "Lexer regression tests"
queue_file "tests/test-parser.adb" "Parser regression tests"
queue_file "tests/test-primitives.adb" "Primitive regression tests"
queue_file "tests/test-eval_core.adb" "Core evaluator regression tests"
queue_file "tests/test-eval_define.adb" "Top-level define regression tests"
queue_file "tests/test-eval_closure.adb" "Closure evaluation regression tests"
queue_file "tests/test-printer.adb" "Printer regression tests"
queue_file "tests/test-end_to_end.adb" "End-to-end regression tests"

queue_remaining_files

mkdir -p "$(dirname "$OUTPUT_FILE")"
: > "$OUTPUT_FILE"

append_separator "ADA_LISP SPARK VERIFICATION CONTEXT"
{
    echo "Project directory: $PROJECT_DIR"
    echo "Output file: $OUTPUT_FILE"
    echo "Generated at: $(date -Iseconds)"
    echo
    echo "Ordering notes:"
    echo "1. Proof guidance, semantics, and entry-point scripts come first."
    echo "2. Source units are grouped so related specs and bodies stay adjacent."
    echo "3. Core runtime dependencies appear before parser, evaluator, and refinement units."
    echo "4. Tests come last as supporting evidence."
    echo
    echo "Priority manifest:"
} >> "$OUTPUT_FILE"

for index in "${!ORDERED_FILES[@]}"; do
    IFS="|" read -r relative_path description <<< "${ORDERED_FILES[$index]}"
    printf "%2d. %s :: %s\n" "$((index + 1))" "$relative_path" "$description" >> "$OUTPUT_FILE"
done

for item in "${ORDERED_FILES[@]}"; do
    IFS="|" read -r relative_path description <<< "$item"
    append_file "$relative_path" "$description"
done

append_separator "CONTEXT COLLECTION SUMMARY"
{
    echo "Total files included: ${#ORDERED_FILES[@]}"
    echo "Total lines: $(wc -l < "$OUTPUT_FILE")"
    echo "Output file size: $(du -h "$OUTPUT_FILE" | cut -f1)"
} >> "$OUTPUT_FILE"

echo "Context collection completed."
echo "File saved to: $OUTPUT_FILE"
echo "Total files included: ${#ORDERED_FILES[@]}"
echo "File size: $(du -h "$OUTPUT_FILE" | cut -f1)"
echo "Total lines: $(wc -l < "$OUTPUT_FILE")"
