package main

import (
	"fmt"
	"os"
	"strings"

	"github.com/google/go-jsonnet"
	"github.com/google/go-jsonnet/ast"
	"github.com/nr8-io/jsonnet-bundler/pkg/parser"
)

func lineColToOffset(source []byte, line, col int) int {
	lines := strings.Split(string(source), "\n")
	offset := 0
	for i := range line {
		offset += len(lines[i]) + 1 // +1 for \n
	}
	return offset + col
}

func replaceLocalBindInSource(node ast.LocalBind, oldName string, newName string, source []byte) ([]byte, error) {
	if loc := node.LocRange; loc.IsSet() {
		beginLine, beginCol := loc.Begin.Line-1, loc.Begin.Column-1 // 0-index
		endLine, endCol := loc.End.Line-1, loc.Begin.Column+len(oldName)-1

		// Convert to byte offsets
		beginOffset := lineColToOffset(source, beginLine, beginCol)
		endOffset := lineColToOffset(source, endLine, endCol)

		// Verify it matches oldName
		span := string(source[beginOffset:endOffset])

		fmt.Println(span, oldName, beginOffset, endOffset, span == oldName)

		if span == oldName {
			// Replace
			return append(source[:beginOffset], append([]byte(newName), source[endOffset:]...)...), nil
		}
	}

	return source, fmt.Errorf("no match at loc")
}

func replaceVarInSource(node ast.Node, oldName string, newName string, source []byte) ([]byte, error) {
	if loc := node.Loc(); loc.IsSet() {
		beginLine, beginCol := loc.Begin.Line-1, loc.Begin.Column-1 // 0-index
		endLine, endCol := loc.End.Line-1, loc.End.Column-1

		// Convert to byte offsets
		beginOffset := lineColToOffset(source, beginLine, beginCol)
		endOffset := lineColToOffset(source, endLine, endCol)

		// Verify it matches oldName
		span := string(source[beginOffset:endOffset])

		fmt.Println(span, oldName, beginOffset, endOffset, span == oldName)

		if span == oldName {
			// Replace
			return append(source[:beginOffset], append([]byte(newName), source[endOffset:]...)...), nil
		}
	}

	return source, fmt.Errorf("no match at loc")
}

func walkAndPrintVars(node ast.Node, prefix string, code []byte) []byte {
	fmt.Printf("TYPE: %T (begin: %v, end: %v)\n", node, node.Loc().Begin, node.Loc().End)

	switch n := node.(type) {
	case *ast.Var:
		fmt.Printf("%s#Var: %s\n", prefix, n.Id)

		code, _ = replaceVarInSource(n, string(n.Id), "prefix_"+string(n.Id), code)
	case *ast.Local:

		for _, b := range n.Binds {
			fmt.Printf("%s#Local Bind: %s\n", prefix, b.Variable)
			code, _ = replaceLocalBindInSource(b, string(b.Variable), "prefix_"+string(b.Variable), code)
		}

		for _, child := range parser.Children(node) {
			code = walkAndPrintVars(child, prefix+"  ", code)
		}
	default:
		for _, child := range parser.Children(node) {
			code = walkAndPrintVars(child, prefix+"  ", code)
		}
	}

	return code
}

func main() {
	code, _ := os.ReadFile("input/konn/main.libsonnet")

	vm := jsonnet.MakeVM()

	node, _, err := vm.ImportAST("", "input/konn/main.libsonnet")

	if err != nil {
		panic(err)
	}

	newSource := walkAndPrintVars(node, "", code)

	os.WriteFile("output.libsonnet", newSource, 0644)
}
