#!/bin/bash -ue
BASE_DIR=$(dirname $(realpath $0))
TEMPLATE="Constantinos_Solomonides_CV.tex"
CONFIGURATION_TARGET="${BASE_DIR}/configuration.tex"
ROLES=( softwarengineer devops generalist testengineer )
ROLE="${ROLES[0]}"
BASE_NAME=${BASE_NAME:-"Constantinos_Solomonides_CV"}
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

function usage(){
    cat <<-END
    -v                  Set debug mode on (`set -x` output)
    -n                  dry-run (echo, instead of running commands). Some side-effects remain
    -c                  Activate CDD mode (print message that shows preference for CDD / freelance work)
    -l <LANGUAGE>       Select output language. Can be used more than once to select multiple. Known ones are \
                            ${USER_LANGUAGES[@]}
    -r <ROLE>           Select role. Currently available are ${ROLES[@]} 
    -H                  Set HTML mode, better for text-like copy-paste
    -h                  Output this message and exit
    -<ANYTHING ELSE>    Output this message and exit with error
END
exit ${1}
}


while getopts "hvnr:cl:H" OPT; do
    case ${OPT} in
            v) set -x
        ;;  n) export E=echo
        ;;  r) if (export IFS=$'\n'; echo "${ROLES[*]}" | grep -q -e "${OPTARG}") ; then
                    ROLE="${OPTARG}";
                fi
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

function prepare_file(){
    role="${1}"
    language="${2}"
    cdd="${3}"

    count=0; for i in "${role}" "${language}" "${cdd}"; do
        if [ -z "${i}" ]; then
            echo "Element at position ${count} was empty" 1>&2
            exit 1
        fi
        count=$((count +1))
    done

    if [ -z "${CONFIGURATION_TARGET}" ]; then
        echo "Configuration target not set. Exiting" >&2
        exit 1
    fi
    : > ${CONFIGURATION_TARGET}
    ${E} cat >"${CONFIGURATION_TARGET}" <<-END
        \\renewcommand{\\targetrole}{${role}}
        \\renewcommand{\\cvlanguage}{${language}}
        \\renewcommand{\\cddrequested}{${cdd}}
END
}


function generate_pdf(){
    destination="${2}"
    language="${3}"

    ${E} ${PDFTEX} --output-directory="${destination}" --jobname="${BASE_NAME}_${NAMES[${language}]}" ${TEMPLATE} >&2
}

function generate_html(){

    file=${1}
    destination="${2}"
    language="${3}"

    fix_files
    ${E} ${HTMLTEX} ${file} >&2
        {   [ ! -z "${E}" ] \
         || { [ -e "${file/tex/html}" ] \
                &&  {
                    for i in ${file/tex/*}; do
                        [ "tex" == "${i/*./}" ] && continue;
                        ${E} mv "${i}" "${destination}/${BASE_NAME}_${NAMES[${language}]}.${i/*./}" >&2
                    done
                }; }; } \
    ||  { echo "File ${file/tex/html} not created or can't be moved" 1>&2; exit 1; }
}


# -- MAIN functionality

for language in ${USER_LANGUAGES[*]}; do
    file=${BASE_DIR}/${TEMPLATE}
        {       [ ! -z "${E}"  ] \
            ||  { [ -f "${file}" ] && [ -w "${file}" ]; };
        } \
    ||  { echo "File ${file} not found or not writable, exiting " 1>&2; exit 1; }

    prepare_file "${ROLE}" "${language}" "${CDD}"

    case "${GENERATE}" in
            pdf)    generate_pdf "${file}" "${RESUMES_DIR}" "${language}"
        ;;  html)   generate_html "${file}" "${RESUMES_DIR}" "${language}"
        ;;  *) usage
    esac
done
