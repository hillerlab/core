/*
Copyright (c) 2026 The Hiller Lab at the Senckenberg Gessellschaft für Naturforschung
Distributed under the terms of the Apache License, Version 2.0.
*/

/*
 * Fail before pbmerge if CCS chunks overlap in PacBio's movie/ZMW key space.
 *
 * `longread check` scans every chunk BAM in parallel and errors if any
 * movie/ZMW key appears in more than one record across the collection. It
 * replaces an earlier samtools/awk/sort | uniq pipeline.
 */

process LONGREAD_CHECK {
    tag "${meta.id}"
    label 'process_low'

    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        '' :
        'ghcr.io/hillerlab/longread-rs:latest' }"

    input:
    tuple val(meta), path(bams)

    output:
    tuple val(meta), path("ccs_chunks.valid"), emit: valid
    path "versions.yml",                       emit: versions

    script:
    """
    # Pass the input BAMs via a list file rather than argv.
    ls -1 *.bam > bam.list

    longread check \\
        --bams bam.list \\
        --out ccs_chunks.valid \\
        --threads ${task.cpus}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        longread: \$(longread --version | sed 's/longread //')
    END_VERSIONS
    """

    stub:
    """
    touch ccs_chunks.valid

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        longread: \$(longread --version | sed 's/longread //')
    END_VERSIONS
    """
}
