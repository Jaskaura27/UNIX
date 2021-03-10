
## Part 2: `commdir.*`

`commdir.{while,for}` is like `comm`, but for directories -- though its output is more like `diff`.

| Script           | Compares names in directories using... |
| ---:             | :--- |
| `commdir.while`  | ... a `while` loop. The `while` loop is powered by `read`ing filenames piped into it from `getAllFileNames`. Set `IFS` appropriately.
| `commdir.for`    | ... a `for` loop. The `for` loop is powered by examining a list of filenames provided by `getAllFileNames`.  Set `IFS` appropriately.
| `commdir.shared` | Provides two utility functions (`getAllFileNames` and `classifyFile`) used by the other two scripts. `commdir.shared` itself is never executed, but its contents are loaded into the other two scripts (as a [library](https://en.wikipedia.org/wiki/Library_(computing)#Shared_libraries)) via the `.` command.

### `commdir.shared`

#### `commdir.shared: getAllFileNames()`

* Name: `getAllFileNames` - displays the names of all of the files in the provided directories
* Synopsis: `getAllFileNames [dir]...`
* Parameters:
  * `"$@"` a list of directories
* Output:
  * the [set union](https://en.wikipedia.org/wiki/Union_(set_theory)) of all the file's names in the provided directories
  * one filename per line
  * names only, no directory component.  Eg: `foo`, NOT `./a/foo`
  * each name appears exactly once (no duplicates)
  * each name corresponds to a file's name in one or more of the provided directories
* Preconditions:
  * all provided parameters MUST be readable directories
  * the provided directories MUST NOT contain a file with a \n in its name
* Note:
  * MUST NOT descend into subdirectories looking for names -- top-level only
  * although directories' names are not output, a file's name in one directory may match a non-file's name in another directory. The name shall be included in the output since it corresponds to a file's name in one of the directories.
  Eg: if `foo` is a file's name in one directory, it will be included in the output regardless of if there is a directory named `foo` in any of the other directories.
* Hints:
  * be able to handle any `$#`
  * easiest to do as a *single* for loop
  * for each arg: in a `(subshell)`, `cd` to the target directory, then print its filenames
    * makes removing the directory component of file's path much easier)
  * DON'T use `ls` -- it's not suitable as part of a pipeline
    * its exact output format can vary depending on platform and settings. Eg: how it handles special characters in filenames
    * `man find`, `-maxdepth`, `-type`
  * only output *files'* names
  * DON'T try to use `comm` or `diff`
    * a *set union* is everything, with no duplicates
  * sort the output, then remove duplicates
  * approximate function length: 7 to 10 lines

#### `commdir.shared: classifyFile()`

* Name: `classifyFile` - determines & displays the comm/diff value of a *single* file name w/r/t two provided directories
* Synopsis: `classifyFile dir1 dir2 filename`
* Parameters:
  * `$1` directory 1
  * `$2` directory 2
  * `$3` the name being evaluated
* Output:
  * `- ${name}\n` if the name is in directory1 but not in directory2
  * `+ ${name}\n` if the name is in directory2 but not in directory1
  * `x ${name}\n` if the name is in both directories, but one of them is not a file
  * `= ${name}\n` if the file name is in both directories, and the files' contents are the same
  * `! ${name}\n` if the file name is in both directories, but the files' contents differ
  * `? ${name}\n` if the file name is in both directories, but there is trouble reading the contents of either file
* Exit status:
  * `0` if the name is in both directories, and the files' contents are the same
  * `1` if the directories' contents differ w/r/t the name
  * `2` if the file name is in both directories, but there is trouble reading either files' contents
* Precondition:
  * the provided name MUST correspond to a file in at least one of the provided directories
* Hints:
  * this helper function operates on *one* name at a time
  * DON'T try to use `diff` or `comm`
  * use a large `if elif else if` as the main construct
    * use `[]` tests with `-f`, `-e`, `&&`, `||`, and `!` as the conditions
  * use `cmp` to compare files (after you've established that the name corresponds to two files)
    * use a `case` to react to `cmp`'s result
    * probably want to silence all output from `cmp`
  * remember to BOTH produce output AND return a value
  * approximate function length: 25 to 30 lines


### `commdir.{while,for}`

The code to load `comdir.shared` into this script:
```bash
readonly real0="$(realpath -e "$0")"
readonly scriptDir="${real0%/*}"
. "$scriptDir/commdir.shared"
```

* Name: `commdir.while`, `commdir.for` - compare names of files in two directories
* Synopsis:
  * `commdir.while dir1 dir2`
  * `commdir.for   dir1 dir2`
* Output:
  * a diff-like comparison of the filenames in the provided directories
  * one filename per line
  * file *names* only, no directory component
  * every filename appears exactly once (no duplicates)
  * for each filename in either directory, the output matches that as produced by `classifyFile`
* Exit Status:
  * `2` if there is trouble with the provided arguments
  * `2` if any file(s) had '?' output
  * `0` if all files had '=' output ([or there were no files to output](https://en.wikipedia.org/wiki/Vacuous_truth))
  * `1` otherwise
* Hints `comdir.{for,while}`:
  * call `classifyFile` inside the loop
    * use a `case` to handle checking and setting various exit statuses appropriately
  * run `cowsay -t 'Use a variable to remember something...'`
* Hints `commdir.for`:
  * use a command substitution to run `getAllFileNames` in the `for`'s *list*
  * the list is one entry per line -- set `IFS` appropriately
* Hints `commdir.while`:
  * you'll need to properly scope a variable
    * which is tricky because the | creates a subprocess with its own address space
    * ensure that the variable is set and read in the same address space
    * SO: pipe `getAllFileNames` into a `{}` that contains the both variable and the `while` loop.
    Eg:
    ```bash
    foo | {  # 'foo' in one address space, {} in another
      x='bar'
      while ... ; do
        ...
      done
      ...
    }
    ```

#### Example Behaviour

First set `$script` to the unit under test. eg:
```bash
script='commdir.for'  # or 'commdir.while'
```

```bash
# empty dirs
expected='Exit status: 0'
actual="$(
  cd "$(mktemp -d)" \
  && mkdir a b \
  && $script a b
  echo "Exit status: $?"
)"
diff -u <( cat <<< "$actual" ) - <<< "$expected"
```
```bash
# ignore directories
expected='Exit status: 0'
actual="$(
  cd "$(mktemp -d)" \
  && mkdir a b \
  && mkdir a/d1 b/d1 a/d2 b/d3 \
  && touch a/d1/f{1,2} b/d1/f{2,3} a/d2/foo b/d3/bar \
  && $script a b
  echo "Exit status: $?"
)"
diff -u <( cat <<< "$actual" ) - <<< "$expected"
````
```bash
# in 1 not 2
expected='- f1
Exit status: 1'
actual="$(
  cd "$(mktemp -d)" \
  && mkdir a b \
  && touch a/f1 \
  && $script a b
  echo "Exit status: $?"
)"
diff -u <( cat <<< "$actual" ) - <<< "$expected"
```
```bash
# in 2 not 1
expected='+ f1
Exit status: 1'
actual="$(
  cd "$(mktemp -d)" \
  && mkdir a b \
  && touch b/f1 \
  && $script a b
  echo "Exit status: $?"
)"
diff -u <( cat <<< "$actual" ) - <<< "$expected"
```
```bash
# one is not a file. MYSTERIOUS!
expected='x n
Exit status: 1'
actual="$(
  cd "$(mktemp -d)" \
  && mkdir a b \
  && touch a/n && mkdir b/n \
  && $script a b
  echo "Exit status: $?"
)"
diff -u <( cat <<< "$actual" ) - <<< "$expected"
```
```bash
# two is not a file. MYSTERIOUS!
expected='x n
Exit status: 1'
actual="$(
  cd "$(mktemp -d)" \
  && mkdir a b \
  && mkdir a/n && touch b/n \
  && $script a b
  echo "Exit status: $?"
)"
diff -u <( cat <<< "$actual" ) - <<< "$expected"
```
```bash
# same file
expected='= f1
Exit status: 0'
actual="$(
  cd "$(mktemp -d)" \
  && mkdir a b \
  && echo same | tee a/f1 > b/f1 \
  && $script a b
  echo "Exit status: $?"
)"
diff -u <( cat <<< "$actual" ) - <<< "$expected"
```
```bash
# contents differ
expected='! f1
Exit status: 1'
actual="$(
  cd "$(mktemp -d)" \
  && mkdir a b \
  && echo af1 > a/f1 && echo bf1 > b/f1 \
  && $script a b
  echo "Exit status: $?"
)"
diff -u <( cat <<< "$actual" ) - <<< "$expected"
```
```bash
# cant read
expected='? f1
Exit status: 2'
actual="$(
  cd "$(mktemp -d)" \
  && mkdir a b \
  && touch {a,b}/f1 && chmod -r a/f1 \
  && $script a b
  echo "Exit status: $?"
)"
diff -u <( cat <<< "$actual" ) - <<< "$expected"
````
```bash
# =0 doesnt override !1
expected='! f1
= f2
Exit status: 1'
actual="$(
  cd "$(mktemp -d)" \
  && mkdir a b \
  && touch {a,b}/f{1,2} && echo foo > a/f1 \
  && $script a b
  echo "Exit status: $?"
)"
diff -u <( cat <<< "$actual" ) - <<< "$expected"
````
```bash
# !1 doesnt override ?2
expected='? f1
! f2
Exit status: 2'
actual="$(
  cd "$(mktemp -d)" \
  && mkdir a b \
  && touch {a,b}/f{1,2} && chmod -r a/f1 && echo foo > a/f2 \
  && $script a b
  echo "Exit status: $?"
)"
diff -u <( cat <<< "$actual" ) - <<< "$expected"
````
```bash
# =0 doesnt override ?2
expected='? f1
= f2
Exit status: 2'
actual="$(
  cd "$(mktemp -d)" \
  && mkdir a b \
  && touch {a,b}/f{1,2} && chmod -r a/f1 \
  && $script a b
  echo "Exit status: $?"
)"
diff -u <( cat <<< "$actual" ) - <<< "$expected"
````
```bash
# all together now!
# nothing overrides ?2 status
expected='? f1
- f2
+ f3
x f4
! f5
= f6
= f7
Exit status: 2'
actual="$(
  cd "$(mktemp -d)" \
  && mkdir a b \
  && touch {a,b}/f{1..7} \
  && chmod -r a/f1 \
  && rm b/f2 a/f3 a/f4 \
  && mkdir a/f4 \
  && echo foo > a/f5 && echo bar > b/f5 \
  && echo same | tee a/f6 > b/f6 \
  && $script a b
  echo "Exit status: $?"
)"
diff -u <( cat <<< "$actual" ) - <<< "$expected"
````
