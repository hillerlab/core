/*
Copyright (c) 2026 The Hiller Lab at the Senckenberg Gessellschaft für Naturforschung
Distributed under the terms of the Apache License, Version 2.0.
*/

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    SPLICEAI2_PUBLISH — Collect the four SpliceAI2 strand and site BigWigs.
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

process SPLICEAI2_PUBLISH {
    tag "publish"
    label 'process_single'

    input:
    tuple val(meta), path(donor_plus)
    tuple val(meta1), path(donor_minus)
    tuple val(meta2), path(acceptor_plus)
    tuple val(meta3), path(acceptor_minus)

    output:
    path("spliceai2"), emit: spliceai2

    script:
    """
    mkdir -p spliceai2
    cp "${donor_plus}" spliceai2/
    cp "${donor_minus}" spliceai2/
    cp "${acceptor_plus}" spliceai2/
    cp "${acceptor_minus}" spliceai2/
    """

    stub:
    """
    mkdir -p spliceai2
    touch spliceai2/donor_plus.bw spliceai2/donor_minus.bw \\
          spliceai2/acceptor_plus.bw spliceai2/acceptor_minus.bw
    """
}
