/*
Copyright (c) 2026 The Hiller Lab at the Senckenberg Gessellschaft für Naturforschung
Distributed under the terms of the Apache License, Version 2.0.
*/

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    TIBERIUS_MERGE — Merge scattered Tiberius chunk annotations.

    Runs merge_annotations.py (full mode), restores FASTA record order from
    the sequence-order manifest, writes GTF, and optionally extracts
    protein/CDS FASTAs from the merged annotation plus the original genome.
    Gene IDs are assigned by (seqid, start, strand), not chunk order.
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

process TIBERIUS_MERGE {
    tag "$meta.id"
    label 'process_medium'

    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        '' :
        'ghcr.io/hillerlab/tiberius:latest' }"

    input:
    tuple val(meta), path(annotations), path(manifest), path(genome)
    val emit_protseq
    val emit_codingseq

    output:
    tuple val(meta), path("*.gtf"),  emit: gtf
    tuple val(meta), path("*.gff3"), emit: gff
    tuple val(meta), path("*.prot"), emit: proteins,  optional: true
    tuple val(meta), path("*.cds"),  emit: codingseq, optional: true
    path "versions.yml",             emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def prefix     = task.ext.prefix ?: "${meta.id}"
    def prot_flag  = emit_protseq ? '--protseq' : ''
    def cds_flag   = emit_codingseq ? '--codingseq' : ''
    """
    tiberius-merge \\
        --manifest ${manifest} \\
        --out-prefix ${prefix} \\
        --genome ${genome} \\
        ${prot_flag} \\
        ${cds_flag} \\
        ${annotations}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        tiberius: \$( python3 -c "import tiberius; print(tiberius.__version__)" )
    END_VERSIONS
    """

    stub:
    def prefix    = task.ext.prefix ?: "${meta.id}"
    def emit_prot = emit_protseq ? true : false
    def emit_cds  = emit_codingseq ? true : false
    """
    touch ${prefix}.gtf
    touch ${prefix}.gff3
    ${emit_prot ? "touch ${prefix}.prot" : ''}
    ${emit_cds ? "touch ${prefix}.cds" : ''}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        tiberius: \$( python3 -c "import tiberius; print(tiberius.__version__)" 2>/dev/null || echo "2.0.7" )
    END_VERSIONS
    """
}
