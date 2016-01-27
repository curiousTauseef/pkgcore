# Common library of shell functions for parsing various Gentoo-related data
# and leveraging pkgcore functionality.

# get an attribute for a given package
_pkgattr() {
	local pkg_attr=$1 pkg_atom=$2 repo=$3
	local ret=0 pid fdout fderr
	local -a pkg error

	if [[ -z ${pkg_atom} ]]; then
		echo "Enter a valid package name." >&2
		return 1
	fi

	# setup pipes for stdout/stderr capture
	local tmpdir=$(mktemp -d)
	trap "rm -rf '${tmpdir}'" EXIT HUP INT TERM
	mkfifo "${tmpdir}"/{stdout,stderr}

	if [[ -n ${repo} ]]; then
		pquery -r "${repo}" --raw --unfiltered --cpv --one-attr "${pkg_attr}" -n -- "${pkg_atom}" >"${tmpdir}"/stdout 2>"${tmpdir}"/stderr &
	else
		pquery --ebuild-repos --raw --unfiltered --cpv --one-attr "${pkg_attr}" -n -- "${pkg_atom}" >"${tmpdir}"/stdout 2>"${tmpdir}"/stderr &
	fi

	# capture pquery stdout/stderr into separate vars
	pid=$!
	exec {fdout}<"${tmpdir}"/stdout {fderr}<"${tmpdir}"/stderr
	rm -rf "${tmpdir}"
	mapfile -t -u ${fdout} pkg
	mapfile -t -u ${fderr} error
	wait ${pid}
	ret=$?
	exec {fdout}<&- {fderr}<&-

	if [[ ${ret} != 0 ]]; then
		# show pquery error message
		echo "${error[-1]}" >&2
		return 1
	fi

	local choice
	if [[ -z ${pkg[@]} ]]; then
		echo "No matches found." >&2
		return 1
	elif [[ ${#pkg[@]} > 1 ]]; then
		echo "Multiple matches found:" >&2
		choice=$(_choose "${pkg[@]%%:*}")
		[[ $? -ne 0 ]] && return 1
	else
		choice=-1
	fi
	echo ${pkg[${choice}]#*:}
}

# cross-shell compatible PATH searching
_which() {
	type -P "$1" >/dev/null
}

# cross-shell compatible array index helper
# bash arrays start at 0
_array_index() {
	echo $1
}
