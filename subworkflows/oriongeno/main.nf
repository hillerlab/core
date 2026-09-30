/*
Copyright (c) 2026 The Hiller Lab at the Senckenberg Gessellschaft für Naturforschung
Distributed under the terms of the Apache License, Version 2.0.
*/

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    ORIONGENO — Scatter a genome, annotate each piece on one GPU, gather.

    Uses ORIONGENO_PREDICT (one GPU per piece), not ORIONGENO_MULTI.
    Scatter is none, chromosome, or weighted. Each predict job restarts
    gene ids at g1 and repeat ids at r1. Gather puts chunks back in FASTA
    order and renumbers those ids. Repeats are gathered only when requested.
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

include { FXSPLIT } from '../../modules/nextflow/fxsplit/main.nf'
include { ORIONGENO_PREDICT } from '../../modules/nextflow/oriongeno/predict/main.nf'

def oriongenoLineages() {
    return ['mammals', 'birds', 'fish', 'other_vertebrates', 'arthropods', 'other_invertebrates', 'plants', 'fungi']
}

def oriongenoScatterModes() {
    return ['none', 'chromosome', 'weighted']
}

def oriongenoBool(value) {
    if (value == null) {
        return false
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

def oriongenoPackBins(records, nBins) {
    def n = Math.max(1, nBins as int)
    n = Math.min(n, records.size())
    def bins = (0..<n).collect { [order: it, total: 0L, records: []] }
    records.toSorted { a, b ->
        def byLen = (b.length as long) <=> (a.length as long)
        byLen != 0 ? byLen : ((a.order as int) <=> (b.order as int))
    }.each { rec ->
        def target = bins.min { x, y -> x.total <=> y.total ?: x.order <=> y.order }
        target.records << rec
        target.total += rec.length as long
    }
    bins.each { bin -> bin.records = bin.records.toSorted { it.order } }
    return bins.findAll { !it.records.isEmpty() }
}

def oriongenoResolveRecord(seqid, files) {
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

def oriongenoParseManifest(path) {
    def records = []
    path.withReader { reader ->
        def header = reader.readLine()
        if (header == null || header.split('\t')*.trim() != ['order', 'seqid', 'length']) {
            error "Malformed OrionGeno manifest header in ${path}: '${header}' (expected 'order\\tseqid\\tlength')"
        }
        reader.eachLine { line ->
            if (!line) {
                return
            }
            def parts = line.split('\t', 3)
            if (parts.size() < 3 || !parts[0].trim().matches(/\d+/) || !parts[2].trim().matches(/\d+/)) {
                error "Malformed OrionGeno manifest line in ${path}: '${line}' (expected 'order\\tseqid\\tlength' with numeric order/length)"
            }
            records << [
                order : parts[0] as int,
                seqid : parts[1],
                length: parts[2] as long,
            ]
        }
    }
    return records
}

process ORIONGENO_MANIFEST {
    tag "$meta.id"
    label 'process_single'

    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        '' :
        'ghcr.io/hillerlab/oriongeno:latest' }"

    input:
    tuple val(meta), path(fasta)
    path scatter_py

    output:
    tuple val(meta), path("records.tsv"), emit: manifest
    path "versions.yml",                  emit: versions

    script:
    """
    python3 ${scatter_py} manifest ${fasta} records.tsv

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        python: \$( python3 --version 2>/dev/null | sed 's/Python //' || echo 3 )
    END_VERSIONS
    """

    stub:
    """
    printf 'order\\tseqid\\tlength\\n0\\tchr1\\t1\\n' > records.tsv

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        python: 3
    END_VERSIONS
    """
}

process ORIONGENO_CAT {
    tag "$meta.id"
    label 'process_single'

    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        '' :
        'ghcr.io/hillerlab/oriongeno:latest' }"

    input:
    tuple val(meta), path(fastas)

    output:
    tuple val(meta), path("combined.fa"), emit: fasta
    path "versions.yml",                  emit: versions

    script:
    """
    cat ${fastas} > combined.fa

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        cat: \$( cat --version | head -n 1 | sed 's/.* //' )
    END_VERSIONS
    """

    stub:
    """
    touch combined.fa

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        cat: na
    END_VERSIONS
    """
}

process ORIONGENO_GATHER {
    tag "$meta.id"
    label 'process_single'

    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        '' :
        'ghcr.io/hillerlab/oriongeno:latest' }"

    input:
    tuple val(meta), path(annotations), path(manifest)
    path scatter_py

    output:
    tuple val(meta), path("${prefix}.${ext}"), emit: annotation
    path "versions.yml",                       emit: versions

    script:
    prefix = task.ext.prefix ?: "${meta.id}"
    ext    = (meta.oriongeno_ext ?: 'gtf').toString()
    """
    python3 ${scatter_py} genes ${ext} ${manifest} ${prefix}.${ext} ${annotations}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        python: \$( python3 --version 2>/dev/null | sed 's/Python //' || echo 3 )
    END_VERSIONS
    """

    stub:
    prefix = task.ext.prefix ?: "${meta.id}"
    ext    = (meta.oriongeno_ext ?: 'gtf').toString()
    """
    touch ${prefix}.${ext}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        python: 3
    END_VERSIONS
    """
}

