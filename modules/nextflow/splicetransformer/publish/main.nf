/*
Copyright (c) 2026 The Hiller Lab at the Senckenberg Gessellschaft für Naturforschung
Distributed under the terms of the Apache License, Version 2.0.
*/

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    SPLICETRANSFORMER_PUBLISH — Collect and organize SpliceAI output files.
    Copies donor and acceptor strand BigWig files into a single output directory.
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

process SPLICETRANSFORMER_PUBLISH {
    tag "publish"
    label 'process_single'

    input:
    tuple val(meta), path(donor_plus)
    tuple val(meta1), path(donor_minus)
    tuple val(meta2), path(acceptor_plus)
    tuple val(meta3), path(acceptor_minus)

    output:
    path("splicetransformer"), emit: splicetransformer

    script:
    """
    mkdir -p splicetransformer
    cp ${donor_plus} splicetransformer/
    cp ${donor_minus} splicetransformer/
    cp ${acceptor_plus} splicetransformer/
    cp ${acceptor_minus} splicetransformer/
    """

    stub:
    """
    mkdir -p splicetransformer
    touch splicetransformer/*.bw
    """
}
