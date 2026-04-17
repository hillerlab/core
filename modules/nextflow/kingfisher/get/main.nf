/*
Copyright (c) 2026 The Hiller Lab at the Senckenberg Gessellschaft für Naturforschung
Distributed under the terms of the Apache License, Version 2.0.
*/

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    KINGFISHER —  Downloads SRA runs from the Sequence Read Archive using kingfisher.
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

process KINGFISHER_GET {
    tag "$accession"
    label 'process_single'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/kingfisher:0.5.0--pyhdfd78af_0' :
        'quay.io/biocontainers/kingfisher:0.5.0--pyhdfd78af_0	' }"

    input:
    val(accession)

    output:
    tuple val(meta), path("*.fastq.gz"), optional: true, emit: fastq
    tuple val(meta), path("*.fasta"),    optional: true, emit: fasta
    tuple val(meta), path("*.bam"),      optional: true, emit: bam
    path "versions.yml",                 emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def provider = task.ext.provider ?: 'ena-ftp aws-http aws-cp'
    meta = [ id: accession ]
    """
    kingfisher \\
    get \\
    -r ${accession} \\
    -m ${provider}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        kingfisher: \$(kingfisher --version 2>&1 | sed 's/^.*kingfisher //; s/ .*\$//')
    END_VERSIONS
    """

    stub:
    """
    touch *.fastq.gz
    touch *.fasta
    touch *.bam

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        kingfisher: \$(kingfisher --version 2>&1 | sed 's/^.*kingfisher //; s/ .*\$//')
    END_VERSIONS
    """
}