process ORIONGENO_GATHER_REPEATS {
    tag "$meta.id"
    label 'process_single'

    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        '' :
        'ghcr.io/hillerlab/oriongeno:latest' }"

    input:
    tuple val(meta), path(annotations), path(manifest)
    path scatter_py

    output:
    tuple val(meta), path("${prefix}.repeat.${ext}"), emit: annotation
    path "versions.yml",                              emit: versions

    script:
    prefix = task.ext.prefix ?: "${meta.id}"
    ext    = (meta.oriongeno_ext ?: 'gtf').toString()
    """
    python3 ${scatter_py} repeats ${ext} ${manifest} ${prefix}.repeat.${ext} ${annotations}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        python: \$( python3 --version 2>/dev/null | sed 's/Python //' || echo 3 )
    END_VERSIONS
    """

    stub:
    prefix = task.ext.prefix ?: "${meta.id}"
    ext    = (meta.oriongeno_ext ?: 'gtf').toString()
    """
    touch ${prefix}.repeat.${ext}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        python: 3
    END_VERSIONS
    """
}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    ORIONGENO subworkflow
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow ORIONGENO {
    take:
    genome          // channel: [ val(meta), path(fasta) ]
    lineage         // value: mammals|birds|fish|other_vertebrates|arthropods|other_invertebrates|plants|fungi
    scatter_mode    // value: none|chromosome|weighted
    scatter_bins    // value: integer, used when scatter_mode == weighted
    format          // value: gtf|gff|gff3
    output_repeat   // value: boolean

    main:
    ch_versions = Channel.empty()
    def scatter_py = file("${moduleDir}/oriongeno_scatter.py", checkIfExists: true)

    def lin = lineage.toString()
    def lineages = oriongenoLineages()
    if (!lineages.contains(lin)) {
        error "Unsupported OrionGeno lineage '${lin}'. Choose one of: ${lineages.join(', ')}"
    }

    def mode = scatter_mode.toString()
    def scatter_modes = oriongenoScatterModes()
    if (!scatter_modes.contains(mode)) {
        error "Unsupported OrionGeno scatter mode '${mode}'. Choose one of: ${scatter_modes.join(', ')}"
    }

    def normalized = (format ?: 'gtf').toString().toLowerCase()
    if (!(normalized in ['gtf', 'gff', 'gff3'])) {
        error "Unsupported OrionGeno format '${normalized}'. Use gtf or gff3."
    }
    def ext = normalized == 'gtf' ? 'gtf' : 'gff3'
    def want_repeat = oriongenoBool(output_repeat)

    def n_bins = 8
    if (scatter_bins != null && scatter_bins.toString().trim()) {
        n_bins = scatter_bins as int
    }
    if (mode == 'weighted' && n_bins < 1) {
        error "OrionGeno weighted scatter requires --oriongeno_bins >= 1"
    }

    genome
        .map { meta, fasta ->
            def sample = meta.id ?: fasta.baseName
            [
                meta + [
                    sample                  : sample,
                    oriongeno_format        : ext,
                    oriongeno_output_repeat : want_repeat,
                    oriongeno_ext           : ext,
                ],
                fasta,
            ]
        }
        .set { ch_prepared }

    if (mode == 'none') {
        ch_prepared
            .map { meta, fasta ->
                [meta + [id: meta.sample, chunk: 'all', order: 0], fasta]
            }
            .set { ch_pieces }

        ORIONGENO_PREDICT(ch_pieces, lin)
        ch_versions = ch_versions.mix(ORIONGENO_PREDICT.out.versions)

        if (ext == 'gtf') {
            ORIONGENO_PREDICT.out.annotation
                .map { meta, anno -> [[id: meta.sample, sample: meta.sample], anno] }
                .set { ch_gtf }
            Channel.empty().set { ch_gff }
        } else {
            Channel.empty().set { ch_gtf }
            ORIONGENO_PREDICT.out.annotation
                .map { meta, anno -> [[id: meta.sample, sample: meta.sample], anno] }
                .set { ch_gff }
        }

        if (want_repeat && ext == 'gtf') {
            ORIONGENO_PREDICT.out.repeats
                .map { meta, rep -> [[id: meta.sample, sample: meta.sample], rep] }
                .set { ch_repeat_gtf }
            Channel.empty().set { ch_repeat_gff }
        } else if (want_repeat) {
            Channel.empty().set { ch_repeat_gtf }
            ORIONGENO_PREDICT.out.repeats
                .map { meta, rep -> [[id: meta.sample, sample: meta.sample], rep] }
                .set { ch_repeat_gff }
        } else {
            Channel.empty().set { ch_repeat_gtf }
            Channel.empty().set { ch_repeat_gff }
        }
    } else {
        ORIONGENO_MANIFEST(ch_prepared, scatter_py)
        ch_versions = ch_versions.mix(ORIONGENO_MANIFEST.out.versions)

        ORIONGENO_MANIFEST.out.manifest
            .map { meta, man ->
                def records = oriongenoParseManifest(man)
                if (records.isEmpty()) {
                    error "No FASTA records found for ${meta.sample}"
                }
                if (mode == 'chromosome' && records.size() > 1000) {
                    error "OrionGeno chromosome scatter would launch ${records.size()} jobs for ${meta.sample}. Use --oriongeno_scatter weighted --oriongeno_bins N"
                }
                tuple(meta.sample, true)
            }
            .set { ch_scatter_ok }

        ch_prepared
            .map { meta, fasta -> tuple(meta.sample, meta, fasta) }
            .join(ch_scatter_ok)
            .map { sample, meta, fasta, ok -> [meta + [headers: true], fasta] }
            .set { ch_to_split }

        FXSPLIT(ch_to_split)
        ch_versions = ch_versions.mix(FXSPLIT.out.versions)

        FXSPLIT.out.fastx
            .mix(FXSPLIT.out.fastx_gz)
            .map { meta, files -> tuple(meta.sample, meta, files instanceof List ? files : [files]) }
            .join(
                ORIONGENO_MANIFEST.out.manifest.map { meta, man -> tuple(meta.sample, man) }
            )
            .flatMap { sample, meta, files, man ->
                def records = oriongenoParseManifest(man)
                if (records.isEmpty()) {
                    error "No FASTA records found for ${sample}"
                }
                if (mode == 'weighted') {
                    return oriongenoPackBins(records, n_bins).collect { bin ->
                        def chunk = "bin${(bin.order + 1).toString().padLeft(3, '0')}"
                        [
                            meta + [
                                id     : "${meta.sample}.${chunk}",
                                chunk  : chunk,
                                order  : bin.order,
                                records: bin.records.collect { it.seqid },
                            ],
                            bin.records.collect { rec -> oriongenoResolveRecord(rec.seqid, files) },
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
                        oriongenoResolveRecord(rec.seqid, files),
                    ]
                }
            }
            .set { ch_split }

        if (mode == 'weighted') {
            ORIONGENO_CAT(ch_split)
            ch_versions = ch_versions.mix(ORIONGENO_CAT.out.versions)
            ORIONGENO_CAT.out.fasta.set { ch_pieces }
        } else {
            ch_split.set { ch_pieces }
        }

        ORIONGENO_PREDICT(ch_pieces, lin)
        ch_versions = ch_versions.mix(ORIONGENO_PREDICT.out.versions)

        ORIONGENO_PREDICT.out.annotation
            .map { meta, anno -> tuple(meta.sample, meta, anno) }
            .groupTuple()
            .map { sample, metas, annos ->
                def paired = [metas, annos].transpose().sort { it[0].order }
                [
                    [
                        id             : sample,
                        sample         : sample,
                        oriongeno_ext  : ext,
                    ],
                    paired.collect { it[1] },
                ]
            }
            .map { meta, annos -> tuple(meta.id, meta, annos) }
            .join(
                ORIONGENO_MANIFEST.out.manifest.map { meta, man -> tuple(meta.sample, man) }
            )
            .map { sample, meta, annos, man -> [meta, annos, man] }
            .set { ch_gather_input }

        ORIONGENO_GATHER(ch_gather_input, scatter_py)
        ch_versions = ch_versions.mix(ORIONGENO_GATHER.out.versions)

        if (ext == 'gtf') {
            ORIONGENO_GATHER.out.annotation.set { ch_gtf }
            Channel.empty().set { ch_gff }
        } else {
            Channel.empty().set { ch_gtf }
            ORIONGENO_GATHER.out.annotation.set { ch_gff }
        }

        if (want_repeat) {
            ORIONGENO_PREDICT.out.repeats
                .map { meta, rep -> tuple(meta.sample, meta, rep) }
                .groupTuple()
                .map { sample, metas, reps ->
                    def paired = [metas, reps].transpose().sort { it[0].order }
                    [
                        [
                            id            : sample,
                            sample        : sample,
                            oriongeno_ext : ext,
                        ],
                        paired.collect { it[1] },
                    ]
                }
                .map { meta, reps -> tuple(meta.id, meta, reps) }
                .join(
                    ORIONGENO_MANIFEST.out.manifest.map { meta, man -> tuple(meta.sample, man) }
                )
                .map { sample, meta, reps, man -> [meta, reps, man] }
                .set { ch_repeat_input }

            ORIONGENO_GATHER_REPEATS(ch_repeat_input, scatter_py)
            ch_versions = ch_versions.mix(ORIONGENO_GATHER_REPEATS.out.versions)

            if (ext == 'gtf') {
                ORIONGENO_GATHER_REPEATS.out.annotation.set { ch_repeat_gtf }
                Channel.empty().set { ch_repeat_gff }
            } else {
                Channel.empty().set { ch_repeat_gtf }
                ORIONGENO_GATHER_REPEATS.out.annotation.set { ch_repeat_gff }
            }
        } else {
            Channel.empty().set { ch_repeat_gtf }
            Channel.empty().set { ch_repeat_gff }
        }
    }

    emit:
    gtf        = ch_gtf
    gff        = ch_gff
    repeat_gtf = ch_repeat_gtf
    repeat_gff = ch_repeat_gff
    versions   = ch_versions
}
