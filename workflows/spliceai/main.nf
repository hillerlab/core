/*
Copyright (c) 2026 The Hiller Lab at the Senckenberg Gessellschaft für Naturforschung
Distributed under the terms of the Apache License, Version 2.0.
*/

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT LOCAL MODULES/SUBWORKFLOWS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

include { SPLICEAI as RUN } from '../../subworkflows/spliceai/main.nf'
include { GENOME } from '../../subworkflows/genome/main.nf'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    WORKFLOWS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow SPLICEAI {
    main:
      ch_versions = Channel.empty()
      ch_genome = GENOME(params.genome)
      compression = params.compression ? true : false

      RUN(
          ch_genome.genome.map { g -> [ [ id: g.baseName ], g ] },
          ch_genome.chrom_sizes,
          compression,
          ch_versions
      )

    emit:
      spliceai = RUN.out.spliceai
}

workflow {
    SPLICEAI()
}
