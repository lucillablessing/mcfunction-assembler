# mcfunction-assembler

Builds function directories for Minecraft data packs



## Motivation

Minecraft function files are great, but they have one severe limitation: one function declaration per file. Since the only way to do code blocks is with a function call, even small tasks often need several files. And because all function calls use raw file paths, reorganizing your functions means having to rename all the references!

This little tool handles all the menial work automatically, letting you organize function declarations across exactly as many files as you want. You give your functions simple names, and they get replaced with the correct references automatically.



## Syntax

You write your source code in a text file with the `.mcfunction` extension, as you normally would, except that function calls use custom names instead of the usual file paths Minecraft would expect. Names should be valid Minecraft identifiers, i.e. `snake_case`.

The syntax is almost identical to existing mcfunction syntax, so all syntax highlighting schemes will still work. Additionally, you can use the keywords `ex` and `fn` as aliases for `execute` and `function`.

Instructions to the assembler are lines that begin with `##`. These are treated as comments by mcfunction syntax (as are all lines that begin with `#`). The instruction to be performed depends on the immediately following character. `##` followed by any other character not listed here is treated as a comment.

* `##: <namespace>` = set the namespace for all following function declarations to `<namespace>` (mnemonic: `:` separates namespace from function name, as in `minecraft:foo`)
* `##/ <path>` = set the parent directory for all following function declarations to `<path>` (mnemonic: `/` separates directories, as in `minecraft:foo/bar`)
* `##+ <path>` = include a file at `<path>` (without the `.mcfunction` extension). The effect is identical to inserting all the lines of the external file at this position in the current file.
* `##{ <name> <path>` = start block of code for a function which will be referred to as `<name>` and should be output at `<path>`.
* `##}` = end current block of code.

The output is a nested directory of function files with the following properties:

* All comments and blank lines are removed.
* All lines of code outside a code block are removed.
* All lines of code inside code blocks are written to a file at the specified path.
* All function names in function calls inside code blocks are replaced with their correct references.



## Usage

Place the application in the same directory as the source code file you wish to assemble. Drag and drop the file onto the application. It will create a directory named after the file, located in the same directory, containing all the function files in their correct subdirectories.



## Example

### Input

Suppose you have the following directory:
```
├one.mcfunction
├two.mcfunction
└sub
 └three.mcfunction
```

The contents of the files are:

* `one`:
```
##: yin

##{ first first_function
# This line is a comment
say first
give @a minecraft:diamond 64
##}

# So is this one

##+ two
##+ sub/three

##{ last very/long_file/path
say last
##}

fn first
# This line and the line above are ignored
```

* `two`:
```
##: yang
##/ inside

##{ ref reference_test
ex if entity @a run fn first
##}

##/ inside/more

##{ second second_function
fn first
##}
```

* `three`:
```
##{ third third_function
fn second
##}

##/ weird
```

### Output

Running the application on `one.mcfunction` produces a directory called `one` which looks like this:
```
└data
 ├yang
 │└functions
 │ ├inside
 │ │├reference_test.mcfunction
 │ │└more
 │ │ ├second_function.mcfunction
 │ │ └third_function.mcfunction
 │ └weird
 │  └very
 │   └long_file
 │    └path.mcfunction
 └yin
  └functions
   └first_function.mcfunction
```

The contents of the files are:

* `first_function`:
```
say first
give @a minecraft:diamond 64
```

* `second_function`:
```
function yin:first_function
```

* `third_function`:
```
function yang:inside/more/second_function
```

* `reference_test`:
```
execute if entity @a run function yin:first_function
```

* `path`:
```
say last
```
