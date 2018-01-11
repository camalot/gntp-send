
__error() {
	(>&2 echo "${1:-"Unknown Error"}");
	exit 9;
}
