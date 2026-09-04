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
include { TIBERIUS_PREDICT } from '../../modules/nextflow/tiberius/predict/main.nf'
include { TIBERIUS_MERGE } from '../../modules/nextflow/tiberius/merge/main.nf'

def tiberiusScatterModes() {
    return ['none', 'chromosome', 'weighted']
}

def tiberiusBool(value) {
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

def tiberiusPackBins(records, nBins) {
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

def tiberiusResolveRecord(seqid, files) {
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

def tiberiusParseManifest(path) {
    def records = []
    path.withReader { reader ->
        def header = reader.readLine()
        if (header == null || header.split('\t')*.trim() != ['order', 'seqid', 'length']) {
            error "Malformed TIBERIUS manifest header in ${path}: '${header}' (expected 'order\\tseqid\\tlength')"
        }
        reader.eachLine { line ->
            if (!line) {
                return
            }
            def parts = line.split('\t', 3)
            if (parts.size() < 3 || !parts[0].trim().matches(/\d+/) || !parts[2].trim().matches(/\d+/)) {
                error "Malformed TIBERIUS manifest line in ${path}: '${line}' (expected 'order\\tseqid\\tlength' with numeric order/length)"
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

process TIBERIUS_MANIFEST {
    tag "$meta.id"
    label 'process_single'

    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        '' :
        'ghcr.io/hillerlab/tiberius:latest' }"

    input:
    tuple val(meta), path(fasta)

    output:
    tuple val(meta), path("records.tsv"), emit: manifest
    path "versions.yml",                  emit: versions

    script:
    """
    awk 'BEGIN { OFS="\\t"; order = 0; print "order", "seqid", "length" }
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

process TIBERIUS_CAT {
    tag "$meta.id"
    label 'process_single'

    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        '' :
        'ghcr.io/hillerlab/tiberius:latest' }"

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

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    TIBERIUS subworkflow
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow TIBERIUS {
    take:
    genome          // channel: [ val(meta), path(fasta) ]
    model_cfg       // value: hiller alias from models.tsv
    scatter_mode    // value: none|chromosome|weighted
    scatter_bins    // value: integer, used when scatter_mode == weighted
    emit_protseq    // value: boolean
    emit_codingseq  // value: boolean

    main:
    ch_versions = Channel.empty()

    def mode = scatter_mode.toString()
    def scatter_modes = tiberiusScatterModes()
    if (!scatter_modes.contains(mode)) {
        error "Unsupported Tiberius scatter mode '${mode}'. Choose one of: ${scatter_modes.join(', ')}"
    }

    def want_prot = tiberiusBool(emit_protseq)
    def want_cds  = tiberiusBool(emit_codingseq)

    def n_bins = 8
    if (scatter_bins != null && scatter_bins.toString().trim()) {
        n_bins = scatter_bins as int
    }
    if (mode == 'weighted' && n_bins < 1) {
        error "Tiberius weighted scatter requires --tiberius_bins >= 1"
    }

    genome
        .map { meta, fasta ->
            def sample = meta.id ?: fasta.baseName
            def flags = []
            if (meta.tiberius_args) {
                flags << meta.tiberius_args
            }
            [
                meta + [
                    sample          : sample,
                    tiberius_args   : flags.join(' '),
                    tiberius_protseq: want_prot,
                    tiberius_codingseq: want_cds,
                ],
                fasta,
            ]
        }
        .set { ch_prepared }

    if (mode == 'none') {
        ch_prepared
            .map { meta, fasta ->
                [
                    meta + [
                        id                 : meta.sample,
                        chunk              : 'all',
                        order              : 0,
                        tiberius_emit_gff3 : true,
                    ],
                    fasta,
                ]
            }
            .set { ch_pieces }

        TIBERIUS_PREDICT(ch_pieces, model_cfg)
        ch_versions = ch_versions.mix(TIBERIUS_PREDICT.out.versions)

        TIBERIUS_PREDICT.out.gtf
            .map { meta, gtf -> [[id: meta.sample, sample: meta.sample], gtf] }
            .set { ch_gtf }
        TIBERIUS_PREDICT.out.gff
            .map { meta, gff -> [[id: meta.sample, sample: meta.sample], gff] }
            .set { ch_gff }
        TIBERIUS_PREDICT.out.proteins
            .map { meta, fa -> [[id: meta.sample, sample: meta.sample], fa] }
            .set { ch_prot }
        TIBERIUS_PREDICT.out.codingseq
            .map { meta, fa -> [[id: meta.sample, sample: meta.sample], fa] }
            .set { ch_cds }
    } else {
        TIBERIUS_MANIFEST(ch_prepared)
        ch_versions = ch_versions.mix(TIBERIUS_MANIFEST.out.versions)

        TIBERIUS_MANIFEST.out.manifest
            .map { meta, man ->
                def records = tiberiusParseManifest(man)
                if (records.isEmpty()) {
                    error "No FASTA records found for ${meta.sample}"
                }
                if (mode == 'chromosome' && records.size() > 1000) {
                    error "Tiberius chromosome scatter would launch ${records.size()} jobs for ${meta.sample}. Use --tiberius_scatter weighted --tiberius_bins N"
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
                TIBERIUS_MANIFEST.out.manifest.map { meta, man -> tuple(meta.sample, man) }
            )
            .flatMap { sample, meta, files, man ->
                def records = tiberiusParseManifest(man)
                if (records.isEmpty()) {
                    error "No FASTA records found for ${sample}"
                }
                if (mode == 'weighted') {
                    return tiberiusPackBins(records, n_bins).collect { bin ->
                        def chunk = "bin${(bin.order + 1).toString().padLeft(3, '0')}"
                        [
                            meta + [
                                id                 : "${meta.sample}.${chunk}",
                                chunk              : chunk,
                                order              : bin.order,
                                records            : bin.records.collect { it.seqid },
                                tiberius_emit_gff3 : false,
                                tiberius_protseq   : false,
                                tiberius_codingseq : false,
                            ],
                            bin.records.collect { rec -> tiberiusResolveRecord(rec.seqid, files) },
                        ]
                    }
                }
                records.collect { rec ->
                    [
                        meta + [
                            id                 : "${meta.sample}.${rec.seqid}",
                            chunk              : rec.seqid,
                            order              : rec.order,
                            records            : [rec.seqid],
                            tiberius_emit_gff3 : false,
                            tiberius_protseq   : false,
                            tiberius_codingseq : false,
                        ],
                        tiberiusResolveRecord(rec.seqid, files),
                    ]
                }
            }
            .set { ch_split }

        if (mode == 'weighted') {
            TIBERIUS_CAT(ch_split)
            ch_versions = ch_versions.mix(TIBERIUS_CAT.out.versions)
            TIBERIUS_CAT.out.fasta.set { ch_pieces }
        } else {
            ch_split.set { ch_pieces }
        }

        TIBERIUS_PREDICT(ch_pieces, model_cfg)
        ch_versions = ch_versions.mix(TIBERIUS_PREDICT.out.versions)

        TIBERIUS_PREDICT.out.gtf
            .map { meta, gtf -> tuple(meta.sample, meta, gtf) }
            .groupTuple()
            .map { sample, metas, gtfs ->
                def paired = [metas, gtfs].transpose().sort { it[0].order }
                def first = paired[0][0]
                [
                    [
                        id     : sample,
                        sample : sample,
                    ],
                    paired.collect { it[1] },
                ]
            }
            .map { meta, gtfs -> tuple(meta.id, meta, gtfs) }
            .join(
                TIBERIUS_MANIFEST.out.manifest.map { meta, man -> tuple(meta.sample, man) }
            )
            .join(
                ch_prepared.map { meta, fasta -> tuple(meta.sample, fasta) }
            )
            .map { sample, meta, gtfs, man, fasta -> [meta, gtfs, man, fasta] }
            .set { ch_merge_input }

        TIBERIUS_MERGE(ch_merge_input, want_prot, want_cds)
        ch_versions = ch_versions.mix(TIBERIUS_MERGE.out.versions)

        TIBERIUS_MERGE.out.gtf.set { ch_gtf }
        TIBERIUS_MERGE.out.gff.set { ch_gff }
        TIBERIUS_MERGE.out.proteins.set { ch_prot }
        TIBERIUS_MERGE.out.codingseq.set { ch_cds }
    }

    emit:
    gtf       = ch_gtf
    gff       = ch_gff
    proteins  = ch_prot
    codingseq = ch_cds
    versions  = ch_versions
}
