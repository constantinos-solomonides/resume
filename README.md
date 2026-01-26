# resume - A repository containing my CV

# Introduction

## Caveat emptor
This repository belongs in a group that serves **primarily** as a way for me to kickstart a portfolio, as my production-grade work was done as part of my employment and thus does not belong to me in any legal way. I do however design and develop scripts in multiple languages for my own use, many of which have been useful to me for many years. I'll be happy if others find use or draw inspiration from them, but there is no expectation of productising them in any way

## Use of the anonymization feature of `.gitattributes`

The CV repository uses [git filters](https://git-scm.com/docs/gitattributes#_filter) to anonymize my e-mail and phone numbers. For this feature to be usable, the following commands must be executed *at least once* from the CLI, alongside the `.gitattributes` file that enforces the filter on all files. Values in `<>` are stand-ins, and need to be replaced with the appropriate values for each user.

```sh
git config filter.anonymize.clean 'sed -e "s/<YOUR_PHONE_RE>/MY_PHONE_NUMBER/g" \
    -e "s/<YOUR_EMAIL_RE>/MY_EMAIL_ADDRESS/g"'
git config filter.anonymize.smudge 'sed -e "s/MY_PHONE_NUMBER/<YOUR_PHONE>/g" \
    -e "s/MY_EMAIL_ADDRESS/<YOUR_EMAIL>/g"'
```

## Use of the repository
This repository holds the `tex` files and the generator script for my CV. By using `LaTeX` instead of a [WYSIWYG](https://en.wikipedia.org/wiki/WYSIWYG) version, I can generate up-to-date versions of my CV as needed, for each choice of:

* `PDF` or `HTML`
* Direct Hire or Contract (CDD) - freelance use
* RenderCV or plain format
* French or English version

An additional advantage of using this approach is that, combined with the `\multilingual` custom command (defined in the file `csolomonides_header.tex`), I can have the two versions defined at the same time, avoiding the issue of "updating the one and forgetting the other". This *does* come at a slight cost of more bulky `.tex` files, however, in line with [the KISS principle](https://en.wikipedia.org/wiki/KISS_principle) that is preferable to more "elegant" and complicated approaches to resolve drift.

# The `sh` builder file
The question *may* arise why instead of an `.sh` file a `Makefile` or a set of simple CLI commands wasn't provided instead OR why the builder is in `bash`. The reasons are as follows:

* An automated method is simpler to use and expand
* Makefiles are inelegant when more than one switches are required
* `bash` is good enough for what this is meant to accomplish

## Use of the builder script

The script can be run as-is and will produce a default CV. It can also be configured via environment variables and CLI switches. The two are complementary, with CLI switches having higher precedence. However, some options, that *should* have no actual impact on the end-result are not modifiable via CLI arguments. Note that the auxiliary files generated are *intentionally* left inside the output folder for debugging and post-mortem purposes.

### Environment variables

| Variable      | Default Value     | Use                                                      |
| ------------- | ----------------- | -------------------------------------------------------- |
| `BASE_DIR`    | .                 | The base path from which any other is calculated         |
| `TEMPLATE`    | `*RenderCV.tex`   | Which template to use for the CV to be generated         |
| `BASE_NAME`   | `Constantinos_Solomonides_CV`  |                                             |
| `TMPDIR`      | `/tmp/resumes`    | Directory used to generate intermediate results          |
| `RESUMES_DIR` | `${BASE_DIR}/../resumes-output` | Where to store outputs. **MUST EXIST**     |
| `E`           | `<EMPTY_STRING>`  | Prefix for commands, `echo` for dry-run                  |
| `CDD`         | `false`           | (Pseudo-boolean, true/false). Activate CDD content in CV |
| `HTMLTEX`     | `htlatex`         | Program to use for `HTML` generation from `tex` files    |
| `PDFTEX`      | `pdflatex`        | Program to use for `PDF` generation from `tex` files     |


### CLI Switches

| Argument | Parameter    | Use                                                                    |
| -------- | ------------ | ---------------------------------------------------------------------- |
| `-v`     |              | Enable DEBUG mode (`set -x` output)                                    |
| `-n`     |              | Dry-run. Echo, do not run commands. Some (safe) side-effects happen    |
| `-t`     | `<FILENAME>` | Use `FILENAME` as template (base CV) instead of default                |
| `-c`     |              | Activate CDD mode                                                      |
| `-l`     | `<LANGUAGE>` | Select output language. Multiple choices will lead to multiple outputs |
| `-H`     |              | Enable `HTML` mode. Useful to copy-paste text in online forms          |
| `-h`     |              | Output help message and exit (success error code)                      |
| `-<ANYTHING ELSE>` |    | Output help message and exit (failure error code)                      |

## Examples

All examples below assume that you are using them from within the repository directory

`./make_resumes.sh -l french -l greek`
Generate the English and French version of the CVs in PDF format

`./make_resumes.sh -n -l french -H`
Dry run the generation of the HTML version of the French CV

`./make_resumes.sh -l french -H`
Generate the HTML version version of the French CV

`./make_resumes.sh -v -l english -H`
Generate the HTML version version of the English CV, produce verbose output

`./make_resumes.sh -v -l french -H -t Constantinos_Solomonides_CV.tex`
Generate the HTML version version of the French CV, produce verbose output, use `Constantinos_Solomonides_CV.tex` as template

`./make_resumes.sh -c -v -l french -t Constantinos_Solomonides_CV-RenderCV.tex`
Generate the PDF version version of the French CV, produce verbose output, use `Constantinos_Solomonides_CV-RenderCV.tex` (default) as template. Activate inclusion of CDD / freelance preference notice.
