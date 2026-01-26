#!/bin/bash -ue
BASE_DIR=$(dirname $(realpath $0))
TEMPLATE="Constantinos_Solomonides_CV-RenderCV.tex"
BASE_NAME=${BASE_NAME:-"Constantinos_Solomonides_CV"}
TMPDIR=${TMPDIR:-"/tmp/resumes"}
RESUMES_DIR=$(realpath ${RESUMES_DIR:-"${BASE_DIR}/../resumes-output"})
E=${E:-}
CDD=${CDD:-false}
HTMLTEX=${HTMLTEX:-htlatex}
PDFTEX=${PDFTEX:-pdflatex}

declare -A NAMES
NAMES[english]=english
NAMES[french]=francais

KNOWN_LANGUAGES=( ${!NAMES[*]} )
USER_LANGUAGES=()
GENERATE=pdf
BASE_LOCATION=""

# TASKS
# * [x] Implement usage function
# * [x] Incorporate CDD functionality -> USE cddrequested
# * [x] Implement Generate HTML function
# * [x] Modify this to use exported files as well, to split file preprocessing
# * [x] define CDD function using \cddrequested command
# * [x] Error checking

function usage(){
    cat << END
    -v                  Set debug mode on (`set -x` output)
    -n                  dry-run (echo, instead of running commands). Some side-effects remain
    -t <FILENAME>       Use FILENAME as template (base CV)
    -c                  Activate CDD mode (print message that shows preference for CDD / freelance work)
    -l <LANGUAGE>       Select output language. Can be used more than once to select multiple. Known ones are \
                            ${USER_LANGUAGES[@]}
    -H                  Set HTML mode, better for text-like copy-paste
    -h                  Output this message and exit
    -<ANYTHING ELSE>    Output this message and exit with error
END
exit ${1}
}



while getopts "hvnt:cl:H" OPT; do
    case ${OPT} in
            v) set -x
        ;;  n) export E=echo
        ;;  t) [ -e "${OPTARG}" ] && TEMPLATE="${OPTARG}"
        ;;  c) CDD=true
        ;;  l)  if (export IFS=$'\n'; echo "${KNOWN_LANGUAGES[*]}" | grep -q -e "${OPTARG}") ; then
                    USER_LANGUAGES[${#USER_LANGUAGES[*]}]="${OPTARG}";
                fi
        ;;  H) GENERATE=html
        ;;  h) usage 0
        ;;  *) usage 1
    esac
done

if [ "${#USER_LANGUAGES[*]}" -eq 0 ]; then
    USER_LANGUAGES=( ${KNOWN_LANGUAGES[*]} );
fi


function fix_files(){
    # Take care of known issues in files
    ${E} sed -i education.tex -e 's/\\'"'"'Education/Education/' >&2
}

function setup_location(){
    ${E} mkdir -p "${TMPDIR}" >&2
    location=$(${E} mktemp -d -p ${TMPDIR});
    ${E} rsync -rvP --include='*.tex' --exclude='*' ${BASE_DIR}/ ${location}/ >&2
    if [ -z "${E}" ]; then echo "${location}"; fi
    if [ ! -z "${E}" ]; then echo "/tmp/safe_location"; fi
}

function prepare_file(){
    file="${1}"
    cdd="${2}"
    language="${3}"

    count=0; for i in "${file}" "${cdd}" "${language}"; do
        if [ -z "${i}" ]; then
            echo "Element at position ${count} was empty" 1>&2
            exit 1
        fi
        count=$((count +1))
    done

    ${E} sed -i "${file}" \
        -e '/%CUSTOM_COMMAND/d' \
        -e '/begin{document}/a\\\newcommand{\\'${language}'}{} %CUSTOM_COMMAND' >&2

    if [ "${cdd,,}" == "true" ]; then
        ${E} sed -i "${file}" \
        -e '/begin{document}/a\\\newcommand{\\cddrequested}{} %CUSTOM_COMMAND' >&2
    fi
}

function generate_pdf(){
    file="${1}"
    destination="${2}"
    language="${3}"

    ${E} ${PDFTEX} --output-directory="${destination}" --jobname="${BASE_NAME}_${NAMES[${language}]}" ${file} >&2
}

function generate_html(){
    file=${1}
    destination="${2}"
    language="${3}"

    fix_files
    ${E} ${HTMLTEX} ${file} >&2
        {   [ ! -z "${E}" ] \
         || { [ -e "${file/tex/html}" ] \
                &&  ${E} mv "${file/tex/html}" "${destination}/${BASE_NAME}_${NAMES[${language}]}.html" >&2 ; }; } \
    ||  { echo "File ${file/tex/html} not created or can't be moved" 1>&2; exit 1; }
}

BASE_LOCATION=$(setup_location)
[ -z "${BASE_LOCATION}" ] && { echo "Base location not set, exiting" 1>&2; exit 1; }

pushd ${BASE_LOCATION}

for language in ${USER_LANGUAGES[*]}; do
    file=${BASE_LOCATION}/${TEMPLATE}
        {       [ ! -z "${E}"  ] \
            ||  { [ -f "${file}" ] && [ -w "${file}" ]; };
        } \
    ||  { echo "File ${file} not found or not writable, exiting " 1>&2; exit 1; }

    prepare_file "${file}" "${CDD}" "${language}"

    case "${GENERATE}" in
            pdf)    generate_pdf "${file}" "${RESUMES_DIR}" "${language}"
        ;;  html)   generate_html "${file}" "${RESUMES_DIR}" "${language}"
        ;;  *) usage
    esac
done
