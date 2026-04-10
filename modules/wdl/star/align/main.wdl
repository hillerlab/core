# Copyright (c) 2026 The Hiller Lab at the Senckenberg Gessellschaft für Naturforschung
# Distributed under the terms of the Apache License, Version 2.0.

version 1.3

task align {
  input {
    Array[File]+ reads
    Directory index
    File gtf
    File additional_junctions
    Boolean single_end = false
    Boolean use_additional_junctions = false
    Boolean star_ignore_sjdbgtf = false
    String seq_platform = ""
    String seq_center = ""
    String seq_library = ""
    String seq_machine_type = ""
    Boolean keep_bam = true
    Boolean delete_fastq = false
    Int threads = 1
    String prefix
    String star_args = ""
  }

  String log_final_path = prefix + ".Log.final.out"
  String log_out_path = prefix + ".Log.out"
  String log_progress_path = prefix + ".Log.progress.out"

  command <<<
    set -euo pipefail

    reads=(~{sep=' ' reads})
    reads1=()
    reads2=()

    if ~{if single_end then "true" else "false"}; then
      reads1=("${reads[@]}")
    else
      for i in "${!reads[@]}"; do
        if (( i % 2 == 0 )); then
          reads1+=("${reads[$i]}")
        else
          reads2+=("${reads[$i]}")
        fi
      done
    fi

    read1_csv=$(IFS=,; echo "${reads1[*]}")
    read2_csv=$(IFS=,; echo "${reads2[*]}")

    ignore_gtf=""
    if ! ~{if star_ignore_sjdbgtf then "true" else "false"}; then
      ignore_gtf="--sjdbGTFfile ~{gtf}"
    fi

    junctions=""
    if ~{if use_additional_junctions then "true" else "false"}; then
      junctions="--sjdbFileChrStartEnd ~{additional_junctions}"
    fi

    attr_rg=""
    if [[ "~{star_args}" != *"--outSAMattrRGline"* ]]; then
      attr_rg="--outSAMattrRGline ID:~{prefix}"
      if [ -n "~{seq_center}" ]; then
        attr_rg="$attr_rg CN:~{seq_center}"
      fi
      attr_rg="$attr_rg SM:~{prefix}"
      if [ -n "~{seq_platform}" ]; then
        attr_rg="$attr_rg PL:~{seq_platform}"
      fi
      if [ -n "~{seq_library}" ]; then
        attr_rg="$attr_rg LB:~{seq_library}"
      fi
      if [ -n "~{seq_machine_type}" ]; then
        attr_rg="$attr_rg PU:~{seq_machine_type}"
      fi
    fi

    out_sam_type=""
    if [[ "~{star_args}" != *"--outSAMtype"* ]]; then
      out_sam_type="--outSAMtype BAM SortedByCoordinate"
    fi

    if [ -n "$read2_csv" ]; then
      STAR \
        --genomeDir ~{index} \
        --readFilesIn "$read1_csv" "$read2_csv" \
        --runThreadN ~{threads} \
        --outFileNamePrefix ~{prefix}. \
        ~{star_args} \
        $out_sam_type \
        $ignore_gtf \
        $junctions \
        $attr_rg
    else
      STAR \
        --genomeDir ~{index} \
        --readFilesIn "$read1_csv" \
        --runThreadN ~{threads} \
        --outFileNamePrefix ~{prefix}. \
        ~{star_args} \
        $out_sam_type \
        $ignore_gtf \
        $junctions \
        $attr_rg
    fi

    if [ -f ~{prefix}.Aligned.out.bam ] && [[ "~{star_args}" == *"--outSAMtype BAM Unsorted SortedByCoordinate"* ]]; then
      mv ~{prefix}.Aligned.out.bam ~{prefix}.Aligned.unsort.out.bam
    fi

    if [ -f ~{prefix}.Unmapped.out.mate1 ]; then
      mv ~{prefix}.Unmapped.out.mate1 ~{prefix}.unmapped_1.fastq
      gzip ~{prefix}.unmapped_1.fastq
    fi

    if [ -f ~{prefix}.Unmapped.out.mate2 ]; then
      mv ~{prefix}.Unmapped.out.mate2 ~{prefix}.unmapped_2.fastq
      gzip ~{prefix}.unmapped_2.fastq
    fi

    if [ -f ~{prefix}.Aligned.sortedByCoord.out.bam ]; then
      samtools index ~{prefix}.Aligned.sortedByCoord.out.bam
    fi

    if ~{if keep_bam then "false" else "true"}; then
      rm -f ~{prefix}.Aligned.sortedByCoord.out.bam
      rm -f ~{prefix}.Aligned.sortedByCoord.out.bam.bai
    fi

    if ~{if delete_fastq then "true" else "false"}; then
      for file in "${reads[@]}"; do
        rm -f "$file"
      done
    fi

    if [[ "~{star_args}" == *"--outWigType"* ]]; then
      rm -f ~{prefix}.Signal.UniqueMultiple.*
      if [ -f ~{prefix}.Signal.Unique.str1.out.bg ]; then
        sort -k1,1 -k2,2n ~{prefix}.Signal.Unique.str1.out.bg > tmp.bg
        mv tmp.bg ~{prefix}.Signal.Unique.str1.out.bg
      fi
    fi
  >>>

  output {
    File log_final = log_final_path
    File log_out = log_out_path
    File log_progress = log_progress_path
    Array[File] bam = glob("*d.out.bam")
    Array[File] bam_sorted = glob("*.sortedByCoord.out.bam")
    Array[File] bam_sorted_aligned = glob("*.Aligned.sortedByCoord.out.bam")
    Array[File] bam_transcript = glob("*toTranscriptome.out.bam")
    Array[File] bam_unsorted = glob("*Aligned.unsort.out.bam")
    Array[File] fastq = glob("*fastq.gz")
    Array[File] tab = glob("*.tab")
    Array[File] spl_junc_tab = glob("*.SJ.out.tab")
    Array[File] read_per_gene_tab = glob("*.ReadsPerGene.out.tab")
    Array[File] junction = glob("*.out.junction")
    Array[File] sam = glob("*.out.sam")
    Array[File] wig = glob("*Unique.*.wig")
    Array[File] bedgraph = glob("*Unique.*.bg")
    Array[File] bai = glob("*.bai")
  }

  requirements {
    container: "community.wave.seqera.io/library/htslib_samtools_star_gawk:ae438e9a604351a4"
  }
}

