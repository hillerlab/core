/*
Copyright (c) 2026 The Hiller Lab at the Senckenberg Gessellschaft für Naturforschung
Distributed under the terms of the Apache License, Version 2.0.
*/

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RUSTAR_ALIGN — Rust reimplementation of STAR, reading FASTQ or CBQ natively.
    Mirrors modules/nf-core/star/align: same flags, same output filenames and the
    same STAR-compatible Log.final.out. Two deliberate differences:
      - no inline `samtools index` (the image ships no samtools -> SAMTOOLS_INDEX)
      - a staged .cbq feeds a single --readFilesIn and suppresses zcat
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

process RUSTAR_ALIGN {
    tag "$meta.id"
    label 'process_medium'

    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        '' :
        'ghcr.io/hillerlab/rustar-aligner-cbq:latest' }"

    input:
        tuple val(meta), path(reads, stageAs: "input*/*"), path(index)
        path gtf
        path additional_junctions
        val star_ignore_sjdbgtf
        val seq_platform
        val seq_center
        val seq_library
        val seq_machine_type
        val keep_bam
        val delete_fastq

    output:
        tuple val(meta), path('*Log.final.out'), emit: log_final
        tuple val(meta), path('*Log.out'), emit: log_out
        tuple val(meta), path('*Log.progress.out'), emit: log_progress
        path "versions.yml", emit: versions

        tuple val(meta), path('*d.out.bam'), optional: true, emit: bam
        tuple val(meta), path("${prefix}.sortedByCoord.out.bam"), optional: true, emit: bam_sorted
        tuple val(meta), path("${prefix}.Aligned.sortedByCoord.out.bam"), optional: true, emit: bam_sorted_aligned
        tuple val(meta), path('*toTranscriptome.out.bam'), optional: true, emit: bam_transcript
        tuple val(meta), path('*Aligned.unsort.out.bam'), optional: true, emit: bam_unsorted
        tuple val(meta), path('*fastq.gz'), optional: true, emit: fastq
        tuple val(meta), path('*.tab'), optional: true, emit: tab
        tuple val(meta), path('*.SJ.out.tab'), optional: true, emit: spl_junc_tab
        tuple val(meta), path('*.ReadsPerGene.out.tab'), optional: true, emit: read_per_gene_tab
        tuple val(meta), path('*.out.junction'), optional: true, emit: junction
        tuple val(meta), path('*.out.sam'), optional: true, emit: sam
        tuple val(meta), path('*Unique.*.wig'), optional: true, emit: wig
        tuple val(meta), path('*Unique.*.bg'), optional: true, emit: bedgraph
        tuple val(meta), env(BAM_SIZE), optional: true, emit: bam_size

    when:
        task.ext.when == null || task.ext.when

    script:
        def args = task.ext.args ?: ''
        // NOTE: assigned without `def` on purpose - `prefix` has to leak into process
        // scope so the output block can interpolate it (same as nf-core/star/align).
        prefix = task.ext.prefix ?: "${meta.id}"
        // Detected from the file rather than meta: ASSEMBLY rebuilds meta as a bare
        // [id, single_end, strandedness] map, so a format key there would desynchronise
        // the samplesheet joins. The file itself is the source of truth.
        def is_cbq = (reads instanceof List ? reads[0] : reads).name.endsWith('.cbq')
        def reads1 = []
        def reads2 = []
        if (!is_cbq) {
            meta.single_end ? [reads].flatten().each { reads1 << it } : reads.eachWithIndex { v, ix -> (ix & 1 ? reads2 : reads1) << v }
        }
        // A .cbq carries both mates in one file, so it is passed as a single --readFilesIn
        // argument and decoded in-process; --readFilesCommand is omitted by the config.
        def reads_in = is_cbq ? "--readFilesIn ${reads} --readFilesNthreads 4"
                              : "--readFilesIn ${reads1.join(",")} ${reads2.join(",")}"
        def delete_targets = is_cbq ? "${reads}" : "${reads1.join(" ")} ${reads2.join(" ")}"
        def ignore_gtf = star_ignore_sjdbgtf ? '' : "--sjdbGTFfile $gtf"
        def junctions = additional_junctions ? "--sjdbFileChrStartEnd $additional_junctions" : ''

        def seq_platform_arg = seq_platform ? "'PL:$seq_platform'" : ""
        def seq_center_arg = seq_center ? "'CN:$seq_center'" : ""

        attrRG = args.contains("--outSAMattrRGline") ? "" : "--outSAMattrRGline 'ID:$prefix' $seq_center_arg 'SM:$prefix' $seq_platform_arg"
        def out_sam_type = (args.contains('--outSAMtype')) ? '' : '--outSAMtype BAM SortedByCoordinate'
        // Decided here, not in the config: only this scope knows whether the staged file
        // is a .cbq (decoded in-process, so zcat must not be applied to it).
        def read_files_command = (is_cbq || args.contains('--readFilesCommand')) ? '' : '--readFilesCommand zcat'
        mv_unsorted_bam = (args.contains('--outSAMtype BAM Unsorted SortedByCoordinate')) ? "mv ${prefix}.Aligned.out.bam ${prefix}.Aligned.unsort.out.bam" : ''
        def is_producing_cov = (args.contains('--outWigType')) ? true : false
        BAM_SIZE = 'BAM_SIZE'
        """
        rustar-aligner \
            --genomeDir $index \
            $reads_in \
            --runThreadN $task.cpus \
            --outFileNamePrefix $prefix. \
            $args \
            $read_files_command \
            $out_sam_type \
            $ignore_gtf \
            $junctions \
            $attrRG

        $mv_unsorted_bam

        if [ -f ${prefix}.Unmapped.out.mate1 ]; then
            mv ${prefix}.Unmapped.out.mate1 ${prefix}.unmapped_1.fastq
            gzip ${prefix}.unmapped_1.fastq
        fi
        if [ -f ${prefix}.Unmapped.out.mate2 ]; then
            mv ${prefix}.Unmapped.out.mate2 ${prefix}.unmapped_2.fastq
            gzip ${prefix}.unmapped_2.fastq
        fi

        export BAM_SIZE=0
        if [ -f "${prefix}.Aligned.sortedByCoord.out.bam" ]; then
            BAM_SIZE=\$(stat -c%s "${prefix}.Aligned.sortedByCoord.out.bam")
        fi

        if [ ${keep_bam} == "false" ]; then
            rm ${prefix}.Aligned.sortedByCoord.out.bam
        fi

        if [ ${delete_fastq} == "true" ]; then
            # Delete actual input files, not just symlinks
            for file in ${delete_targets}; do
                if [ -L "\$file" ]; then
                    realpath=\$(readlink -f "\$file")
                    rm -f "\$realpath"
                else
                    rm -f "\$file"
                fi
            done
        fi

        if [ $is_producing_cov == true ]; then
            rm ${prefix}.Signal.UniqueMultiple.*

            sort -k1,1 -k2,2n ${prefix}.Signal.Unique.str1.out.bg > tmp.bg
            mv tmp.bg ${prefix}.Signal.Unique.str1.out.bg
        fi

        cat <<-END_VERSIONS > versions.yml
        "${task.process}":
            rustar-aligner: \$(rustar-aligner --version | head -n1 | sed -e "s/rustar-aligner //g")
        END_VERSIONS
        """

    stub:
        prefix = task.ext.prefix ?: "${meta.id}"
        BAM_SIZE = 'BAM_SIZE'
        """
        echo "" | gzip > ${prefix}.unmapped_1.fastq.gz
        echo "" | gzip > ${prefix}.unmapped_2.fastq.gz
        touch ${prefix}Xd.out.bam
        touch ${prefix}.Log.final.out
        touch ${prefix}.Log.out
        touch ${prefix}.Log.progress.out
        touch ${prefix}.sortedByCoord.out.bam
        touch ${prefix}.toTranscriptome.out.bam
        touch ${prefix}.Aligned.unsort.out.bam
        touch ${prefix}.Aligned.sortedByCoord.out.bam
        touch ${prefix}.tab
        touch ${prefix}.SJ.out.tab
        touch ${prefix}.ReadsPerGene.out.tab
        touch ${prefix}.Chimeric.out.junction
        touch ${prefix}.out.sam
        touch ${prefix}.Signal.UniqueMultiple.str1.out.wig
        touch ${prefix}.Signal.UniqueMultiple.str1.out.bg
        touch ${prefix}.Signal.Unique.str1.out.wig
        touch ${prefix}.Signal.Unique.str1.out.bg
        BAM_SIZE=0

        cat <<-END_VERSIONS > versions.yml
        "${task.process}":
            rustar-aligner: \$(rustar-aligner --version | head -n1 | sed -e "s/rustar-aligner //g")
        END_VERSIONS
        """
}
