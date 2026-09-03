/*
Copyright (c) 2026 The Hiller Lab at the Senckenberg Gessellschaft für Naturforschung
Distributed under the terms of the Apache License, Version 2.0.
*/

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT LOCAL MODULES/SUBWORKFLOWS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

include { FXSPLIT } from '../../modules/nextflow/fxsplit/main.nf'
include { ANNEVO_PREDICTION } from '../../modules/nextflow/annevo/prediction/main.nf'
include { ANNEVO_DECODING } from '../../modules/nextflow/annevo/decoding/main.nf'

def ANNEVO_LINEAGES = ['Mammalia', 'Insecta', 'Aves', 'Actinopteri', 'Magnoliopsida', 'Fungi'] as Set
def ANNEVO_OVERLAP_LINEAGES = ['Mammalia', 'Actinopteri'] as Set
def ANNEVO_SCATTER_MODES = ['none', 'chromosome', 'weighted'] as Set

def annevoBool(value) {
    if (value == null) {
        return null
    }
    if (value instanceof Boolean) {
        return value
    }
    def text = value.toString().trim().toLowerCase()
    if (text in ['true', '1', 'yes', 'y', 'on']) {
        return true
    }
    if (text in ['false', '0', 'no', 'n', 'off', '']) {
        return false
    }
    error "Cannot parse boolean value: ${value}"
}

def annevoPackBins(records, nBins) {
    def n = Math.max(1, nBins as int)
    n = Math.min(n, records.size())
    def bins = (0..<n).collect { [order: it, total: 0L, records: []] }
    records.toSorted { -it.length }.each { rec ->
        def target = bins.min { a, b -> a.total <=> b.total ?: a.order <=> b.order }
        target.records << rec
        target.total += rec.length as long
    }
    bins.each { bin -> bin.records = bin.records.toSorted { it.order } }
    return bins.findAll { !it.records.isEmpty() }
}

def annevoResolveRecord(seqid, files) {
    def exact = files.find { it.baseName == seqid }
    if (exact) {
        return exact
    }
    def prefixed = files.find { it.baseName.startsWith(seqid + '.') || it.baseName.startsWith(seqid + '_') }
    if (prefixed) {
        return prefixed
    }
    def safe = seqid.replaceAll(/[^A-Za-z0-9._-]/, '_')
    def sanitized = files.find { it.baseName == safe || it.baseName.startsWith(safe + '.') }
    if (sanitized) {
        return sanitized
    }
    error "No FXSPLIT output for FASTA record '${seqid}' among ${files*.name}"
}

def annevoParseManifest(path) {
    def records = []
    path.withReader { reader ->
        def header = reader.readLine()
        reader.eachLine { line ->
            if (!line) {
                return
            }
            def parts = line.split('\t', 3)
            records << [
                order : parts[0] as int,
                seqid : parts[1],
                length: parts[2] as long,
            ]
        }
    }
    return records
}

process ANNEVO_MANIFEST {
    tag "$meta.id"
    label 'process_single'

    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        '' :
        'ghcr.io/hillerlab/annevo:latest' }"

    input:
    tuple val(meta), path(fasta)

    output:
    tuple val(meta), path("records.tsv"), emit: manifest
    path "versions.yml",                  emit: versions

    script:
    """
    awk 'BEGIN { OFS="\\t"; print "order", "seqid", "length" }
         /^>/ {
             if (seqid != "") print order, seqid, len
             if (seqid != "") order++
             seqid = substr(\$1, 2)
             len = 0
             next
         }
         {
             gsub(/\\r/, "")
             len += length(\$0)
         }
         END {
             if (seqid != "") print order, seqid, len
         }' ${fasta} > records.tsv

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        awk: \$( { awk --version || awk -W version || echo awk; } 2>/dev/null | head -n 1 )
    END_VERSIONS
    """

    stub:
    """
    echo -e "order\\tseqid\\tlength\\n0\\tchr1\\t1" > records.tsv

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        awk: \$( { awk --version || awk -W version || echo awk; } 2>/dev/null | head -n 1 )
    END_VERSIONS
    """
}