workflow run {
  input {
    Array[File]+ reads
    Directory index
    File gtf
    File additional_junctions
    Boolean single_end = false
    Boolean use_additional_junctions = false
    Boolean star_ignore_sjdbgtf = false
    String seq_platform = ""
    String seq_center = ""
    String seq_library = ""
    String seq_machine_type = ""
    Boolean keep_bam = true
    Boolean delete_fastq = false
    Int threads = 1
    String prefix
    String star_args = ""
  }

  call align {
    input:
      reads = reads,
      index = index,
      gtf = gtf,
      additional_junctions = additional_junctions,
      single_end = single_end,
      use_additional_junctions = use_additional_junctions,
      star_ignore_sjdbgtf = star_ignore_sjdbgtf,
      seq_platform = seq_platform,
      seq_center = seq_center,
      seq_library = seq_library,
      seq_machine_type = seq_machine_type,
      keep_bam = keep_bam,
      delete_fastq = delete_fastq,
      threads = threads,
      prefix = prefix,
      star_args = star_args
  }

  output {
    File log_final = align.log_final
    File log_out = align.log_out
    File log_progress = align.log_progress
    Array[File] bam = align.bam
    Array[File] bam_sorted = align.bam_sorted
    Array[File] bam_sorted_aligned = align.bam_sorted_aligned
    Array[File] bam_transcript = align.bam_transcript
    Array[File] bam_unsorted = align.bam_unsorted
    Array[File] fastq = align.fastq
    Array[File] tab = align.tab
    Array[File] spl_junc_tab = align.spl_junc_tab
    Array[File] read_per_gene_tab = align.read_per_gene_tab
    Array[File] junction = align.junction
    Array[File] sam = align.sam
    Array[File] wig = align.wig
    Array[File] bedgraph = align.bedgraph
    Array[File] bai = align.bai
  }
}
