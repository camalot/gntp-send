#!/usr/bin/env bash
set -e;

base_dir=$(dirname "$0");

# shellcheck source=.deploy/shared.sh
# shellcheck disable=SC1091
source "${base_dir}/shared.sh";


get_opts() {
	while getopts ":n:v:" opt; do
	  case $opt in
			n) export opt_project_name="$OPTARG";
			;;
			v) export opt_version="$OPTARG";
			;;
	    \?) __error "Invalid option -$OPTARG";
	    ;;
	  esac;
	done;
	return 0;
};

get_opts "$@";

PROJECT_NAME="${opt_project_name:-"${CI_PROJECT_NAME}"}";
BUILD_VERSION=${CI_BUILD_VERSION:-"1.0.0-snapshot"};

[[ -z "${PROJECT_NAME// }" ]] && __error "'-n' (project name) attribute is required.";
[[ -z "${BUILD_VERSION// }" ]] && __error "'-v' (version) attribute is required.";

libtoolize --copy --force;
aclocal;
automake --add-missing;
autoconf --force;

cmake "${WORKSPACE}";

ls -lFA;

[ ! -f "${WORKSPACE}/Makefile" ] && (>&2 echo 'Required Makefile is missing.') && exit 9;
make -f "${WORKSPACE}/Makefile";

mkdir -p "${WORKSPACE}/root";

mkdir -p "${WORKSPACE}/root/usr/local/bin"
mkdir -p "${WORKSPACE}/root/usr/lib";
mv "${WORKSPACE}/gntp-send" "${WORKSPACE}/root/usr/local/bin/";
mv "${WORKSPACE}/libgrowl.so" "${WORKSPACE}/root/usr/lib/";
cp -r "${WORKSPACE}/include" "${WORKSPACE}/root/usr/";

mkdir -p "${WORKSPACE}/dist/";
pushd . || exit 9;
cd "${WORKSPACE}/root" || exit 9;
pwd;
zip -r "${PROJECT_NAME}-${BUILD_VERSION}.zip" -- *;
mv "${PROJECT_NAME}-${BUILD_VERSION}.zip" "${WORKSPACE}/dist/";
popd || exit 9;


