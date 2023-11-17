#!/bin/bash
#
# Install script
#
# Downloads and installs a binary from the given url.

set -euo pipefail

# ========================
# Customize install script
# ========================

# This script is published at get.jetpack.io/devbox so users can install via:
# curl -fsSL https://get.jetpack.io/devbox | bash

readonly INSTALL_DIR="/usr/local/bin"
readonly BIN="devbox"
readonly DOWNLOAD_URL="https://releases.jetpack.io/devbox"

readonly TITLE="Devbox 📦 by jetpack.io"
readonly DESCRIPTION=$(
	cat <<EOF
  Instant and predictable development environments and containers.

  This script downloads and installs the latest devbox binary.
EOF
)
readonly DOCS_URL="https://github.com/jetpack-io/devbox"
readonly COMMUNITY_URL="https://discord.gg/jetpack-io"

# ====================
# flags.sh
# ====================
FORCE="${FORCE:-0}"

parse_flags() {
	while [ "$#" -gt 0 ]; do
		case "$1" in
		-f | --force)
		FORCE=1
		shift 1
		;;
		*)
		error "Unknown option: $1"
		exit 1
		;;
		esac
	done
}

# ====================
# format.sh
# ====================

readonly BOLD="$(tput bold 2>/dev/null || echo '')"
readonly GREY="$(tput setaf 8 2>/dev/null || echo '')"
readonly UNDERLINE="$(tput smul 2>/dev/null || echo '')"
readonly RED="$(tput setaf 1 2>/dev/null || echo '')"
readonly GREEN="$(tput setaf 2 2>/dev/null || echo '')"
readonly YELLOW="$(tput setaf 3 2>/dev/null || echo '')"
readonly BLUE="$(tput setaf 4 2>/dev/null || echo '')"
readonly MAGENTA="$(tput setaf 5 2>/dev/null || echo '')"
readonly CYAN="$(tput setaf 6 2>/dev/null || echo '')"
readonly NO_COLOR="$(tput sgr0 2>/dev/null || echo '')"
readonly CLEAR_LAST_MSG="\033[1F\033[0K"

title() {
	local -r text="$*"
	printf "%s\n" "${BOLD}${MAGENTA}${text}${NO_COLOR}"
}

header() {
	local -r text="$*"
	printf "%s\n" "${BOLD}${text}${NO_COLOR}"
}

plain() {
	local -r text="$*"
	printf "%s\n" "${text}"
}

info() {
	local -r text="$*"
	printf "%s\n" "${BOLD}${GREY}→${NO_COLOR} ${text}"
}

warn() {
	local -r text="$*"
	printf "%s\n" "${YELLOW}! $*${NO_COLOR}"
}

error() {
	local -r text="$*"
	printf "%s\n" "${RED}✘ ${text}${NO_COLOR}" >&2
}

success() {
	local -r text="$*"
	printf "%s\n" "${GREEN}✓${NO_COLOR} ${text}"
}

start_task() {
	local -r text="$*"
	printf "%s\n" "${BOLD}${GREY}→${NO_COLOR} ${text}..."
}

end_task() {
	local -r text="$*"
	printf "${CLEAR_LAST_MSG}%s\n" "${GREEN}✓${NO_COLOR} ${text}... [DONE]"
}

fail_task() {
	local -r text="$*"
	printf "${CLEAR_LAST_MSG}%s\n" "${RED}✘ ${text}... [FAILED]${NO_COLOR}" >&2
}

confirm() {
	if [ ${FORCE-} -ne 1 ]; then
		printf "%s " "${MAGENTA}?${NO_COLOR} $* ${BOLD}[Y/n]${NO_COLOR}"
		set +e
		read -r yn </dev/tty
		rc=$?
		set -e
		if [ $rc -ne 0 ]; then
			error "Error reading from prompt (re-run with '-f' flag to auto select Yes if running in a script)"
			exit 1
		fi
		if [ "$yn" != "y" ] && [ "$yn" != "Y" ] && [ "$yn" != "yes" ] && [ "$yn" != "" ]; then
			error 'Aborting (please answer "yes" to continue)'
			exit 1
		fi
	fi
}

delay() {
	sleep 0.3
}

# =========
# util.sh
# =========
has() {
	command -v "$1" 1>/dev/null 2>&1
}

download() {
	local -r url="$1"
	local -r file="$2"
	local cmd=""

	if has curl; then
		cmd="curl --fail --silent --location --output $file $url"
	elif has wget; then
		cmd="wget --quiet --output-document=$file $url"
	elif has fetch; then
		cmd="fetch --quiet --output=$file $url"
	else
		error "No program to download files found. Please install one of: curl, wget, fetch"
		error "Exiting..."
		return 1
	fi

	if [[ ${3:-} == "--fail" ]]; then
		$cmd && return 0 || rc=$?
		error "Command failed (exit code $rc): ${BLUE}${cmd}${NO_COLOR}"
		exit $rc
	fi

	$cmd && return 0 || rc=$?
	return $rc
}

# ==============
# Implementation
# ==============
intro_msg() {
	title "${TITLE}"
	plain "${DESCRIPTION}"
	printf "\n"
	header "Confirm Installation Details"
	plain "  Location:     ${GREEN}${INSTALL_DIR}/${BIN}${NO_COLOR}"
	plain "  Download URL: ${UNDERLINE}${BLUE}${DOWNLOAD_URL}${NO_COLOR}"
	printf "\n"
}

install_flow() {
	confirm "Install ${GREEN}${BIN}${NO_COLOR} to ${GREEN}${INSTALL_DIR}${NO_COLOR} (requires sudo)?"
	printf "\n"
	header "Downloading and Installing"

	start_task "Downloading ${BIN} binary"
	local -r tmp_file=$(mktemp)
	download "${DOWNLOAD_URL}" "${tmp_file}" --fail
	delay
	end_task "Downloading ${BIN} binary"

	start_task "Installing in ${INSTALL_DIR}/${BIN} (requires sudo)"
	chmod +x "${tmp_file}"
	$(command -v sudo || true) bash -c "mkdir -p ${INSTALL_DIR} && mv ${tmp_file} ${INSTALL_DIR}/${BIN}"
	delay
	end_task "Installing in ${INSTALL_DIR}/${BIN}"
	delay

	success "${BOLD}Successfully installed ${GREEN}${BIN}${NO_COLOR}${BOLD}${NO_COLOR} 🚀"
	delay
	printf "\n"
}

next_steps_msg() {
	header "Next Steps"
	plain "  1. ${BOLD}Learn how to use ${BIN}${NO_COLOR}"
	plain "     ${GREY}Run ${CYAN}${BIN} help${GREY} or read the docs at ${UNDERLINE}${BLUE}${DOCS_URL}${NO_COLOR}"
	plain "  2. ${BOLD}Get help and give feedback${NO_COLOR}"
	plain "     ${GREY}Join our community at ${UNDERLINE}${BLUE}${COMMUNITY_URL}${NO_COLOR}"
}

main() {
	parse_flags "$@"
	intro_msg
	install_flow
	next_steps_msg
}

main "$@"
