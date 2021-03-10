
## Part 1: `lengthof.*`

The `lengthof` scripts tell you the (string) lengths of various inputs.  The length of each input is displayed, followed by the [sentinel value](https://en.wikipedia.org/wiki/Sentinel_value) `==`, followed by the sum of the reported lengths. Each output is one per line.

| Script                 | Displays the length of...              | Using |
| ---:                   | :---                                   | :---  |
| `lengthof.args`        | ...each command line argument.         | `for`, `while`, or `until`
| `lengthof.filenames`   | ...each name in the current directory. | `for`
| `lengthof.lines`       | ...each line of input on `stdin`.      | `while` and `read`

### Sample Behaviours

You should be able to copy & paste ALL of the text bellow (at once) to run all of the included test cases.  There should be no output when run this way.  Of course, you may copy & paste test cases one at a time to isolate and eliminate bugs.

Note: while these tests are extensive, they are not exhaustive. They are not guaranteed to be either necessary, nor sufficient.

#### `# lengthof.args`

```bash
expected='11
14
13
13
18
14
==
83'
actual="$( lengthof.args \
  commdir.for commdir.shared commdir.while \
  lengthof.args lengthof.filenames lengthof.lines )"
diff -u <( cat <<< "$actual" ) - <<< "$expected"
```
```bash
expected='6
18
==
24'
actual="$( lengthof.args '6 long' '   3x3   spaces   ' )"
diff -u <( cat <<< "$actual" ) - <<< "$expected"
```
```bash
expected='8
==
8'
actual="$( lengthof.args "$(printf '%s\n' '\k' '\a' '\\')" )"
diff -u <( cat <<< "$actual" ) - <<< "$expected"
```
```bash
expected='6
==
6'
actual="$( lengthof.args "$(printf '%b\n' '\k' '\a' '\\')" )"
diff -u <( cat <<< "$actual" ) - <<< "$expected"
```
```bash
expected='21
24
44
54
23
21
15
27
13
23
42
45
19
20
47
==
438'
actual="$(
  LC_COLLATE=C
  dir="$(find ~ -type f \
    -name 'Adventures of Huckleberry Finn, Complete.txt' \
    -print -quit)" \
  && dir="${dir%/*}" \
  && cd "$dir" \
  && lengthof.args *
)"
diff -u <( cat <<< "$actual" ) - <<< "$expected"
```

#### `# lengthof.filenames`

```bash
expected='3
==
3'  # just 'dir', not 'file' or 'dir/file'
actual="$( LC_COLLATE=C ; cd "$(mktemp -d)" \
  && mkdir dir && touch dir/file \
  && lengthof.filenames )"
diff -u <( cat <<< "$actual" ) - <<< "$expected"
```
```bash
expected='11
14
13
13
18
14
==
83'
actual="$( LC_COLLATE=C ; cd "$(mktemp -d)" \
  && touch commdir.for commdir.shared commdir.while \
    lengthof.args lengthof.filenames lengthof.lines \
  && lengthof.filenames )"
diff -u <( cat <<< "$actual" ) - <<< "$expected"
```
```bash
expected='18
6
==
24'
actual="$( LC_COLLATE=C ; cd "$(mktemp -d)" \
  && touch '6 long' '   3x3   spaces   ' \
  && lengthof.filenames )"
diff -u <( cat <<< "$actual" ) - <<< "$expected"
```
```bash
expected='8
==
8'
actual="$( LC_COLLATE=C ; cd "$(mktemp -d)" \
  && touch "$(printf '%s\n' '\k' '\a' '\\')" \
  && lengthof.filenames )"
diff -u <( cat <<< "$actual" ) - <<< "$expected"
```
```bash
expected='6
==
6'
actual="$( LC_COLLATE=C ; cd "$(mktemp -d)" \
  && touch "$(printf '%b\n' '\k' '\a' '\\')" \
  && lengthof.filenames )"
diff -u <( cat <<< "$actual" ) - <<< "$expected"
```
```bash
expected='21
24
44
54
23
21
15
27
13
23
42
45
19
20
47
==
438'
actual="$(
  LC_COLLATE=C
  dir="$(find ~ -type f \
    -name 'Adventures of Huckleberry Finn, Complete.txt' \
    -print -quit)" \
  && dir="${dir%/*}" \
  && cd "$dir" \
  && lengthof.filenames
)"
diff -u <( cat <<< "$actual" ) - <<< "$expected"
```

#### `# lengthof.lines`

```bash
expected='11
14
13
13
18
14
==
83'
actual="$( printf -- '%s\n' \
  commdir.for commdir.shared commdir.while \
  lengthof.args lengthof.filenames lengthof.lines \
  | lengthof.lines )"
diff -u <( cat <<< "$actual" ) - <<< "$expected"
```
```bash
expected='6
18
==
24'
actual="$(printf -- '%s\n' '6 long' '   3x3   spaces   ' \
  | lengthof.lines)"
diff -u <( cat <<< "$actual" ) - <<< "$expected"
```
```bash
expected='2
2
2
==
6'
actual="$( printf '%s\n' '\k' '\a' '\\' | lengthof.lines )"
diff -u <( cat <<< "$actual" ) - <<< "$expected"
```
```bash
expected='2
1
1
==
4'
actual="$( printf '%b\n' '\k' '\a' '\\' | lengthof.lines )"
diff -u <( cat <<< "$actual" ) - <<< "$expected"
```
```bash
expected='21
24
44
54
23
21
15
27
13
23
42
45
19
20
47
==
438'
actual="$(
  LC_COLLATE=C
  dir="$(find ~ -type f \
    -name 'Adventures of Huckleberry Finn, Complete.txt' \
    -print -quit)" \
  && dir="${dir%/*}" \
  && cd "$dir" \
  && printf -- '%s\n' * \
  | lengthof.lines
)"
diff -u <( cat <<< "$actual" ) - <<< "$expected"
```
```bash
expected='6142647'  # $(( $(cat * | wc -m) - $(cat * | wc -l) ))
actual="$(
  LC_COLLATE=C
  dir="$(find ~ -type f \
    -name 'Adventures of Huckleberry Finn, Complete.txt' \
    -print -quit)" \
  && dir="${dir%/*}" \
  && cd "$dir" \
  && cat * \
  | lengthof.lines \
  | tail -1
)"
diff -u <( cat <<< "$actual" ) - <<< "$expected"
```
