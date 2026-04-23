// Copyright (c) 2025 Alejandro Gonzales-Irribarren <alejandrxgzi@gmail.com>
// Distributed under the terms of the Apache License, Version 2.0.

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    CHUNKER — Splits genomic regions (BED/GTF/GFF) and sequences (2bit/FA/FA.GZ) 
    into chunks for parallel processing. Allows to extend the extracted chunk by a given
    upstream and downstream amount of nucleotides. Additionally, it allows to specify 
    the number of chunks to be generated.
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

process CHUNKER {
    tag "$meta.id:$meta.chr"
    label 'process_low'

    conda "${moduleDir}/environment.yml"
    container 'ghcr.io/alejandrogzi/orf-chunk:latest'

    input:
    tuple val(meta), path(regions)
    tuple val(meta1), path(sequence)
    val(chunk_size)

    output:
    tuple val(meta), path('tmp/*bed'),     optional: true, emit: chunked_regions
    tuple val(meta), path('tmp/*fa'),      optional: true, emit: chunked_sequences
    path "versions.yml",  emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def upstream = task.ext.upstream ?: 1000
    def downstream = task.ext.downstream ?: 1000
    def prefix = task.ext.prefix ?: meta.chr
    """
    orf chunk \\
    --regions $regions \\
    --sequence $sequence \\
    --chunks $chunk_size \\
    -u $upstream \\
    -d $downstream \\
    --prefix $prefix \\
    --ignore-errors

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        orf-chunk: \$(orf --version 2>&1 | sed 's/^.*orf //; s/ .*\$//')
    END_VERSIONS
    """

    stub:
    """
    touch tmp
    touch tmp/*bed
    touch tmp/*fa

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        orf-chunk: \$(orf --version 2>&1 | sed 's/^.*orf //; s/ .*\$//')
    END_VERSIONS
    """
}