process ANNEVO_CAT {
    tag "$meta.id"
    label 'process_single'

    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        '' :
        'ghcr.io/hillerlab/annevo:latest' }"

    input:
    tuple val(meta), path(fastas)

    output:
    tuple val(meta), path("*.fa"), emit: fasta
    path "versions.yml",            emit: versions

    script:
    prefix = task.ext.prefix ?: "${meta.id}"
    """
    cat ${fastas} > ${prefix}.fa

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        cat: \$( cat --version | head -n 1 | sed 's/.* //' )
    END_VERSIONS
    """

    stub:
    prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}.fa

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        cat: na
    END_VERSIONS
    """
}

process ANNEVO_GATHER {
    tag "$meta.id"
    label 'process_single'

    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        '' :
        'ghcr.io/hillerlab/annevo:latest' }"

    input:
    tuple val(meta), path(gffs), path(manifest)

    output:
    tuple val(meta), path("*.annevo.gff3"), emit: gff
    path "versions.yml",                     emit: versions

    script:
    prefix = task.ext.prefix ?: "${meta.id}"
    """
    python - "${manifest}" "${prefix}.annevo.gff3" ${gffs} <<'PY'
import sys
from pathlib import Path

manifest = Path(sys.argv[1])
output = Path(sys.argv[2])
gff_paths = [Path(path) for path in sys.argv[3:]]

order = []
with manifest.open() as handle:
    next(handle, None)
    for line in handle:
        line = line.rstrip("\\n")
        if not line:
            continue
        order.append(line.split("\\t", 2)[1])

header = []
blocks = {}
banner = "# ----- prediction on sequence number"
name_tag = "name = "

def consume(path):
    current_id = None
    current = []

    def flush():
        nonlocal current_id, current
        if current_id is not None:
            blocks[current_id] = "".join(current)
        current_id = None
        current = []

    with path.open() as handle:
        for line in handle:
            if (
                line.startswith("# This output was generated with ANNEVO")
                or line.startswith("# ANNEVO is an ab initio")
                or line.startswith("# Citation:")
            ):
                if line not in header:
                    header.append(line)
                continue
            if line.startswith(banner):
                flush()
                start = line.rfind(name_tag)
                if start < 0:
                    raise SystemExit(f"cannot parse sequence banner: {line!r}")
                current_id = line[start + len(name_tag):].split(")", 1)[0].strip()
                current = [line]
                continue
            if current_id is None:
                continue
            current.append(line)
    flush()

for path in gff_paths:
    consume(path)

written = set()
with output.open("w") as handle:
    handle.writelines(header)
    for seqid in order:
        text = blocks.get(seqid)
        if text:
            handle.write(text)
            written.add(seqid)
    for seqid, text in blocks.items():
        if seqid not in written:
            handle.write(text)
