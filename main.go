package main

import (
	"fmt"
	"hash/fnv"
	"log"
	"os"
	"sort"
	"time"

	"github.com/google/go-jsonnet"
	"github.com/google/go-jsonnet/ast"
	"github.com/nr8-io/jsonnet-bundler/pkg/parser"
)

// Generate a hash-based prefix from the filename
func hash(filename string) string {
	h := fnv.New32a() // FNV-1a 32-bit
	h.Write([]byte(filename))
	// add underscore to ensure valid identifier
	return fmt.Sprintf("_%08x", h.Sum32())
}

// Build a line offset index for efficient lookups
func buildLineOffsets(source []byte) []int {
	offsets := []int{0}
	for i, b := range source {
		if b == '\n' {
			offsets = append(offsets, i+1)
		}
	}
	return offsets
}

// Convert line and column to byte offset
func lineColToOffset(lineOffsets []int, line, col int) int {
	if line < 0 || line >= len(lineOffsets) {
		return 0
	}
	return lineOffsets[line] + col
}

// Replacement represents a text replacement in the source code
type Replacement struct {
	beginOffset int
	endOffset   int
	newValue    string
}

type Context struct {
	// prefix to be added to local binds and their usages
	prefix string
	// replacements to to be applied in the source
	replacements []Replacement
	// the original source code
	source []byte
	// line offsets for the source code
	lineOffsets []int
	// set of local binds collected to be replaced
	localBinds map[string]struct{}
}

func collectLocalBindReplacement(ctx *Context, node ast.LocalBind, oldName string, newName string) (*Replacement, error) {
	if loc := node.LocRange; loc.IsSet() {
		beginLine, beginCol := loc.Begin.Line-1, loc.Begin.Column-1
		endLine, _ := loc.End.Line-1, loc.End.Column-1

		// Calculate end column based on oldName length, since LocRange's End may not point exactly after the variable name
		endCol := loc.Begin.Column + len(oldName) - 1

		beginOffset := lineColToOffset(ctx.lineOffsets, beginLine, beginCol)
		endOffset := lineColToOffset(ctx.lineOffsets, endLine, endCol)

		span := string(ctx.source[beginOffset:endOffset])

		// Verify that the extracted span matches the oldName
		if span == oldName {
			return &Replacement{beginOffset, endOffset, newName}, nil
		}
	}

	return nil, fmt.Errorf("no match at loc")
}

func collectVarReplacement(ctx *Context, node ast.Node, oldName string, newName string) (*Replacement, error) {
	if loc := node.Loc(); loc.IsSet() {
		beginLine, beginCol := loc.Begin.Line-1, loc.Begin.Column-1
		endLine, endCol := loc.End.Line-1, loc.End.Column-1

		beginOffset := lineColToOffset(ctx.lineOffsets, beginLine, beginCol)
		endOffset := lineColToOffset(ctx.lineOffsets, endLine, endCol)

		span := string(ctx.source[beginOffset:endOffset])
		if span == oldName {
			return &Replacement{beginOffset, endOffset, newName}, nil
		}
	}

	return nil, fmt.Errorf("no match at loc")
}

func collectLocalBindReplacements(ctx *Context, node ast.Node) {
	switch n := node.(type) {
	case *ast.Local:
		for _, b := range n.Binds {
			rep, err := collectLocalBindReplacement(ctx, b, string(b.Variable), ctx.prefix+"_"+string(b.Variable))
			if err == nil {
				ctx.replacements = append(ctx.replacements, *rep)
				ctx.localBinds[string(b.Variable)] = struct{}{}
			}
		}
	}

	for _, child := range parser.Children(node) {
		collectLocalBindReplacements(ctx, child)
	}
}

func collectVarReplacements(ctx *Context, node ast.Node) {
	switch n := node.(type) {
	case *ast.Var:
		if _, ok := ctx.localBinds[string(n.Id)]; ok {
			rep, err := collectVarReplacement(ctx, n, string(n.Id), ctx.prefix+"_"+string(n.Id))
			if err == nil {
				ctx.replacements = append(ctx.replacements, *rep)
			}
		}
	}

	for _, child := range parser.Children(node) {
		collectVarReplacements(ctx, child)
	}
}

func applyReplacements(ctx *Context) []byte {
	reps := ctx.replacements

	// Sort replacements by beginOffset descending to handle overlapping replacements correctly
	sort.Slice(reps, func(i, j int) bool {
		return reps[i].beginOffset > reps[j].beginOffset
	})

	// Loop through replacements and apply them to the source
	out := ctx.source
	for _, rep := range reps {
		out = append(out[:rep.beginOffset], append([]byte(rep.newValue), out[rep.endOffset:]...)...)
	}

	return out
}

func main() {
	source := "input/konn/main.libsonnet"
	code, err := os.ReadFile(source)
	if err != nil {
		log.Fatal(err)
	}

	// Initialize context for processing
	ctx := &Context{
		// prefix as hash of the current file name
		prefix:      hash(source),
		source:      code,
		lineOffsets: buildLineOffsets(code),
		localBinds:  make(map[string]struct{}),
	}

	// Create Jsonnet VM and parse the input file as AST for accurate location info
	vm := jsonnet.MakeVM()

	node, _, err := vm.ImportAST("", "input/konn/main.libsonnet")
	if err != nil {
		log.Fatal(err)
	}

	// First pass to collect and replace local binds
	collectLocalBindReplacements(ctx, node)
	// Second pass to collect and replace variable usages
	collectVarReplacements(ctx, node)

	// Apply all collected replacements to the source code
	newSource := applyReplacements(ctx)

	// add comment to the top of the file indicating it is auto-generated
	newSource = append([]byte("// Auto-generated by jsonnet-bundler at "+time.Now().Format(time.RFC3339)+" for "+source+"\n"), newSource...)

	// make sure output directory exists
	err = os.MkdirAll("output", os.ModePerm)
	if err != nil {
		log.Fatal(err)
	}

	// Write the modified source to output file
	err = os.WriteFile("output/main.libsonnet", newSource, 0644)
	if err != nil {
		log.Fatal(err)
	}
}
