/*
Copyright (c) 2026 The Hiller Lab at the Senckenberg Gessellschaft für Naturforschung
Distributed under the terms of the Apache License, Version 2.0.
*/

/*
 * Canonicalize all PBSIM3 subread BAMs as one synthetic PacBio movie before
 * they are merged.
 *
 * CCS chunking is defined for a single movie. PBSIM3, however, restarts ZMW
 * numbering for every simulated movie and emits the placeholder RG
 * ID:ffffffff. `longread rg` therefore:
 *   1. assigns every original movie/ZMW pair a deterministic global ZMW;
 *   2. rewrites QNAME and zm tags to that global ZMW;
 *   3. rewrites all records to one specification-compliant SUBREAD read group;
 *   4. emits a map preserving the original identity.
 *
 * This replaces an earlier samtools/awk/sort pipeline. `longread rg` does the
 * work entirely in-process (noodles + libdeflate), in two parallel passes over
 * the input BAMs, bounding the number of simultaneously open file descriptors,
 * and producing byte-identical output regardless of thread count.
 */

process LONGREAD_RG {
    tag "${meta.id}"
    label 'process_high_cpu'

    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        '' :
        'ghcr.io/hillerlab/longread-rs:latest' }"

    input:
    tuple val(meta), path(bams)

    output:
    tuple val(meta), path("*.normalized.bam"), emit: bam
    tuple val(meta), path("zmw_map.tsv"),      emit: map
    path "versions.yml",                       emit: versions

    script:
    """
    # Pass the (potentially thousands of) input BAMs via a list file rather than argv.
    ls -1 *.bam > bam.list

    longread rg \\
        --movie "movie.${meta.id}" \\
        --bams bam.list \\
        --outdir . \\
        --zmw-map zmw_map.tsv \\
        --threads ${task.cpus}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        longread: \$(longread --version | sed 's/longread //')
    END_VERSIONS
    """

    stub:
    """
    for bam in ${bams}; do
        touch "\${bam%.bam}.normalized.bam"
    done
    touch zmw_map.tsv

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        longread: \$(longread --version | sed 's/longread //')
    END_VERSIONS
    """
}
