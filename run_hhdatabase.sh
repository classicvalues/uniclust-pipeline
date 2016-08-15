#!/bin/bash -ex
#BSUB -q mpi-long+
#BSUB -o out.%J
#BSUB -e err.%J
#BSUB -W 120:00
#BSUB -n 160
#BSUB -a openmpi
#BSUB -m hh
#BSUB -R haswell
#BSUB -R cbscratch
#BSUB -R "span[ptile=16]"

function make_a3m () {
	local BASE="$1"
    local RELEASE="$2"
	local PREFIXCLUST="$3"
	local CLUSTDB="${BASE}/${PREFIXCLUST}_${RELEASE}"

	local TMPDIR="$4"
	mkdir -p ${TMPDIR}
	local TMPDB="${TMPDIR}/${PREFIXCLUST}_${RELEASE}"

	mmseqs addsequences "${CLUSTDB}" "${BASE}/uniprot_db" "${TMPDB}_fasta" --min-sequences 2
	ffindex_build -as "${TMPDB}_fasta" "${TMPDB}_fasta.index"
	mv -f "${TMPDB}_fasta" "${TMPDB}_fasta.ffdata"
	mv -f "${TMPDB}_fasta.index" "${TMPDB}_fasta.ffindex"

	make_a3m.sh "${TMPDB}_fasta" "${TMPDB}_a3m" "${TMPDIR}"

    mmseqs addsequences "${CLUSTDB}" "${BASE}/uniprot_db" "${TMPDB}_singleton" --max-sequences 1 --hh-format
	cp -f "${TMPDB}_a3m.ffdata" "${CLUSTDB}_a3m.ffdata"
	cp -f "${TMPDB}_a3m.ffindex" "${CLUSTDB}_a3m.ffindex" 
	ffindex_build -as "${CLUSTDB}_a3m.ffdata" "${CLUSTDB}_a3m.ffindex" -d "${TMPDB}_singleton" -i "${TMPDB}_singleton.index"
}

function make_hhdatabase () {
	local BASE="$1"
    local RELEASE="$2"
	local PREFIXCLUST="$3"
	local PREFIXBOOST="$4"
	local CLUSTDB="${BASE}/${PREFIXCLUST}_${RELEASE}"
	local BOOSTDB="${BASE}/${PREFIXBOOST}_${RELEASE}"

	local TMPDIR="$5"
	mkdir -p ${TMPDIR}

    make_a3m "${BASE}" "${RELEASE}" "${PREFIXCLUST}" "${TMPDIR}"
	make_hhmake.sh "${CLUSTDB}_a3m" "${CLUSTDB}_hhm" "${TMPDIR}"

	#make_cstranslate.sh ${CLUSTDB}_a3m ${CLUSTDB}_cs219
    make_finalize.sh "${BASE}" "$2" "${PREFIXCLUST}" "tmp/uniboost" "${TMPDIR}"
}

source ./paths.sh
make_hhdatabase "${TARGET}" "${RELEASE}" "uniclust30" "uniboost10" "${TARGET}/tmp/clust"
make_a3m "${TARGET}" "${RELEASE}" "uniclust50" "${TARGET}/tmp/clust"
make_a3m "${TARGET}" "${RELEASE}" "uniclust90" "${TARGET}/tmp/clust"
