/*
Copyright (c) 2026 The Hiller Lab at the Senckenberg Gessellschaft für Naturforschung
Distributed under the terms of the Apache License, Version 2.0.
*/

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    GUNZIP — Decompress gzipped files using gunzip.
    Extracts contents of .gz files to their original uncompressed form.
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

process GUNZIP {
    tag "$archive"
    label 'process_single'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://community-cr-prod.seqera.io/docker/registry/v2/blobs/sha256/52/52ccce28d2ab928ab862e25aae26314d69c8e38bd41ca9431c67ef05221348aa/data' :
        'community.wave.seqera.io/library/coreutils_grep_gzip_lbzip2_pruned:838ba80435a629f8' }"

    input:
    tuple val(meta), path(archive)

    output:
    tuple val(meta), path("$gunzip"), emit: gunzip
    path "versions.yml"             , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    gunzip = task.ext.prefix ?: archive.toString() - '.gz'
    """
    gunzip \\
        -c \\
        $args \\
        "$archive" \\
        > "$gunzip"

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        gzip: \$(gzip --version | head -n1 | sed 's/^.* //')
    END_VERSIONS
    """

    stub:
    gunzip = task.ext.prefix ?: archive.toString() - '.gz'
    """
    touch $gunzip

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        gzip: "stub"
    END_VERSIONS
    """
}
