/*
Copyright (c) 2026 The Hiller Lab at the Senckenberg Gessellschaft für Naturforschung
Distributed under the terms of the Apache License, Version 2.0.
*/

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT LOCAL MODULES/SUBWORKFLOWS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

include { SPLICEAI2_CHUNK } from '../../modules/nextflow/spliceai2/chunk/main.nf'
include { SPLICEAI2_PREDICT } from '../../modules/nextflow/spliceai2/predict/main.nf'
include { SPLICEAI2_TRANSCRIPTS } from '../../modules/nextflow/spliceai2/transcripts/main.nf'
include { SPLICEAI2_PUBLISH } from '../../modules/nextflow/spliceai2/publish/main.nf'

include { UCSC_WIGTOBIGWIG as WIGTOBIGWIG_DONOR_PLUS } from '../../modules/nextflow/ucsc/wigtobigwig/main.nf'
include { UCSC_WIGTOBIGWIG as WIGTOBIGWIG_DONOR_MINUS } from '../../modules/nextflow/ucsc/wigtobigwig/main.nf'
include { UCSC_WIGTOBIGWIG as WIGTOBIGWIG_ACCEPTOR_PLUS } from '../../modules/nextflow/ucsc/wigtobigwig/main.nf'
include { UCSC_WIGTOBIGWIG as WIGTOBIGWIG_ACCEPTOR_MINUS } from '../../modules/nextflow/ucsc/wigtobigwig/main.nf'

include { BIGWIGMERGE as BIGWIGMERGE_DONOR_PLUS } from '../../modules/nextflow/bigtools/bigwigmerge/main.nf'
include { BIGWIGMERGE as BIGWIGMERGE_DONOR_MINUS } from '../../modules/nextflow/bigtools/bigwigmerge/main.nf'
include { BIGWIGMERGE as BIGWIGMERGE_ACCEPTOR_PLUS } from '../../modules/nextflow/bigtools/bigwigmerge/main.nf'
include { BIGWIGMERGE as BIGWIGMERGE_ACCEPTOR_MINUS } from '../../modules/nextflow/bigtools/bigwigmerge/main.nf'

workflow SPLICEAI2 {
    take:
      genome         // channel: [ val(meta), path(genome) ]
      chromsizes     // channel: [ path(chromsizes) ]
      compression    // bool
      models         // path(model directory)
      species        // SpliceAI2 species name
      genome_fai     // path(genome.fai), required with loci
      loci           // path(BED6), optional
      ch_versions    // channel: [ path(version) ]

    main:
      ch_chunks = Channel.empty()
      ch_transcripts = Channel.empty()
      ch_skipped = Channel.empty()
      SPLICEAI2_CHUNK(genome, compression)

      if (compression) {
        SPLICEAI2_CHUNK.out.fasta_gz
            .flatMap {
                meta, fa ->
                def fas = fa instanceof List ? fa : [fa]
                fas.collect { it ->
                    def identifier = it.baseName.replaceFirst(/^tmp\./, '').replaceFirst(/\.fa$/, '')
                    [ [ id: meta.id + '.' + identifier ], it ]
                }
            }
            .set { ch_chunks }
      } else {
        SPLICEAI2_CHUNK.out.fasta
            .flatMap {
                meta, fa ->
                def fas = fa instanceof List ? fa : [fa]
                fas.collect { it ->
                    def identifier = it.baseName.replaceFirst(/^tmp\./, '').replaceFirst(/\.fa$/, '')
                    [ [ id: meta.id + '.' + identifier ], it ]
                }
            }
            .set { ch_chunks }
      }

      SPLICEAI2_PREDICT(ch_chunks, models, species)

      WIGTOBIGWIG_DONOR_PLUS(SPLICEAI2_PREDICT.out.donor_plus, chromsizes)
      WIGTOBIGWIG_DONOR_MINUS(SPLICEAI2_PREDICT.out.donor_minus, chromsizes)
      WIGTOBIGWIG_ACCEPTOR_PLUS(SPLICEAI2_PREDICT.out.acceptor_plus, chromsizes)
      WIGTOBIGWIG_ACCEPTOR_MINUS(SPLICEAI2_PREDICT.out.acceptor_minus, chromsizes)

      BIGWIGMERGE_DONOR_PLUS(
          WIGTOBIGWIG_DONOR_PLUS.out.bigwig
            .map { meta, bigwig -> bigwig }
            .collect()
            .map { bws -> [ [ id : 'donor_plus' ], bws ] },
      )
      BIGWIGMERGE_DONOR_MINUS(
          WIGTOBIGWIG_DONOR_MINUS.out.bigwig
            .map { meta, bigwig -> bigwig }
            .collect()
            .map { bws -> [ [ id : 'donor_minus' ], bws ] },
      )
      BIGWIGMERGE_ACCEPTOR_PLUS(
          WIGTOBIGWIG_ACCEPTOR_PLUS.out.bigwig
            .map { meta, bigwig -> bigwig }
            .collect()
            .map { bws -> [ [ id : 'acceptor_plus' ], bws ] },
      )
      BIGWIGMERGE_ACCEPTOR_MINUS(
          WIGTOBIGWIG_ACCEPTOR_MINUS.out.bigwig
            .map { meta, bigwig -> bigwig }
            .collect()
            .map { bws -> [ [ id : 'acceptor_minus' ], bws ] },
      )

      SPLICEAI2_PUBLISH(
          BIGWIGMERGE_DONOR_PLUS.out.bigwig,
          BIGWIGMERGE_DONOR_MINUS.out.bigwig,
          BIGWIGMERGE_ACCEPTOR_PLUS.out.bigwig,
          BIGWIGMERGE_ACCEPTOR_MINUS.out.bigwig,
      )

      if (loci != null) {
          SPLICEAI2_TRANSCRIPTS(
              genome.map { meta, fasta -> [ meta, fasta, genome_fai, loci ] },
              models,
              species
          )
          ch_transcripts = SPLICEAI2_TRANSCRIPTS.out.transcripts
          ch_skipped = SPLICEAI2_TRANSCRIPTS.out.skipped
      }

    emit:
      spliceai2   = SPLICEAI2_PUBLISH.out.spliceai2
      transcripts = ch_transcripts
      skipped     = ch_skipped
      versions    = ch_versions
}
