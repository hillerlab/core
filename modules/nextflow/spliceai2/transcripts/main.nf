/*
Copyright (c) 2026 The Hiller Lab at the Senckenberg Gessellschaft für Naturforschung
Distributed under the terms of the Apache License, Version 2.0.
*/

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    SPLICEAI2_TRANSCRIPTS — Decode transcript structures for a set of loci.
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

process SPLICEAI2_TRANSCRIPTS {
    tag "$meta.id"
    label 'process_high'
    label 'process_gpu'

    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        '' :
        'ghcr.io/hillerlab/spliceai2:latest' }"

    input:
    tuple val(meta), path(genome), path(genome_fai), path(loci)
    path models
    val species

    output:
    tuple val(meta), path("transcripts/*.transcripts.bed"), emit: transcripts
    tuple val(meta), path("transcripts/*.skipped.bed"),     emit: skipped
    path "versions.yml",                                    emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    """
    test -s "${genome_fai}"

    spliceai2 transcripts --no-compile \\
        $args \\
        --genome "${genome}" \\
        --loci "${loci}" \\
        --models "${models}" \\
        --species "${species}" \\
        --outdir transcripts

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        spliceai2: \$( spliceai2 --version | sed 's/^spliceai2 //g' )
    END_VERSIONS
    """

    stub:
    def prefix = meta.id
    """
    mkdir -p transcripts
    touch "transcripts/${prefix}.transcripts.bed" "transcripts/${prefix}.skipped.bed"

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        spliceai2: \$( spliceai2 --version | sed 's/^spliceai2 //g' )
    END_VERSIONS
    """
}
