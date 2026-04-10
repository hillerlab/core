/*
Copyright (c) 2026 The Hiller Lab at the Senckenberg Gessellschaft für Naturforschung
Distributed under the terms of the Apache License, Version 2.0.
*/

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT LOCAL MODULES/SUBWORKFLOWS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

include { APARENT_CHUNK } from '../../modules/nextflow/aparent/chunk/main.nf'
include { APARENT_PREDICT } from '../../modules/nextflow/aparent/predict/main.nf'

include { WGET as WGET_APARENT_WEIGHTS } from '../../modules/nextflow/wget/main.nf'

include { BEDGRAPHTOBIGWIG as BIGTOOLS_BEDGRAPHTOBIGWIG_FORWARD } from '../../modules/nextflow/bigtools/bedgraphtobigwig/main.nf'
include { BEDGRAPHTOBIGWIG as BIGTOOLS_BEDGRAPHTOBIGWIG_REVERSE } from '../../modules/nextflow/bigtools/bedgraphtobigwig/main.nf'

include { GAWK_JOIN as GAWK_JOIN_BEDGRAPH_FORWARD } from '../../modules/nextflow/gawk/join/main.nf'
include { GAWK_JOIN as GAWK_JOIN_BEDGRAPH_REVERSE } from '../../modules/nextflow/gawk/join/main.nf'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    LOCAL SUBWORKFLOWS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow APARENT {
    take:
      reads                  // channel: [ val(meta), [ reads ] ]
      genome                 // Channel.value(path)
      chrom_sizes            // Channel.value(path)
      repeats                // path
      aparent_weights        // path
      ch_versions            // [ meta, versions.yml ]

    main:
      ch_genome = genome.map { g -> [ [id:g.baseName], g ] }

      ch_aparent_weights = WGET_APARENT_WEIGHTS(
          Channel.value(
            aparent_weights
          ).map { url -> [ [id : url.tokenize('/')[-1]], url ] }
      )

     APARENT_CHUNK(
        reads,
        ch_genome
     )

     APARENT_CHUNK.out.chunks
        .flatMap { 
            meta, chunk_tsv ->
            def chunk_tsvs = chunk_tsv instanceof List ? chunk_tsv : [chunk_tsv]
            chunk_tsvs.withIndex().collect { it, idx ->
                [ meta + [ chunk: idx ], it ]
            }
        }
        .set { ch_aparent_chunks }

      APARENT_PREDICT(
        ch_aparent_chunks, 
        ch_aparent_weights.outfile
      )

      APARENT_PREDICT.out.bg_forward
        .map { meta, bg -> bg }
        .collect()
        .map { bgs -> [ [id:'aparent.forward', strand:'forward'], bgs ] }
        .set { ch_joined_aparent_bgs_forward }

      GAWK_JOIN_BEDGRAPH_FORWARD(ch_joined_aparent_bgs_forward, 'bg')
      BIGTOOLS_BEDGRAPHTOBIGWIG_FORWARD(GAWK_JOIN_BEDGRAPH_FORWARD.out.output, chrom_sizes)

      APARENT_PREDICT.out.bg_reverse
        .map { meta, bg -> bg  }
        .collect()
        .map { bgs -> [ [id:'aparent.reverse', strand:'reverse'], bgs ] }
        .set { ch_joined_aparent_bgs_reverse }

      GAWK_JOIN_BEDGRAPH_REVERSE(ch_joined_aparent_bgs_reverse, 'bg')
      BIGTOOLS_BEDGRAPHTOBIGWIG_REVERSE(GAWK_JOIN_BEDGRAPH_REVERSE.out.output, chrom_sizes)

      ch_versions = ch_versions.mix(APARENT_CHUNK.out.versions)
      ch_versions = ch_versions.mix(APARENT_PREDICT.out.versions)
      ch_versions = ch_versions.mix(GAWK_JOIN_BEDGRAPH_FORWARD.out.versions)
      ch_versions = ch_versions.mix(GAWK_JOIN_BEDGRAPH_REVERSE.out.versions)
      ch_versions = ch_versions.mix(BIGTOOLS_BEDGRAPHTOBIGWIG_FORWARD.out.versions)
      ch_versions = ch_versions.mix(BIGTOOLS_BEDGRAPHTOBIGWIG_REVERSE.out.versions)

    emit:
      aparent_plus          = BIGTOOLS_BEDGRAPHTOBIGWIG_FORWARD.out.bigwig
      aparent_minus         = BIGTOOLS_BEDGRAPHTOBIGWIG_REVERSE.out.bigwig
      versions              = ch_versions
}
