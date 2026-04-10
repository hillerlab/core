/*
Copyright (c) 2026 The Hiller Lab at the Senckenberg Gessellschaft für Naturforschung
Distributed under the terms of the Apache License, Version 2.0.
*/

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT LOCAL MODULES/SUBWORKFLOWS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

include { SPLICEAI_CHUNK } from '../../modules/nextflow/spliceai/chunk/main.nf'
include { SPLICEAI_PREDICT } from '../../modules/nextflow/spliceai/predict/main.nf'
include { SPLICEAI_PUBLISH } from '../../modules/nextflow/spliceai/publish/main.nf'

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


workflow SPLICEAI {
    take:
      genome         // channel: [ val(meta), [ genome ] ]
      chromsizes     // channel: [  chromsizes ] 
      compression    // bool
      ch_versions    // channel: [ path(version) ]

    main:
      ch_chunks = Channel.empty()
      SPLICEAI_CHUNK(genome)

      if (compression) {
        SPLICEAI_CHUNK.out.fasta_gz
            .flatMap { 
                meta, fa ->
                def fas = fa instanceof List ? fa : [fa]
                fas.collect { it ->
                    // INFO: format of chunks is tmp.chr1.chunk.1.fasta.gz
                    // INFO: grab -3 should be safe
                    def parts = it.baseName.split('\\.')
                    def chunk = parts[-2]
                    [ [ id: meta.id + '.' + chunk ], it ]
                }
            }
            .set { ch_chunks }
      } else {
        SPLICEAI_CHUNK.out.fasta
            .flatMap { 
                meta, fa ->
                def fas = fa instanceof List ? fa : [fa]
                fas.collect { it ->
                    def parts = it.baseName.split('\\.')
                    def chunk = parts[-1]
                    [ [ id: meta.id + '.' + chunk ], it ]
                }
            }
            .set { ch_chunks }
      }

      SPLICEAI_PREDICT(ch_chunks)

      WIGTOBIGWIG_DONOR_PLUS(SPLICEAI_PREDICT.out.donor_plus, chromsizes)
      WIGTOBIGWIG_DONOR_MINUS(SPLICEAI_PREDICT.out.donor_minus, chromsizes)
      WIGTOBIGWIG_ACCEPTOR_PLUS(SPLICEAI_PREDICT.out.acceptor_plus, chromsizes)
      WIGTOBIGWIG_ACCEPTOR_MINUS(SPLICEAI_PREDICT.out.acceptor_minus, chromsizes)

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

      SPLICEAI_PUBLISH(
          BIGWIGMERGE_DONOR_PLUS.out.bigwig,
          BIGWIGMERGE_DONOR_MINUS.out.bigwig,
          BIGWIGMERGE_ACCEPTOR_PLUS.out.bigwig,
          BIGWIGMERGE_ACCEPTOR_MINUS.out.bigwig,
      )
      
    emit:
      spliceai = SPLICEAI_PUBLISH.out.spliceai
      versions = ch_versions
}
