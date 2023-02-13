# mcfunction-assembler

Builds function directories for Minecraft data packs



## Motivation

Minecraft function files are great, but they have one severe limitation: one function declaration per file. Since the only way to do code blocks is with a function call, even small tasks often need several files. And because all function calls use raw file paths, reorganizing your functions means having to rename all the references!

This little tool handles all the menial work automatically, letting you organize function declarations across exactly as many files as you want. You give your functions simple names, and they get replaced with the correct references automatically.



## Usage

You write your source code in a text file with the `.mcfunction` extension, as you normally would, except that function calls use custom names instead of the usual file paths Minecraft would expect.

The syntax is almost identical to existing mcfunction syntax, so all syntax highlighting schemes will still work. Additionally, you can use the keywords `ex` and `fn` as aliases for `execute` and `function`.

Instructions to the assembler are lines that begin with `##`. These are treated as comments by mcfunction syntax (as are all lines that begin with `#`). The instruction to be performed depends on the immediately following character. `##` followed by any other character not listed here is treated as a comment.

* `##: <namespace>` = set the namespace for all following function declarations to `<namespace>` (mnemonic: `:` separates namespace from function name, as in `minecraft:foo`)
* `##/ <path>` = set the parent directory for all following function declarations to `<path>` (mnemonic: `/` separates directories, as in `minecraft:foo/bar`)
* `##+ <path>` = include a file at `<path>`.
* `##{ <name> <path>` = start block of code for a function which will be referred to as `<name>` and should be output at `<path>`.
* `##}` = end current block of code.

The output is a nested directory of function files with the following properties:

* All comments are removed.
* All lines of code outside a code block are removed.
* All lines of code inside code blocks are written to a file at the specified path.
* All function names in function calls inside code blocks are replaced with their correct references.