PY

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        annevo: \$( annevo --version | sed 's/annevo //g' )
    END_VERSIONS
    """

    stub:
    prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}.annevo.gff3

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        annevo: \$( annevo --version | sed 's/annevo //g' )
    END_VERSIONS
    """
}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    ANNEVO subworkflow
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow ANNEVO {
    take:
    genome          // channel: [ val(meta), path(fasta) ]
    lineage         // value: Mammalia|Insecta|Aves|Actinopteri|Magnoliopsida|Fungi
    scatter_mode    // value: none|chromosome|weighted
    scatter_bins    // value: integer, used when scatter_mode == weighted
    overlap_pred    // value: boolean or null (null → lineage default)

    main:
    ch_versions = Channel.empty()

    def lin = lineage.toString()
    if (!ANNEVO_LINEAGES.contains(lin)) {
        error "Unsupported ANNEVO lineage '${lin}'. Choose one of: ${ANNEVO_LINEAGES.join(', ')}"
    }

    def mode = scatter_mode.toString()
    if (!ANNEVO_SCATTER_MODES.contains(mode)) {
        error "Unsupported ANNEVO scatter mode '${mode}'. Choose one of: ${ANNEVO_SCATTER_MODES.join(', ')}"
    }

    def parsed_overlap = annevoBool(overlap_pred)
    def use_overlap = parsed_overlap == null ? ANNEVO_OVERLAP_LINEAGES.contains(lin) : parsed_overlap

    def n_bins = 8
    if (scatter_bins != null && scatter_bins.toString().trim()) {
        n_bins = scatter_bins as int
    }
    if (mode == 'weighted' && n_bins < 1) {
        error "ANNEVO weighted scatter requires --annevo_bins >= 1"
    }

    genome
        .map { meta, fasta ->
            def sample = meta.id ?: fasta.baseName
            def flags = []
            if (use_overlap) {
                flags << '--overlap_pred'
            }
            if (meta.annevo_args) {
                flags << meta.annevo_args
            }
            [
                meta + [
                    sample     : sample,
                    lineage    : lin,
                    annevo_args: flags.join(' '),
                ],
                fasta,
            ]
        }
        .set { ch_prepared }

    ANNEVO_MANIFEST(ch_prepared)
    ch_versions = ch_versions.mix(ANNEVO_MANIFEST.out.versions)

    if (mode == 'none') {
        ch_prepared
            .map { meta, fasta -> [meta + [id: meta.sample, chunk: 'all', order: 0], fasta] }
            .set { ch_pieces }
    } else {
        FXSPLIT(
            ch_prepared.map { meta, fasta -> [meta + [headers: true], fasta] }
        )
        ch_versions = ch_versions.mix(FXSPLIT.out.versions)

        FXSPLIT.out.fastx
            .mix(FXSPLIT.out.fastx_gz)
            .map { meta, files -> tuple(meta.sample, meta, files instanceof List ? files : [files]) }
            .join(
                ANNEVO_MANIFEST.out.manifest.map { meta, man -> tuple(meta.sample, man) }
            )
            .flatMap { sample, meta, files, man ->
                def records = annevoParseManifest(man)
                if (records.isEmpty()) {
                    error "No FASTA records found for ${sample}"
                }
                if (mode == 'weighted') {
                    return annevoPackBins(records, n_bins).collect { bin ->
                        def chunk = sprintf('bin%03d', bin.order + 1)
                        [
                            meta + [
                                id     : "${meta.sample}.${chunk}",
                                chunk  : chunk,
                                order  : bin.order,
                                records: bin.records.collect { it.seqid },
                            ],
                            bin.records.collect { rec -> annevoResolveRecord(rec.seqid, files) },
                        ]
                    }
                }
                records.collect { rec ->
                    [
                        meta + [
                            id     : "${meta.sample}.${rec.seqid}",
                            chunk  : rec.seqid,
                            order  : rec.order,
                            records: [rec.seqid],
                        ],
                        annevoResolveRecord(rec.seqid, files),
                    ]
                }
            }
            .set { ch_split }

        if (mode == 'weighted') {
            ANNEVO_CAT(ch_split)
            ch_versions = ch_versions.mix(ANNEVO_CAT.out.versions)
            ANNEVO_CAT.out.fasta.set { ch_pieces }
        } else {
            ch_split.set { ch_pieces }
        }
    }

    ANNEVO_PREDICTION(ch_pieces, lin)
    ch_versions = ch_versions.mix(ANNEVO_PREDICTION.out.versions)

    ch_pieces
        .join(ANNEVO_PREDICTION.out.predictions)
        .set { ch_decode }

    ANNEVO_DECODING(ch_decode)
    ch_versions = ch_versions.mix(ANNEVO_DECODING.out.versions)

    ANNEVO_DECODING.out.gff
        .map { meta, gff -> tuple(meta.sample, meta, gff) }
        .groupTuple()
        .map { sample, metas, gffs ->
            def paired = [metas, gffs].transpose().sort { it[0].order }
            def first = paired[0][0]
            [
                [
                    id     : sample,
                    sample : sample,
                    lineage: first.lineage,
                ],
                paired.collect { it[1] },
            ]
        }
        .set { ch_gathered }

    ch_gathered
        .map { meta, gffs -> tuple(meta.id, meta, gffs) }
        .join(
            ANNEVO_MANIFEST.out.manifest.map { meta, man -> tuple(meta.sample, man) }
        )
        .map { sample, meta, gffs, man -> [meta, gffs, man] }
        .set { ch_gather_input }

    ANNEVO_GATHER(ch_gather_input)
    ch_versions = ch_versions.mix(ANNEVO_GATHER.out.versions)

    emit:
    gff         = ANNEVO_GATHER.out.gff
    predictions = ANNEVO_PREDICTION.out.predictions
    versions    = ch_versions
}
