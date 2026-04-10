/*
Copyright (c) 2026 The Hiller Lab at the Senckenberg Gessellschaft für Naturforschung
Distributed under the terms of the Apache License, Version 2.0.
*/

process TWOBIT_TO_FA {
    tag "$twobit"
    label 'process_single'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/ucsc-twobittofa:482--hdc0a859_0' :
        'quay.io/biocontainers/ucsc-twobittofa:482--hdc0a859_0' }"

    input:
    tuple val(meta), path(twobit)

    output:
    tuple val(meta), path("*.fasta"), emit: fasta
    path "versions.yml", emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: twobit.baseName
    """
    twoBitToFa \\
        $args \\
        "$twobit" \\
        ${prefix}.fasta

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        twoBitToFa: \$(twoBitToFa -version 2>/dev/null | head -n1 || echo "unknown")
    END_VERSIONS
    """

    stub:
    def prefix = task.ext.prefix ?: twobit.baseName
    """
    touch ${prefix}.fasta

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        twoBitToFa: "stub"
    END_VERSIONS
    """
}
