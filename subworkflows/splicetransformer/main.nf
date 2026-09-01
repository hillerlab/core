/*
Copyright (c) 2026 The Hiller Lab at the Senckenberg Gessellschaft für Naturforschung
Distributed under the terms of the Apache License, Version 2.0.
*/

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT LOCAL MODULES/SUBWORKFLOWS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

include { SPLICETRANSFORMER_CHUNK } from '../../modules/nextflow/splicetransformer/chunk/main.nf'
include { SPLICETRANSFORMER_PREDICT } from '../../modules/nextflow/splicetransformer/predict/main.nf'
include { SPLICETRANSFORMER_PUBLISH } from '../../modules/nextflow/splicetransformer/publish/main.nf'

include { UCSC_WIGTOBIGWIG as WIGTOBIGWIG_DONOR_PLUS } from '../../modules/nextflow/ucsc/wigtobigwig/main.nf'
include { UCSC_WIGTOBIGWIG as WIGTOBIGWIG_DONOR_MINUS } from '../../modules/nextflow/ucsc/wigtobigwig/main.nf'
include { UCSC_WIGTOBIGWIG as WIGTOBIGWIG_ACCEPTOR_PLUS } from '../../modules/nextflow/ucsc/wigtobigwig/main.nf'
include { UCSC_WIGTOBIGWIG as WIGTOBIGWIG_ACCEPTOR_MINUS } from '../../modules/nextflow/ucsc/wigtobigwig/main.nf'

include { BIGWIGMERGE as BIGWIGMERGE_DONOR_PLUS } from '../../modules/nextflow/bigtools/bigwigmerge/main.nf'
include { BIGWIGMERGE as BIGWIGMERGE_DONOR_MINUS } from '../../modules/nextflow/bigtools/bigwigmerge/main.nf'
include { BIGWIGMERGE as BIGWIGMERGE_ACCEPTOR_PLUS } from '../../modules/nextflow/bigtools/bigwigmerge/main.nf'
include { BIGWIGMERGE as BIGWIGMERGE_ACCEPTOR_MINUS } from '../../modules/nextflow/bigtools/bigwigmerge/main.nf'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    LOCAL SUBWORKFLOWS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/


workflow SPLICETRANSFORMER {
    take:
      genome         // channel: [ val(meta), [ genome ] ]
      chromsizes     // channel: [  chromsizes ] 
      compression    // bool
      ch_versions    // channel: [ path(version) ]

    main:
      ch_chunks = Channel.empty()
      SPLICETRANSFORMER_CHUNK(genome)

      if (compression) {
        SPLICETRANSFORMER_CHUNK.out.fasta_gz
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
        SPLICETRANSFORMER_CHUNK.out.fasta
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

      SPLICETRANSFORMER_PREDICT(ch_chunks)

      WIGTOBIGWIG_DONOR_PLUS(SPLICETRANSFORMER_PREDICT.out.donor_plus, chromsizes)
      WIGTOBIGWIG_DONOR_MINUS(SPLICETRANSFORMER_PREDICT.out.donor_minus, chromsizes)
      WIGTOBIGWIG_ACCEPTOR_PLUS(SPLICETRANSFORMER_PREDICT.out.acceptor_plus, chromsizes)
      WIGTOBIGWIG_ACCEPTOR_MINUS(SPLICETRANSFORMER_PREDICT.out.acceptor_minus, chromsizes)

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

      SPLICETRANSFORMER_PUBLISH(
          BIGWIGMERGE_DONOR_PLUS.out.bigwig,
          BIGWIGMERGE_DONOR_MINUS.out.bigwig,
          BIGWIGMERGE_ACCEPTOR_PLUS.out.bigwig,
          BIGWIGMERGE_ACCEPTOR_MINUS.out.bigwig,
      )
      
    emit:
      splicetransformer = SPLICETRANSFORMER_PUBLISH.out.splicetransformer
      versions = ch_versions
}
